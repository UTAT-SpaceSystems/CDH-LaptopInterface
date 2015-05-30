/* Welcome to the ECU Reader project. This sketch uses the Canbus library.
It requires the CAN-bus shield for the Arduino. This shield contains the MCP2515 CAN controller and the MCP2551 CAN-bus driver.
A connector for an EM406 GPS receiver and an uSDcard holder with 3v level convertor for use in data logging applications.
The output data can be displayed on a serial LCD.

SK Pang Electronics www.skpang.co.uk

v1.0 28-03-10

*/

//#include <NewSoftSerial.h>
#include "Canbus.h"
#include "defaults.h"
#include "global.h"
#include "mcp2515.h"
#include "mcp2515_defs.h"

//NewSoftSerial sLCD =  NewSoftSerial(3, 14); /* Serial LCD is connected on pin 14 (Analog input 0) */
#define COMMAND 0xFE
#define CLEAR   0x01
#define LINE0   0x80
#define LINE1   0xC0

int LED2 = 8;
int LED3 = 7;
int interrupt = 2;

unsigned char len = 0;
unsigned char buf[8];

uint8_t stat = 1;

char str[20];
char data[8];

void setup()
{
    
    pinMode(LED2, OUTPUT);
    pinMode(LED3, OUTPUT);
    pinMode(interrupt, INPUT);
    
    Serial.begin(9600);
    
    Serial.println("CANBus Reader");  // For debug use
    
    if(Canbus.init(CANSPEED_250))
    {
        Serial.println("OK");
    }
    else
    {
        Serial.println("ERR");
    }
    
    delay(1000);
    
}


void loop()
{   
    //Serial.println(mcp2515_read_status(stat));
  //  if (digitalRead(interrupt) == 1)
 //   {
 //     Serial.println(digitalRead(interrupt));
//    }
    
/*    if(Canbus.ecu_req(O2_VOLTAGE, data) == 1)
    {
      Serial.println("Message Recieved");
    //Serial.println(data[0]);
    }*/
    tCAN message;
    Serial.println(mcp2515_check_message());
    if (mcp2515_check_message())
    {
        digitalWrite(LED2, HIGH);
        
        if (mcp2515_get_message(&message))
        {
            digitalWrite(LED3, HIGH);
            Serial.print("ID: ");
            Serial.print(message.id,HEX);
            Serial.print(", ");
            Serial.print("Data: ");
            for(int i=0;i<message.header.length;i++)
            {
                Serial.print(message.data[i],HEX);
                Serial.print(" ");
            }
            Serial.println("");
        }
    }
    
    //  tCAN message;
    //
    //  if (mcp2515_check_message())
    //  {
    //    if (mcp2515_get_message(&message))
    //    {
    //      Serial.print("ID: ");
    //      Serial.print(message.id,HEX);
    //      Serial.print("\n");
    //
    //
    //      Serial.print("DA: ");
    //      for(int i=0;i<message.header.length;i++)
    //      {
    //        Serial.print(message.data[i],HEX);
    //        Serial.print(" ");
    //      }
    //      Serial.println("");
    //      }
    //    }
    //    else
    //    {
    //      Serial.println("No Message Recieved.");
    //    }
}
