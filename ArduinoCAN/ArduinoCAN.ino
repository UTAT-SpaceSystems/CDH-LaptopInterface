/*
    Author: Omar Abdeldayem, Steven Yin, Keenan Burnett, Albert Xie
    ***********************************************************************
    *   FILE NAME:      ArduinoCAN.ino
    *
    *   PURPOSE:        
    *   This program is meant to act as both a laptop interface to the satellite's CAN bus 
    *   as well as a "groundstation" to the satellite by communicating with it over radio via
    *   a CC1120 dev board.
    *
    *   FILE REFERENCES:    arduino_refs.h, SPI.h, cmd_strobes.h, registers.h, transceiver.h
    *
    *   EXTERNAL VARIABLES: None
    *
    *   ABORNOMAL TERMINATION CONDITIONS, ERROR AND WARNING MESSAGES: None yet.
    *
    *   NOTES:  
    *
    *   REQUIREMENTS/ FUNCTIONAL SPECIFICATION REFERENCES:
    *   The transceiver code makes use of a SPI connection to a CC1120 transceiver dev board.
    *   Be sure to connect the SS and RST pin appropriately.
    *
    *   When operating with the transceiver instead of the CAN Bus, be sure to run this code
    *   on an Arduino Pro Mini (3.3V, 8MHz).
    *
    *   An UNO with a CAN-BUS shield should be used for the CAN portion of this program.
    *
    *   DEVELOPMENT HISTORY:
    *
    *   02/22/2016      S: Created, working!
    *
    *   03/12/2016      K: Added my transceiver code so that we can communicate
    *                   with the CC1120.
    *                   Specifically, I've added transceiver.h and PROGRAM_SELECT so that we
    *                   can pick between running the CAN-Bus program and the transceiver 
    *
*/

/* Includes */
#include "arduino_defs.h"
#include "SPI.h"
#include "cmd_strobes.h"
#include "registers.h"

/* Transceiver Definitions */
#define PACKET_LENGTH 152
#define STATUS_INTERVAL 1000
#define ACK_TIMEOUT 1000
#define TRANSCEIVER_CYCLE 250
#define TRANSMIT_TIMEOUT 1000
#define CALIBRATION_TIMEOUT 5000
#define DEVICE_ADDRESS 0xA5
#define REAL_PACKET_LENGTH 76
#define ACK_LENGTH 3
#define TM_TIMEOUT 5000
#define STDFIFO 0x3F

// The following are the states
#define STATEIDLE   0b000
#define STATERX     0b001
#define STATETX     0b010
#define STATERXERR  0b110
#define STATETXERR  0b111

/* PUS Standard Definitions */
#define HK_TASK_ID  0x04
#define HK_GROUND_ID 0x0F

/* define crystal oscillator frequency to 32MHz */
#define f_xosc 32000000;

/* SPI PIN DEFINTIONS */
#define pin_SS 9
#define pin_RST_TRX 6
#define pin_MOSI 11
#define pin_MISO 12
#define pin_SCK 13

/* Global Variables for Transceiver Operations */
unsigned long previousTime = 0;
unsigned long currentTime = millis();
long int lastTransmit;
long int lastCycle;
long int lastAck;
long int lastToggle;
long int lastCalibration;
const int interval = 1000;
byte rx_mode, tx_mode, rx_length, tx_length;
byte new_packet[152];
byte packet_receivedf;
byte t_message[128];
byte tx_fail_count;
byte ack_acquired;
byte transmitting_sequence_control;
byte current_tm[PACKET_LENGTH], tm_to_downlink[PACKET_LENGTH], current_tc[PACKET_LENGTH];

/* PROGRAM SELECTION */
#define PROGRAM_SELECT  0// 1 == CAN-BUS, 0 == TRANSCEIVER

void setup()
{
    Serial.begin(9600);

#if PROGRAM_SELECT
    pinMode(LED1, OUTPUT);
    pinMode(LED2, OUTPUT);
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
#endif

#if !PROGRAM_SELECT
    Serial.print("\n**** STARTING GROUNDSTATION INIT ****\n");
    /* Configure Pins */
    pinMode(pin_RST_TRX, OUTPUT);
    pinMode(pin_SS, OUTPUT);
    /* Configure SPI */
    set_RSTn(1);
    set_CSn(1);
    delay(1000);
    SPI.setBitOrder(MSBFIRST);    // CC1120 uses MSB First.
    SPI.setClockDivider(SPI_CLOCK_DIV128);
    SPI.begin();
    /* Configure Transceiver */
    transceiver_initialize();

    /* Transmit First Packet */
    setup_fake_tc();
    transmit_packet();
    delay(25);

    Serial.print("\n**** FINISHING GROUNDSTATION INIT ****\n");
#endif

}

