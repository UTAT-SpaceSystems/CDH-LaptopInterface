/*
----------------------------------
UTAT Space Systems CANBus Analyzer
----------------------------------

DEVELOPMENT HISTORY:
Date          Author              Description of Change
02/04/16      Steven Yin          Created
                                  Added basic commands

*/

#ifndef arduino_defs_h
#define arduino_defs_h


// Pin definitions specific to how the MCP2515 is wired up.
#define CS_PIN    10
#define INT_PIN    2

// LEDS
#define LED1      7
#define LED2      8

// Commands DEFINE
#define REQ_SENSOR_DATA   0x00

#endif
