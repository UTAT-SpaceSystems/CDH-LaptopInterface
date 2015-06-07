/*
----------------------------------
UTAT Space Systems CANBus Reader
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
// CAN message frames 
Frame message_0, message_1;
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
    message_0.id = 0;
    message_1.id = 0;
    
    // This implementation utilizes the MCP2515 INT pin to flag received messages or other events
    if(CAN.Interrupt()) 
    {
        // determine which interrupt flags have been set
        byte interruptFlags = CAN.Read(CANINTF);
        
        if(interruptFlags & RX0IF) 
        {
            // read from RX buffer 0
            message_0 = CAN.ReadBuffer(RXB0);
        }
        if(interruptFlags & RX1IF) 
        {
            // read from RX buffer 1
            message_1 = CAN.ReadBuffer(RXB1);
        }
        if(interruptFlags & TX0IF) 
        {
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
            // error handling code
            // if TXBnCTRL.TXERR set then transmission error
            // if message is lost TXBnCTRL.MLOA will be set
        }
    }
    else
    {
        Serial.print("#\n");
    }
    
    if(message_0.id>0) 
    {
        // Print message
        printCANMessage(message_0, 10);
    }
    
    if(message_1.id>0) 
    {
        // Print message
        printCANMessage(message_1, 10);
    }
    
}


// TO-DO
void parseMessageFromSerial(String in)
{
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
void printCANMessage(Frame message, unsigned long filter)
{ 
    if (filter != 0)
    {
        if (message.id == filter)
        {
            Serial.print("$");
            Serial.print(message.id, HEX);
            Serial.print("/");
            for(i = 0; i < message.dlc; i++) 
            {
                Serial.print(message.data[i],HEX);
                Serial.print("/");
            }
            Serial.println();
        }
    }
    else
    {
        Serial.print("$");
        Serial.print(message.id, HEX);
        Serial.print("/");
        for(i = 0; i < message.dlc; i++) 
        {
            Serial.print(message.data[i],HEX);
            Serial.print("/");
        }
        Serial.println();  
    }
}
