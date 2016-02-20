/*
----------------------------------
UTAT Space Systems CANBus Analyzer
----------------------------------

For use with the Sparkfun CANBus shield.
Initial Author: David Harding
Created: 11/08/2010

DEVELOPMENT HISTORY:
Date          Author              Description of Change
06/14/15      Omar Abdeldayem     Monitoring (send, receive & log) fully functional

02/12/16      Steven Yin          Added pin to reset OBC and SSMs and handshake code

02/13/16      Steven Yin          Removed software reset

02/19/16      Steven Yin          Added code to request all sensor data

*/

#include <SPI.h> // Arduino SPI Library
#include "MCP2515.h"
#include "arduino_defs.h"


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
    establishContact();
    // Set up SPI Communication
    // dataMode can be SPI_MODE0 or SPI_MODE3 only for MCP2515
    SPI.setClockDivider(SPI_CLOCK_DIV2);
    SPI.setDataMode(SPI_MODE0);
    SPI.setBitOrder(MSBFIRST);
    SPI.begin();   
    // Initialise MCP2515 CAN controller at the specified speed and clock frequency
    // CAN bus running at 250kbs at 16MHz
    int baudRate = CAN.Init(250,16);
    
    pinMode(LED1,OUTPUT);
    pinMode(LED2,OUTPUT);
    
    if(baudRate>0) 
    {
        Serial.print("@READY\n");
    } 
    else 
    {
        Serial.print("@ERROR\n");
    }
}

void loop() 
{
    delay(100);
    message_in_0.id = 0;
    message_in_1.id = 0;
    request_sensor_data();
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
            // TX buffer 0 sent
            Serial.print("@MSG SENT\n");
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
            Serial.print("@MSG ERR\n");
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
        String serial_message = Serial.readStringUntil('\n');
        if(serial_message[0] == '^')
        {
            message_out = parseMessageFromSerial(serial_message);
            
            if (message_out.dlc != 0)
            {
                sendCANMessage(message_out);
            }
        }
        else if(serial_message[0] == '~')
        {
            handleCommand(serial_message);
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
        if(string_to_hex(in.substring(1, 3), f.id) == false)
        {
            Serial.println("*Please check your MOB again!");
            f.dlc = 0;
            return f;
        }
        
        for(int i = 0; i < f.dlc; i++ )
        {
            if(string_to_hex(in.substring(3 + (2 * i), 5 + (2 * i)), f.data[f.dlc - 1 - i]) == false)
            {
                Serial.println("*Please check your message again!");
                f.dlc = 0;
                return f;
            }
        }
    }
    return f;
}

/**
* Handle the commands which requires arduino to handle
* String in - String sent over serial from Processing in the following
* format: ~XX
* where 'X' is a HEX
*/
void handleCommand(String in)
{
    byte command;
    if(!string_to_hex(in.substring(1,3), command))
    {
        // When the input is not correct
        // DO NOTHING
        return;
    }
    switch(command)
    {
        case REQ_SENSOR_DATA:
        {
            request_sensor_data();
        }
    }
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

/**
* Interact with processing code to clear all output buffer
*/
void establishContact() 
{
    delay(100);
    if(Serial.available() > 0)
    {
        String temp = Serial.readString();
    }
    Serial.println("Clearning buffer!!!");
    Serial.flush();
    while (Serial.available() <= 0) 
    {
    }
}

/**
* Request sensor data
*/
void request_sensor_data()
{
    Frame buff;
    buff.dlc = 8; 
    buff.id = 20;
    buff.data[7]=0x30;
    buff.data[6]=0x02;
    buff.data[5]=0x02;
    buff.data[4]=0x09;
    buff.data[3]=0xF0;
    buff.data[2]=0xF0;
    buff.data[1]=0xF0;
    buff.data[0]=0xF0;
    //for(int i = 0x01; i <= 0x1B; i++) // Request data from all sensors

        sendCANMessage(buff);
    //if (Serial.available() <= 0)
    //{
    //    Serial.println("*Sensor data requested!");
    //}
}

void test()
{
    if (Serial.available()<=0) 
    {
        int input_number = random(10, 99);
        int ones = (input_number%10);
        int tens = ((input_number/10)%10);
        Serial.println("$A/"+String(ones)+"/"+String(tens)+"/F/A/9/B/F/1/6/5/4/6/6/5/3/F");
    }
}

boolean string_to_hex(String in, byte& out)
{
    byte c1 = in.charAt(0);
    byte c2 = in.charAt(1);
    out = 0;
    if(c1 >= '0' && c1<= '9')
    {
        out = c1 - '0';
    }
    else if(c1 >= 'a' && c1 <= 'f')
    {
        out = c1 - 'a' + 10;
    }
    else if(c1 >= 'A' && c1 <= 'F')
    {
        out = c1 -'A' + 10;
    }
    else
    {
        return false;
    }
    
    out *= 16;
    
    if(c2 >= '0' && c2<= '9')
    {
        out = out + c2 - '0';
    }
    else if(c2 >= 'a' && c2 <= 'f')
    {
        out = out + c2 - 'a' + 10;
    }
    else if(c2 >= 'A' && c2 <= 'F')
    {
        out = out + c2 -'A' + 10;
    }
    else
    {
        return false;
    }
    return true;
}


