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
// CAN message frame (actually just the parts that are exposed by the MCP2515 RX/TX buffers)
Frame message_0, message_1;
// Create CAN object with pins as defined
MCP2515 CAN(CS_PIN, INT_PIN);


void setup() {
    Serial.begin(9600);
    
    Serial.println("Initializing ...");
    
    // Set up SPI Communication
    // dataMode can be SPI_MODE0 or SPI_MODE3 only for MCP2515
    SPI.setClockDivider(SPI_CLOCK_DIV2);
    SPI.setDataMode(SPI_MODE0);
    SPI.setBitOrder(MSBFIRST);
    SPI.begin();
    
    // Initialise MCP2515 CAN controller at the specified speed and clock frequency
    int baudRate=CAN.Init(250,16);
    if(baudRate>0) {
        Serial.println("MCP2515 Init OK ...");
        Serial.print("Baud Rate (kbps): ");
        Serial.println(baudRate,DEC);
    } else {
        Serial.println("MCP2515 Init Failed ...");
    }
    
    Serial.println("Ready ...");
}

void loop() {
    message_0.id = 0;
    message_1.id = 0;
    
    // This implementation utilizes the MCP2515 INT pin to flag received messages or other events
    if(CAN.Interrupt()) {
        // determine which interrupt flags have been set
        byte interruptFlags = CAN.Read(CANINTF);
        
        if(interruptFlags & RX0IF) {
            // read from RX buffer 0
            message_0 = CAN.ReadBuffer(RXB0);
        }
        if(interruptFlags & RX1IF) {
            // read from RX buffer 1
            message_1 = CAN.ReadBuffer(RXB1);
        }
        if(interruptFlags & TX0IF) {
            // TX buffer 0 sent
        }
        if(interruptFlags & TX1IF) {
            // TX buffer 1 sent
        }
        if(interruptFlags & TX2IF) {
            // TX buffer 2 sent
        }
        if(interruptFlags & ERRIF) {
            // error handling code
        }
        if(interruptFlags & MERRF) {
            // error handling code
            // if TXBnCTRL.TXERR set then transmission error
            // if message is lost TXBnCTRL.MLOA will be set
        }
    }
    else
    {
        Serial.println("No message received.");
    }
    
    if(message_0.id>0) {
        // Print message
        printCANMessage(message_0, 10);
    }
    
    if(message_1.id>0) {
        // Print message
        printCANMessage(message_1, 10);
    }
}

void printCANMessage(Frame message, unsigned long filter)
{ 
    if (filter != 0)
    {
        if (message.id == filter)
        {
            Serial.print("ID: ");
            Serial.println(message.id, HEX);
            Serial.print("Extended: ");
            if(message.ide) {
                Serial.println("Yes");
            } else {
                Serial.println("No");
            }
            Serial.print("DLC: ");
            Serial.println(message.dlc,DEC);
            for(i=0;i<message.dlc;i++) {
                Serial.print(message.data[i],HEX);
                Serial.print(" ");
            }
            Serial.println();
        }
    }
    else
    {
        if (message.id == filter)
        {
            Serial.print("ID: ");
            Serial.println(message.id, HEX);
            Serial.print("Extended: ");
            if(message.ide) {
                Serial.println("Yes");
            } else {
                Serial.println("No");
            }
            Serial.print("DLC: ");
            Serial.println(message.dlc,DEC);
            for(i=0;i<message.dlc;i++) {
                Serial.print(message.data[i],HEX);
                Serial.print(" ");
            }
            Serial.println();
        }
    }
}
