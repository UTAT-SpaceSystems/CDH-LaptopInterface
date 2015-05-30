/* Welcome to the ECU Reader project. This sketch uses the Canbus library.
It requires the CAN-bus shield for the Arduino. This shield contains the MCP2515 CAN controller and the MCP2551 CAN-bus driver.
A connector for an EM406 GPS receiver and an uSDcard holder with 3v level convertor for use in data logging applications.
The output data can be displayed on a serial LCD.

SK Pang Electronics www.skpang.co.uk

v1.0 28-03-10

*/

//#include <NewSoftSerial.h>
#include "Canbus.h"

//NewSoftSerial sLCD =  NewSoftSerial(3, 14); /* Serial LCD is connected on pin 14 (Analog input 0) */
#define COMMAND 0xFE
#define CLEAR   0x01
#define LINE0   0x80
#define LINE1   0xC0

int LED2 = 8;
int LED3 = 7;

char buffer[16];
 
void setup() {
  
  pinMode(LED2, OUTPUT); 
  pinMode(LED3, OUTPUT); 

  Serial.begin(9600);
  Serial.println("ECU Reader");  /* For debug use */
  
  if(Canbus.init(CANSPEED_500))  /* Initialise MCP2515 CAN controller at the specified speed */
  {
    Serial.println("CAN Init ok");
  } else
  {
    Serial.println("Can't init CAN");
  } 
   
  delay(1000); 

}
 

void loop() {
 

}
