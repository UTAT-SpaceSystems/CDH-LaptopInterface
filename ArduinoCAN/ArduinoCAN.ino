/*
----------------------------------
UTAT Space Systems CANBus Analyzer
----------------------------------

For use with the Sparkfun CANBus shield.
Initial Author: David Harding
Created: 11/08/2010

Modified: 5/31/2015

DEVELOPMENT HISTORY:
Date          Author              Release          Description of Change
06/14/15      Omar Abdeldayem     1.0              Monitoring (send, receive & log) fully functional 

*/

#include "SPI.h" // Arduino SPI Library
#include "MCP2515.h"

// Pin definitions specific to how the MCP2515 is wired up.
#define CS_PIN    10
#define INT_PIN    2

byte i = 0;
// String for sending messages on bus
Frame message_out;
// CAN message receive frames 
Frame message_in_0, message_in_1;
// Create CAN object with pins as defined
MCP2515 CAN(CS_PIN, INT_PIN);


void setup() 
{
    Serial.begin(9600);
    
    // Set up SPI Communication
    // dataMode can be SPI_MODE0 or SPI_MODE3 only for MCP2515
    SPI.setClockDivider(SPI_CLOCK_DIV2);
    SPI.setDataMode(SPI_MODE0);
    SPI.setBitOrder(MSBFIRST);
    SPI.begin();   
    // Initialise MCP2515 CAN controller at the specified speed and clock frequency
    // CAN bus running at 250kbs at 16MHz
    int baudRate=CAN.Init(250,16);
    
    if(baudRate>0) 
    {
        Serial.print("READY\n");
    } 
    else 
    {
        Serial.print("ERROR\n");
    }
}

void loop() 
{
    delay(100);
    message_in_0.id = 0;
    message_in_1.id = 0;
    
    // This implementation utilizes the MCP2515 INT pin to flag received messages or other events
    if(CAN.Interrupt()) 
    {
        // determine which interrupt flags have been set
        byte interruptFlags = CAN.Read(CANINTF);
        
        if(interruptFlags & RX0IF) 
        {
            // read from RX buffer 0
            message_in_0 = CAN.ReadBuffer(RXB0);
        }
        if(interruptFlags & RX1IF) 
        {
            // read from RX buffer 1
            message_in_1 = CAN.ReadBuffer(RXB1);
        }
        if(interruptFlags & TX0IF) 
        {
            Serial.print("MSG SENT\n");
            // TX buffer 0 sent
        }
        if(interruptFlags & TX1IF) 
        {
            // TX buffer 1 sent
        }
        if(interruptFlags & TX2IF) 
        {
            // TX buffer 2 sent
        }
        if(interruptFlags & ERRIF) 
        {
            // error handling code
        }
        if(interruptFlags & MERRF) 
        {
            Serial.print("MSG ERR\n");
            // error handling code
            // if TXBnCTRL.TXERR set then transmission error
            // if message is lost TXBnCTRL.MLOA will be set
        }
    }
    else
    {
        Serial.print("#\n");
    }
    
    // Print Messages
    if(message_in_0.id>0) 
    {
        parseCANMessage(message_in_0);
    }    
    if(message_in_1.id>0) 
    {
        parseCANMessage(message_in_1);
    }
    
    // Checks to see whether the GUI has written anything to serial
    // to send back out on the bus
    if (Serial.available())
    {
        String serial_message = Serial.readString();
        if(serial_message[0] == '^')
        {
            message_out = parseMessageFromSerial(serial_message);
            
            if (message_out.dlc != 0)
            {
                sendCANMessage(message_out);
            }
        }
    }
}

/**
* Parses a message sent over serial from the GUI into a CAN frame
* String in - String sent over serial from Processing in the following
* format: ^XX/00FF00FF00FF00FF
* where XX represents the ID and everything after the slash represents 
* the 8 data bytes.
*/
Frame parseMessageFromSerial(String in)
{  
    Frame f;
    f.dlc = 0;
    if (in.length() != 0)
    {
        f.dlc = 8; 
        // First byte
        f.id = in.substring(1, 3).toInt();  
        
        for(int i = 0; i < f.dlc; i++ )
        {
          f.data[i] = in.substring(3 + (2 * i), 5 + (2 * i)).toInt();
        }
    }
    return f;
}

/**
* Loads a CAN frame into one of the tranceiver's two transmit buffers
* and sends it over CAN.
* Frame message - CAN frame being sent out over the bus
*/
void sendCANMessage(Frame message)
{
  CAN.LoadBuffer(TXB0, message);
  CAN.SendBuffer(TXB0);
}

/**
* Prints out the data and ID received in a CAN frame. Messages can be
* filtered based on their IDs.
*
* Frame message - CAN frame received to print.
* unsigned long filter - CAN ID to filter messages by; a value of 0 indicates no filtering.
*/
void parseCANMessage(Frame message)
{ 
    String data = "";
    
   Serial.print("$");
   print_hex(message.id, 8);
   Serial.print("/");
   for(i = 0; i < message.dlc; i++) 
   {
       print_hex(message.data[i], 8);
       Serial.print("/");
   }
   Serial.println();  
          
}

/**
* Prints an int in hexadecimal WITH leading (insignificant) zeros
* v - integer to print
* num_places - number of bits
*/
void print_hex(int v, int num_places)
{
    int mask=0, n, num_nibbles, digit;

    for (n=1; n<=num_places; n++)
    {
        mask = (mask << 1) | 0x0001;
    }
    v = v & mask; // truncate v to specified number of places

    num_nibbles = num_places / 4;
    if ((num_places % 4) != 0)
    {
        ++num_nibbles;
    }

    do
    {
        digit = ((v >> (num_nibbles-1) * 4)) & 0x0f;
        Serial.print(digit, HEX);
    } while(--num_nibbles);

}

