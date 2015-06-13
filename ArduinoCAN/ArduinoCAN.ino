/*
----------------------------------
UTAT Space Systems CANBus Analyzer
----------------------------------

For use with the Sparkfun CANBus shield.

Initial Author: David Harding
Created: 11/08/2010
Modified: 5/31/2015

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
    
    //Serial.println("Initializing ...");
    
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
        
        //Serial.print("Baud Rate (kbps): ");
        //Serial.println(baudRate,DEC);
    } 
    else 
    {
        Serial.print("ERROR\n");
    }
    
    //Serial.println("Ready ...");
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
            Serial.print("MSG SENT");
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
        parseCANMessage(message_in_0, 10);
    }    
    if(message_in_1.id>0) 
    {
        parseCANMessage(message_in_1, 10);
    }
    
    
    if (Serial.available())
    {
        String serial_message = Serial.readString();
        if(serial_message[0] == '^')
        {
            message_out = parseMessageFromSerial(serial_message);
            sendCANMessage(message_out);
        }
    }
}


Frame parseMessageFromSerial(String in)
{
    Frame f;
    f.dlc = 8; 
    // First byte
    f.id = in.substring(1, 3);  
    
    for(int i = 0; i < f.dlc; i++ )
    {
      f.data[i] = in.substring(3 + (2 * i), 5 + (2 * i));
    }
    return f;
}

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
void parseCANMessage(Frame message, unsigned long filter)
{ 
    String data = "";
    
    if (filter != 0)
    {
        if (message.id == filter)
        { 
             Serial.print("$");
             print_hex(message.id, 8);
             Serial.print("/");
             for(i = 0; i < message.dlc; i++) 
             {
                 print_hex(message.data[i], 8);
                 Serial.print("/");
                 //data += String(message.data[i]);
             }
             Serial.println();  
         }
    }
    else
    {
        Serial.print("$");
             print_hex(message.id, 8);
             Serial.print("/");
             for(i = 0; i < message.dlc; i++) 
             {
                 print_hex(message.data[i], 8);
                 Serial.print("/");
                 //data += String(message.data[i]);
             }
             Serial.println();
    }
}

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

