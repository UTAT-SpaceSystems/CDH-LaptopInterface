/*
----------------------------------
UTAT Space Systems CANBus Analyzer
----------------------------------

DEVELOPMENT HISTORY:
Date          Author              Description of Change
02/04/16      Steven Yin          Created
                                  Added basic commands
                                  
02/21/16      Steven Yin          Updated to work with new library

*/

#ifndef arduino_defs_h
#define arduino_defs_h

#include <SPI.h>
#include "mcp_can.h"
#include "QueueArray.h"

// Pin definitions specific to how the MCP2515 is wired up.
const int SPI_CS_PIN = 10;

MCP_CAN CAN(SPI_CS_PIN);  // Set CS pin

typedef struct
{
    boolean is_ok = false; // Ok to send or not
    boolean is_message = false; // Message from user
    byte id;      // MOB
    byte data[8]; // Data
} Frame;

// The FIFO buffer for serial output
QueueArray<uint64_t> serial_queue;

// The FIFO buffer for send can message
QueueArray<Frame> send_queue;

byte len;
byte receive_buf[8];
uint64_t serial_buf;

volatile int run_counter = 0;

// LEDS
#define LED1      7
#define LED2      8

// Commands DEFINE
#define REQ_SENSOR_DATA   0x00

#endif
