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

/*
 * Software Macros
 */

// The invertal between sensor data request
#define REQUEST_SENSOR_DATA_INTERVAL 5000


/*
 * Hardware Macros
 */

// Pin definitions specific to how the MCP2515 is wired up.
#define CS_PIN    10
#define INT_PIN    2

// For the First Byte(Commands)


// For the Second Byte(Data)

#endif