void loop()
{
#if PROGRAM_SELECT
    if(CAN_MSGAVAIL == CAN.checkReceive()) // check if data coming
    {
        digitalWrite(LED1, HIGH);
        serial_buf = 0;
        CAN.readMsgBuf(&len, receive_buf); // read data,  len: data length, receive_buf: data buf
        for(int i = 0; i < 8; i++)
        {
            serial_buf |= ((uint64_t)receive_buf[7 - i]) << (i * 8);
        }
        serial_queue.push(serial_buf);
        digitalWrite(LED1, LOW);
    }
    run_counter++;
    
    parseCANMessage();
    
    if(run_counter >= 10)
    {
        sendCANMessage();
        delay(100);
        run_counter = 0;
    }
#endif

#if !PROGRAM_SELECT
    transceiver_run();
#endif

    // Checks for GUI serial inputs
    if (Serial.available())
    {
        digitalWrite(LED2, HIGH);
        String serial_message = Serial.readStringUntil('\n');
        if(serial_message[0] == '^')
        {
            Frame message_out;
            message_out = parseMessageFromSerial(serial_message);
            
            if (message_out.is_ok)
                send_queue.push(message_out);
        }
        else if(serial_message[0] == '~')
        {
            handleCommand(serial_message);
        }
        digitalWrite(LED2, LOW);
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
    f.is_message = true;
    return f;
}

/**
* Send CAN message over CAN bus
*/
void sendCANMessage()
{
  if(!send_queue.isEmpty())
  {
      Frame message = send_queue.pop();
      switch(CAN.sendMsgBuf((int) message.id ,0, 8, message.data))
      {
          case CAN_OK:
          if(message.is_message)
              Serial.print("*Message sent!\n");
          Serial.print("@MSG_OK\n");
          break;
          case CAN_GETTXBFTIMEOUT:
          if(message.is_message)
              Serial.print("*Message not sent! CAN_Tx Timeout!\n");
          Serial.print("@MSG_ERR\n");
          break;
          case CAN_SENDMSGTIMEOUT:
          if(message.is_message)
              Serial.print("*Message not sent! Sending Timeout!\n");
          Serial.print("@MSG_ERR\n");
          break;
      }
  }
}

/**
* Prints out the data and ID received in a CAN frame. Messages can be
* filtered based on their IDs.
*/
void parseCANMessage()
{ 
    if(!serial_queue.isEmpty())
    {
    uint64_t data = serial_queue.pop();
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
    Frame message_out;
    message_out.is_ok = true;
    message_out.id = 20;
    message_out.data[7] = 0x30;
    message_out.data[6] = 0x02;
    message_out.data[5] = 0x02;
    //message_out.data[4] = 0x09;
    for(int i = 0x01; i <= 0x1B; i++)
    {
        message_out.data[4] = i;
        send_queue.push(message_out);
    }
    //send_queue.push(message_out);
    //CAN.sendMsgBuf(20 ,0, 8, send_buf);

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
    if(Serial.readStringUntil('\n').equals("1"))
        trans_mode();
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

/*
 *  Transceiver mode
 *
 */
void trans_mode()
{
    Serial.print("*Transceriver mode!\n");
    while(1)
    {
        
    }
}

//************************************************************ FUNCTION DECLARATION**********************************************//

void transceiver_initialize(void)
{
    set_CSn(0);
    while(digitalRead(pin_MISO))  // Wait for MISO to go low.
    cmd_str(SRES);             //SRES                  reset chip
    delay(100);
    cmd_str(SFRX);             //SFRX                  flush RX FIFO
    cmd_str(SFTX);             //SFTX                  flush TX FIFO
    /* Settings taken from SmartRF */
    reg_settings();
    /* Calibrate */
    cmd_str(SCAL);
    delay(250);
    cmd_str(SAFC);
    delay(250);

    rx_mode = 1;
    tx_mode = 0;
    rx_length = 0;
    prepareAck();
    /* Put in RX Mode */
    cmd_str(SRX);
    return;
}

void transceiver_run(void)
{
    byte *state, *CHIP_RDYn, rxFirst, rxLast, txFirst, txLast, check;
    delay(250);
    if (millis() - lastCycle < TRANSCEIVER_CYCLE)
        return;
    
    if(tx_mode)
    {
        rx_mode = 0;
        tx_length = reg_read2F(NUM_TXBYTES);
        if(tx_length)
        {
            if(tx_fail_count)
            {
                cmd_str(SIDLE);
                cmd_str(SFTX);
                cmd_str(SRX);
                rx_mode = 1;
                tx_mode = 0;
                tx_fail_count = 0;
                lastCycle = millis();
                return;
            }
            else
            {
                cmd_str(STX);
                tx_fail_count++;
            }
        }
        else
        {
            cmd_str(SRX);
            rx_mode = 1;
            tx_mode = 0;
            lastCycle = millis();
            return;
        }
    }
    if(rx_mode)
    {
        tx_mode = 0;
        rx_length = reg_read2F(NUM_RXBYTES);
        Serial.print("RX_LENGTH: ");
        Serial.println(rx_length);
        rxFirst = reg_read2F(RXFIRST);
        Serial.print("RXFIRST: ");
        Serial.println(rxFirst);
        rxLast = reg_read2F(RXLAST);
        Serial.print("RXLAST ");
        Serial.println(rxLast);
        /* Got some data */
        if(rx_length)
        {
            delay(200);      // Relic of working code.
            if(rx_length > REAL_PACKET_LENGTH)
            {
                Serial.print("\nSTART PACKET\n");
                load_packet();
                Serial.print("\nEND PACKET\n");
                /* We have a packet */
                if(rx_length <= (rxLast - rxFirst + 1))     // Length = data + address byte + length byte
                {
                    check = store_new_packet();
                    rx_length = 0;
                    if(!check)                                  // Packet was accepted and stored internally.
                    {
                        Serial.print("\nGOOD PACKET\n");
                        prepareAck();
                        cmd_str(STX);
                        return;             
                    }

                }
            }
            else if(rx_length > ACK_LENGTH)
            {
                load_ack();

                /* We have an acknowledgment */
                if(new_packet[1] == 0x41 && new_packet[2] == 0x43 && new_packet[3] == 0x4B) // Received proper acknowledgment.
                {
                    Serial.print("\nRECEIVED ACK\n");
                    lastAck = millis();
                    lastTransmit = millis();
                    //if(last_tx_packet_height)
                        //current_tm_fullf = 0;             // Second half of packet was sent, set current_tm_fullf to zero.
                    //ack_acquired = 1;
                }
            }
                cmd_str(SIDLE);         // Want to get rid of this.
                cmd_str(SFRX);
                cmd_str(SRX);               
        }
        get_status(CHIP_RDYn, state);
        if(*state == 0b110)
        {
            cmd_str(SIDLE);
            cmd_str(SFRX);
            //cmd_str(SRX);
        }
        cmd_str(SRX);           // Make sure we're in RXSTATE while in rx-mode.
    }
    if(millis() - lastAck > ACK_TIMEOUT)
    {
        delay((byte)rand());
        lastAck = millis();
    }
    if(millis() - lastCalibration > CALIBRATION_TIMEOUT)    // Calibrate the transceiver.
    {
        set_RSTn(0);
        delay(250);
        set_RSTn(1);
        transceiver_initialize();
        lastCalibration = millis();
    }
    if(millis() - lastTransmit > TRANSMIT_TIMEOUT)  // Transmit packet (if one is available)
    {
        Serial.print("\nSENDING PACKET\n");
        cmd_str(SIDLE);
        cmd_str(SFRX);
        cmd_str(SFTX);
        delay(5);
        transmit_packet();
        lastTransmit = millis();
    }
    lastCycle = millis();
}

void reg_settings(void)
{
    //high performance settings
    reg_write2F(FS_DIG1, 0x00);             //FS_DIG1: 0x00         Frequency Synthesizer Digital Reg. 1
    reg_write2F(FS_DIG0, 0x5F);             //FS_DIG0: 0x5F         Frequency Synthesizer Digital Reg. 0
    reg_write2F(FS_CAL1, 0x40);             //FS_CAL1: 0x40         Frequency Synthesizer Calibration Reg. 1
    reg_write2F(FS_CAL0, 0x0E);             //FS_CAL0: 0x0E         Frequency Synthesizer Calibration Reg. 0
    reg_write2F(FS_DIVTWO, 0x03);           //FS_DIVTWO: 0x03       Frequency Synthesizer Divide by 2
    reg_write2F(FS_DSM0, 0x33);             //FS_DSM0: 0x33         FS Digital Synthesizer Module Configuration Reg. 0
    reg_write2F(FS_DVC0, 0x17);             //FS_DVCO: 0x17         Frequency Synthesizer Divider Chain Configuration ..
    reg_write2F(FS_PFD, 0x50);              //FS_PFD: 0x50          Frequency Synthesizer Phase Frequency Detector Con..
    reg_write2F(FS_PRE, 0x6E);              //FS_PRE: 0x6E          Frequency Synthesizer Prescaler Configuration
    reg_write2F(FS_REG_DIV_CML, 0x14);      //FS_REG_DIV_CML: 0x14  Frequency Synthesizer Divider Regulator Configurat..
    reg_write2F(FS_SPARE, 0xAC);            //FS_SPARE: 0xAC        Set up Frequency Synthesizer Spare
    reg_write2F(FS_VCO0, 0xB4);             //FS_VCO0: 0xB4         FS Voltage Controlled Oscillator Configuration Reg..
    reg_write2F(XOSC5, 0x0E);               //XOSC5: 0x0E           Crystal Oscillator Configuration Reg. 5
    reg_write2F(XOSC1, 0x03);               //XOSC1: 0x03           Crystal Oscillator Configuration Reg. 0
    
    /************************************/
    //For test purposes only, (2nd block, deleted first one) use values from SmartRF for some bits
    //High performance RX
    cmd_str(SNOP);
    reg_write(SYNC_CFG1, 0x0B);             //
    reg_write(DCFILT_CFG, 0x1C);            //
    reg_write(IQIC, 0x00);                  //
    reg_write(CHAN_BW, 0x04);               //
    reg_write(MDMCFG0, 0x05);               //
    reg_write(AGC_CFG1, 0xA9);              //
    reg_write(AGC_CFG0, 0xCF);              //
    reg_write(FIFO_CFG, 0xFF);              //
    reg_write(SETTLING_CFG, 0x03);          //
    reg_write2F(IF_MIX_CFG, 0x00);          //
    /**************************************/
    
    //modulation and freq deviation settings
    reg_write(DEVIATION_M, 0b01001000);     //DEVIATION_M: 0x48      set DEV_M to 72 which sets freq deviation to 20.019531kHz (with DEV_M=5)
    reg_write(MODCFG_DEV_E, 0b00000101);    //MODCFG_DEV_E: 0x05     set up modulation mode and DEV_E to 5 (see DEV_M register)
    reg_write(FS_CFG, 0b00010100);          //FS_CFG: B00010100      set up LO divider to 8 (410.0 - 480.0 MHz band), out of lock detector disabled
    
    //set preamble
    //reg_write(PREAMBLE_CFG1, 0b00001101);         //PREAMBLE_CFG1: 0x00    No preamble
    //reg_write_bit(PREAMBLE_CFG0, 5, 1);     //PQT_EN: 0x00           Preamble detection disabled
    reg_write(PREAMBLE_CFG1, 0x14);
    reg_write(PREAMBLE_CFG0, 0x2A);
    reg_write(SYMBOL_RATE2, 0x73);
    //reg_write(SYMBOL_RATE1, 0x05);
    //reg_write(SYMBOL_RATE0, 0xBC);
    
    //TOC_LIMIT
    reg_write_bit2F(TOC_CFG, 7, 0);         //TOC_LIMIT: 0x00      Using the low tolerance setting (TOC_LIMIT = 0) greatly reduces system settling times and system power consumption as no preamble bits are needed for bit synchronization or frequency offset compensation (4 bits preamble needed for AGC settling).
    reg_write_bit2F(TOC_CFG, 6, 0);         //TOC_LIMIT: 0x00      Using the low tolerance setting (TOC_LIMIT = 0) greatly reduces system settling times and system power consumption as no preamble bits are needed for bit synchronization or frequency offset compensation (4 bits preamble needed for AGC settling).
    
    //set SYNC word
    reg_write_bit(SYNC_CFG1, 6, 1);         //PQT_GATING_EN: 0       PQT gating disabled (preamble not required)
    reg_write(SYNC_CFG0, 0x17);             //SYNC_CFG0: B00010111   32 bit SYNC word. Bit error qualifier disabled. No check on bit errors
    reg_write(SYNC3, 0x93);                 //SYNC3: 0x93            Set SYNC word bits 31:24
    reg_write(SYNC2, 0x0B);                 //SYNC2: 0x0B            Set SYNC word bits 23:16
    reg_write(SYNC1, 0x51);                 //SYNC1: 0x51            Set SYNC word bits 15:8
    reg_write(SYNC0, 0xDE);                 //SYNC0: 0xDE            Set SYNC word bits 7:0
    
    cmd_str(SNOP);
    //set packets
    reg_write_bit(MDMCFG1, 6, 1);           //FIFO_EN: 0             FIFO enable set to true
    reg_write_bit(MDMCFG0, 6, 0);           //TRANSPARENT_MODE_EN: 0 Disable transparent mode
    reg_write(PKT_CFG2, 0b00000000);        //PKT_CFG2: 0x00         set FIFO mode
    reg_write(PKT_CFG1, 0b00110000);        //PKT_CFG1: 0x30         set address check and 0xFF broadcast
    reg_write(PKT_CFG0, 0b00100000);        //PKT_CFG0: 0x30         set variable packet length
    reg_write(PKT_LEN, 0xFF);               //PKT_LEN: 0xFF          set packet max packet length to 0x7F
    reg_write(DEV_ADDR, DEVICE_ADDRESS);    //DEV_ADDR register is set to DEVICE_ADDRESS
    reg_write(RFEND_CFG1, 0b00101110);      //RFEND_CFG1: 0x2E       go to TX after a good packet, RX timeout disabled.
    //reg_write(0x29, 0b00111110);          //RFEND_CFG1: 0x3E       go to RX after a good packet
    reg_write(RFEND_CFG0, 0b00110000);      //RFEND_CFG0: 0x30       go to RX after transmitting a packet
    //reg_write(0x2A, 0b00100000);          //RFEND_CFG0: 0x20       go to TX after transmitting a packet
    
    //set power level
    reg_write(PA_CFG2, 0b01111111);         //PA_CFG2: 0x7F          set POWER_RAMP to 64 (output power to 14.5dBm, equation 21)
    
    //frequency offset setting
    reg_write2F(FREQOFF1, 0);               //FREQOFF1: 0x00         set frequency offset to 0
    reg_write2F(FREQOFF0, 0);               //FREQOFF0: 0x00
    
    //Frequency setting
    reg_write2F(FREQ2, 0x6C);               //FREQ2: 0x6C            set frequency to 434MHz (sets Vco, see equation from FREQ2 section of user guide)
    reg_write2F(FREQ1, 0x80);               //FREQ1: 0x80
    reg_write2F(FREQ0, 0x00);               //FREQ0: 0x00   
    return;
}

//write to register address addr with data
byte reg_read(byte addr)
{
    byte addr_new, msg;
    addr_new = addr + B10000000; //add the read bit
    SS_set_low();
    msg = SPI.transfer(addr); //send desired address
    delayMicroseconds(20);
    msg = SPI.transfer(0); //read back
    delayMicroseconds(20);
    SS_set_high();
    return msg;
}

//reads register in extended memory space
byte reg_read2F(byte addr)
{
    byte msg;
    msg = B10101111;
    SS_set_low();
    msg = SPI.transfer(msg); //address extension command
    delayMicroseconds(20);
    msg = SPI.transfer(addr); //send the desired address
    delayMicroseconds(20);
    msg =  SPI.transfer(0); //read back
    delayMicroseconds(20);
    SS_set_high();
    return msg;
}

//write to register address addr with data
void reg_write(byte addr, byte data)
{
    byte msg;
    SS_set_low();
    msg = SPI.transfer(addr); //send desired address
    delayMicroseconds(20);
    msg = SPI.transfer(data); //send desired address
    delayMicroseconds(20);
    SS_set_high();
    return;
}

//rwrites to register in extended memory space
void reg_write2F(byte addr, byte data)
{
    cmd_str(SNOP);
    byte msg;
    msg = B00101111;
    SS_set_low();
    msg = SPI.transfer(msg); //address extension command
    delayMicroseconds(20);
    msg = SPI.transfer(addr); //send desired address
    delayMicroseconds(20);
    msg = SPI.transfer(data); //send desired address
    delayMicroseconds(20);
    SS_set_high();
    return;
}

//writes status information to variables in main loop
void get_status(byte *CHIP_RDYn, byte *state)
{  
  byte msg = cmd_str(SNOP);  
  *CHIP_RDYn = (msg >> 7) & 1; //7th bit (reading backwards)
  *state = (msg >> 4) & 7;
  return;
}

//send command strobe and print info on command strobe if Print bit is true
byte cmd_str(byte addr)
{
    byte msg;
    msg = SPI.transfer(addr);
    delayMicroseconds(20);
    delayMicroseconds(1);
    return msg;
}

//reads FIFO using direct access
byte dir_FIFO_read(byte addr)
{
    cmd_str(SNOP);
    byte msg = B10111110;
    SS_set_low();
    msg = SPI.transfer(msg); //direct FIFO read address
    delayMicroseconds(20);
    msg = SPI.transfer(addr); //send desired address
    delayMicroseconds(20);
    msg = SPI.transfer(0);
    delayMicroseconds(20);
    SS_set_high();
    return msg;
}

//writes in FIFO using direct access
byte dir_FIFO_write(byte addr, byte data)
{
    cmd_str(SNOP);
    byte msg = B00111110;
    SS_set_low();
    msg = SPI.transfer(msg); //direct FIFO write address
    delayMicroseconds(20);
    msg = SPI.transfer(addr); //send desired FIFO address
    delayMicroseconds(20);
    msg = SPI.transfer(data); //send desired data
    delayMicroseconds(20);
    SS_set_high();
    return msg;
}

//sets chip select to either LOW or HIGH
void set_CSn(bool state)
{
  if(state)
    digitalWrite(pin_SS, HIGH);
  else
    digitalWrite(pin_SS, LOW);
}

void set_RSTn(bool state)
{
    if(state)
        digitalWrite(pin_RST_TRX, HIGH);
    else
        digitalWrite(pin_RST_TRX, LOW);
}

//changes the nth bit in register 'reg' to data
void reg_write_bit(byte reg, byte n, byte data)
{
    byte msg, temp;
    msg = reg_read(reg);
    if(!data)
    {
        temp = ~(1 << n);
        msg = temp & msg;
    }
    else
    {
        temp = 1 << n;
        msg = temp | msg;
    }
    reg_write(reg, msg);
    return;
}

//changes the nth bit in register 'reg' to data (extended register space)
void reg_write_bit2F(byte reg, byte n, byte data)
{
    byte msg, temp;
    msg = reg_read2F(reg);
    if(!data)
    {
        temp = ~(1 << n);
        msg = temp & msg;
    }
    else
    {
        temp = 1 << n;
        msg = temp | msg;
    }
    reg_write2F(reg, msg);
    return;
}

// Here, address should correspond to the DEVICE_ADDRESS of the transceiver 
// that you want to communicate with.
void transceiver_send(byte* message, byte address, byte length)
{
    byte i;
    cmd_str(SIDLE);
    cmd_str(SFTX);
    // The first byte is the length of the packet (message + 1 for the address)
    dir_FIFO_write(0, length+2);
    // The second byte is the address
    dir_FIFO_write(1, address);
    // The rest is the actual data
    for(i = 0; i < length; i++)
    {
        dir_FIFO_write(i+2, message[i]);
    }
    //set up TX FIFO pointers
    reg_write2F(TXFIRST, 0x00);            //set TX FIRST to 0
    reg_write2F(TXLAST, length+3);              //set TX LAST (maximum OF 0X7F)
    //reg_write2F(RXFIRST, 0x00);              //set TX FIRST to 0
    //reg_write2F(RXLAST, 0x00); //set TX LAST (maximum OF 0X7F)
    //strobe commands to start TX
    cmd_str(STX);
    tx_mode = 1;
    rx_mode = 0;
    lastTransmit = millis();
}

void prepareAck(void)
{
    char* ackMessage = "ACK";
    byte ackAddress = 0xA5, i;
    cmd_str(SIDLE);
    cmd_str(SFTX);
    
    // Reset FIFO registers
    reg_write2F(TXFIRST, 0x00);
    // Put the ACK Packet in the FIFO
    dir_FIFO_write(0, (3 + 2));
    dir_FIFO_write(1, ackAddress);
    
    for(i = 0; i < 3; i++)
        dir_FIFO_write(i+2, ackMessage[i]);
    
    reg_write2F(TXFIRST, 0);
    reg_write2F(TXLAST, (3 + 3));
    reg_write2F(RXFIRST, 0x00);
    reg_write2F(RXLAST, 0x00);
    tx_mode = 1;
    rx_mode = 0;
    lastTransmit = millis();
    return;
}

byte store_new_packet(void)
{
    //byte i;  // packet_height = 0, offset = 0;
    //unsigned int pec;

    // ...

    /* There is room in the packet list */
    if(new_packet[76] != 0x18)                  // Characteristic of B151 in a telecommand.
        return 0xFF;
    return 0x00;
}

// The packet to be transmitted is assumed to be tm_to_downlink[] and be 152 bytes long.
byte transmit_packet(void)
{
    transceiver_send(tm_to_downlink + 76, DEVICE_ADDRESS, 76);
    return 1;
}

void clear_new_packet(void)
{
    for(byte i = 0; i < 128; i ++){
        new_packet[i] = 0;
    }
}

void clear_current_tc(void)
{
    for(byte i = 0; i < PACKET_LENGTH; i ++){
        current_tc[i] = 0;
    }
}

void load_packet(void)
{
    byte i = 0;
    //new_packet[0] = reg_read(STDFIFO);
    //Serial.println(new_packet[i], HEX);
    for(i = 0; i < (REAL_PACKET_LENGTH + 2); i++)
    {
        //new_packet[i] = reg_read(STDFIFO);
        new_packet[i] = dir_FIFO_read(0x80 + i);
        Serial.print(i);
        Serial.print(": ");
        Serial.println(new_packet[i], HEX);
    }
    return;
}

void load_ack(void)
{
    byte i = 0;
    //new_packet[0] = reg_read(STDFIFO);
    //Serial.println(new_packet[i], HEX);
    for(i = 0; i < (ACK_LENGTH + 2); i++)
    {
        //new_packet[i] = reg_read(STDFIFO);
        new_packet[i] = dir_FIFO_read(0x80 + i);
        Serial.println(new_packet[i], HEX);
    }
    return;
}

void setup_fake_tc(void)
{
    byte version, type, sequence_flags, service_type, service_sub_type, i;
    unsigned int pec;
    version = 0;
    type = 1;
    sequence_flags = 0x02;
    service_type = 3;           // HK Service
    service_sub_type = 9;       // Req HK Definition report
    // Packet Header
    tm_to_downlink[151] = ((version & 0x07) << 5) | ((type & 0x01) << 4) | (0x08);
    tm_to_downlink[150] = HK_TASK_ID;
    tm_to_downlink[149] = sequence_flags;
    tm_to_downlink[148] = transmitting_sequence_control;
    tm_to_downlink[147] = 0x00;
    tm_to_downlink[146] = PACKET_LENGTH - 1;
    version = 1;
    // Data Field Header
    tm_to_downlink[145] = ((version & 0x07) << 4) | 0x8A;
    tm_to_downlink[144] = service_type;
    tm_to_downlink[143] = service_sub_type;
    tm_to_downlink[142] = HK_GROUND_ID;
    tm_to_downlink[140] = 0;
    tm_to_downlink[139] = 0;
    pec = fletcher16(tm_to_downlink + 2, 150);
    tm_to_downlink[1] = (byte)(pec >> 8);
    tm_to_downlink[0] = (byte)(pec);
    
    tm_to_downlink[75] = 0x88;      // Indicator of this being the lower 76 bytes.
    
    return;
}

unsigned int fletcher16(byte* data, int count)
{
    unsigned int sum1 = 0;
    unsigned int sum2 = 0;
    int i;
    for(i = 0; i < count; i++)
    {
        sum1 = (sum1 + data[i]) % 255;
        sum2 = (sum2 + sum1) % 255;
    }
    
    return (sum2 << 8) | sum1;
}

void SS_set_high(void) 
{
    //set_CSn(1);
    delayMicroseconds(1);
}

void SS_set_low(void)
{
    //set_CSn(0);
    delayMicroseconds(1);
}