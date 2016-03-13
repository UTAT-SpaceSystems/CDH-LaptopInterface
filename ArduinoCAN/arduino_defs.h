/*
----------------------------------
UTAT Space Systems CANBus Analyzer
----------------------------------

DEVELOPMENT HISTORY:
Date          Author              Description of Change
02/04/16      Steven Yin          Created
                                  Added basic commands
                                  
02/21/16      Steven Yin          Updated to work with new library

03/12/16      Steven Yin          Updated the defs for the transceiver

*/

#ifndef arduino_defs_h
#define arduino_defs_h

#include "mcp_can.h"
#include "QueueArray.h"

/* HK Definitions */
#define PANELX_V				0x01
#define PANELX_I				0x02
#define PANELY_V				0x03
#define PANELY_I				0x04
#define BATTM_V					0x05
#define BATT_V					0x06
#define BATTIN_I				0x07
#define BATTOUT_I				0x08
#define BATT_TEMP				0x09
#define EPS_TEMP				0x0A
#define COMS_V					0x0B
#define COMS_I					0x0C
#define PAY_V					0x0D
#define PAY_I					0x0E
#define OBC_V					0x0F
#define OBC_I					0x10
#define SHUNT_DPOT				0x11
#define COMS_TEMP				0x12
#define OBC_TEMP				0x13
#define PAY_TEMP0				0x14
#define PAY_TEMP1				0x15
#define PAY_TEMP2				0x16
#define PAY_TEMP3				0x17
#define PAY_TEMP4				0x18
#define PAY_HUM					0x19
#define PAY_PRESS				0x1A
#define PAY_ACCEL				0x1B
#define MPPTX                   0x1C
#define MPPTY                   0x1D
#define ABS_TIME_D              0x1E
#define ABS_TIME_H              0x1F
#define ABS_TIME_M              0x20

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

// Commands DEFINE
#define REQ_SENSOR_DATA   0x00
#define GET_TRANS_DATA    0x01

// BIG_ARRAY
uint8_t hk_array[76];

// Commands Flags
uint8_t toggle_values = 0;
uint8_t req_hk = 0;
uint8_t req_time = 0;

// The FIFO buffer for serial output(trans)
QueueArray<uint32_t> trans_serial_queue;

/********************************** CAN DEFINES**********************************/

// Pin definitions specific to how the MCP2515 is wired up.
const int SPI_CS_PIN = 10;

MCP_CAN CAN(SPI_CS_PIN);  // Set CS pin

typedef struct
{
    boolean is_ok = false; // Ok to send or not
    boolean is_message = false; // Message from user
    byte id;      // MOB
    byte data[8]; // Data
}Frame;

// The FIFO buffer for serial output
QueueArray<uint64_t> can_serial_queue;

// The FIFO buffer for send can message
QueueArray<Frame> can_send_queue;

byte len;
byte receive_buf[8];
uint64_t serial_buf;

volatile int run_counter = 0;

// LEDS
#define LED1      7
#define LED2      8

#endif
