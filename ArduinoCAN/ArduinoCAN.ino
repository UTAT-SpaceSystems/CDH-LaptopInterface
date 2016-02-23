#include "arduino_defs.h"

void setup()
{
    Serial.begin(9600);
    establishContact();

START_INIT:

    if(CAN_OK == CAN.begin(CAN_250KBPS))
    {
        Serial.print("*CAN BUS Shield init ok!\n");
        Serial.print("@CAN_OK\n");
    }
    else
    {
        Serial.print("*CAN BUS Shield init fail, retry!\n");
        Serial.print("@CAN_ERR\n");
        delay(1000);
        goto START_INIT;
    }
}

void loop()
{
    if(CAN_MSGAVAIL == CAN.checkReceive())    // check if data coming
    {
        serial_buf = 0;
        CAN.readMsgBuf(&len, receive_buf);    // read data,  len: data length, buf: data buf
        for(int i = 0; i < 8; i++)
        {
            serial_buf |= ((uint64_t)receive_buf[7 - i]) << (i * 8);
        }
        queue.push(serial_buf);
    }
    parseCANMessage();
    // Checks for GUI serial inputs
    if (Serial.available())
    {
        String serial_message = Serial.readStringUntil('\n');
        if(serial_message[0] == '^')
        {
            Frame message_out;
            message_out = parseMessageFromSerial(serial_message);
            
            if (message_out.is_ok)
              sendCANMessage(message_out);
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
    // First byte
    byte temp;
    if(in.substring(1, 3).toInt() < 1 || in.substring(1, 3).toInt() > 37)
    {
        Serial.print("*Please check your MOB again!\n");
        return f;
    }
    f.id = in.substring(1, 3).toInt();
    
    for(int i = 0; i < 8; i++ )
    {
        if(string_to_hex(in.substring(3 + (2 * i), 5 + (2 * i)), f.data[8 - 1 - i]) == false)
        {
            Serial.print(in);
            Serial.print("*Please check your message again!\n");
            return f;
        }
    }
    f.is_ok = true;
    return f;
}

/**
* Send CAN message over CAN bus
* Frame message - CAN frame being sent out over the bus
*/
void sendCANMessage(Frame message)
{
  switch(CAN.sendMsgBuf((int) message.id ,0, 8, message.data))
  {
      case CAN_OK:
      Serial.print("*Message sent!\n");
      Serial.print("@MSG_OK\n");
      break;
      case CAN_GETTXBFTIMEOUT:
      Serial.print("*Message not sent! CAN_Tx Timeout!\n");
      Serial.print("@MSG_ERR\n");
      break;
      case CAN_SENDMSGTIMEOUT:
      Serial.print("*Message not sent! Sending Timeout!\n");
      Serial.print("@MSG_ERR\n");
      break;
  }
}

/**
* Prints out the data and ID received in a CAN frame. Messages can be
* filtered based on their IDs.
*/
void parseCANMessage()
{ 
    if(!queue.isEmpty())
    {
    uint64_t data = queue.pop();
    byte msg = 0;
    Serial.print("$");
    Serial.print(CAN.getCanId());
    Serial.print("/");
    for(int i = 0; i < len; i++) 
    {
        msg = (byte)(data >> (i * 8));
        print_hex((int)msg, 8);
        Serial.print("/");
    }
    Serial.print("\n");
    }
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
        Serial.print("*Please check you command again!\n");
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
* Request sensor data
*/
void request_sensor_data()
{
    byte send_buf[8];
    send_buf[7] = 0x30;
    send_buf[6] = 0x02;
    send_buf[5] = 0x02;
    send_buf[4] = 0x09;

    CAN.sendMsgBuf(20 ,0, 8, send_buf);

    Serial.print("*Sensor data requested!\n");
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
    Serial.print("*Arduino Connection Established!\n");
    Serial.print("@ARDUINO_OK\n");
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
