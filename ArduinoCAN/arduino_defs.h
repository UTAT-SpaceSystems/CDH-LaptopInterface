/*
----------------------------------
UTAT Space Systems LaptopInterface
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

/* PROGRAM SELECTION */
#define PROGRAM_SELECT  1// 1 == CAN-BUS, 0 == TRANSCEIVER

/* PARAMETER DEFINITIONS */
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
#define PAY_ACCEL_X				0x1B
#define PAY_FL_PD0				0x1C
#define PAY_FL_PD1				0x1D
#define PAY_FL_PD2				0x1E
#define PAY_FL_PD3				0x1F
#define PAY_FL_PD4				0x20
#define PAY_FL_PD5				0x21
#define PAY_FL_PD6				0x22
#define PAY_FL_PD7				0x23
#define PAY_FL_PD8				0x24
#define PAY_FL_PD9				0x25
#define PAY_FL_PD10				0x26
#define PAY_FL_PD11				0x27
#define MPPTX                   0xFF
#define MPPTY                   0xFE
#define PAY_TEMP				0x64
#define PAY_ACCEL_Y				0x65
#define PAY_ACCEL_Z				0x66

/* Transceiver Definitions */
#define PACKET_LENGTH 152
#define DATA_LENGTH 137
#define STATUS_INTERVAL 1000
#define ACK_TIMEOUT 1000
#define TRANSCEIVER_CYCLE 100
#define TRANSMIT_TIMEOUT 2000
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

/* define crystal oscillator frequency to 32MHz */
#define f_xosc 32000000;

/* SPI PIN DEFINTIONS */
#define pin_SS 9
#define pin_RST_TRX 6
#define pin_MOSI 11
#define pin_MISO 12
#define pin_SCK 13

/* PUS Definitions */
/* Definitions to clarify which services represent what.		*/
#define TC_VERIFY_SERVICE				1
#define HK_SERVICE						3
#define EVENT_REPORT_SERVICE			5
#define MEMORY_SERVICE					6
#define TIME_SERVICE					9
#define K_SERVICE						69
#define FDIR_SERVICE					70

/* Definitions to clarify which service subtypes represent what	*/
/* Housekeeping							*/
#define NEW_HK_DEFINITION				1
#define CLEAR_HK_DEFINITION				3
#define ENABLE_PARAM_REPORT				5
#define DISABLE_PARAM_REPORT			6
#define REPORT_HK_DEFINITIONS			9
#define HK_DEFINITON_REPORT				10
#define HK_REPORT						25
/* Diagnostics							*/
#define NEW_DIAG_DEFINITION				2
#define CLEAR_DIAG_DEFINITION			4
#define ENABLE_D_PARAM_REPORT			7
#define DISABLE_D_PARAM_REPORT			8
#define REPORT_DIAG_DEFINITIONS			11
#define DIAG_DEFINITION_REPORT			12
#define DIAG_REPORT						26
/* Time									*/
#define UPDATE_REPORT_FREQ				1
#define TIME_REPORT						2
/* Memory Management					*/
#define MEMORY_LOAD_ABS					2
#define DUMP_REQUEST_ABS				5
#define MEMORY_DUMP_ABS					6
#define CHECK_MEM_REQUEST				9
#define MEMORY_CHECK_ABS				10
#define DOWNLINKING_SCIENCE				0xCC
/* K-Service							*/
#define ADD_SCHEDULE					1
#define CLEAR_SCHEDULE					2
#define	SCHED_REPORT_REQUEST			3
#define SCHED_REPORT					4
#define PAUSE_SCHEDULE					5
#define RESUME_SCHEDULE					6
#define COMPLETED_SCHED_COM_REPORT		7
#define START_EXPERIMENT_ARM			8
#define START_EXPERIMENT_FIRE			9
#define SET_VARIABLE					10
#define GET_PARAMETER					11
#define SINGLE_PARAMETER_REPORT			12
/* FDIR Service							*/
#define ENTER_LOW_POWER_MODE			1
#define EXIT_LOW_POWER_MODE				2
#define ENTER_SAFE_MODE					3
#define EXIT_SAFE_MODE					4
#define ENTER_COMS_TAKEOVER_MODE		5
#define EXIT_COMS_TAKEOVER_MODE			6
#define PAUSE_SSM_OPERATIONS			7
#define RESUME_SSM_OPERATIONS			8
#define REPROGRAM_SSM					9
#define RESET_SSM						10
#define RESET_TASK						11
#define DELETE_TASK						12

/* SENDER ID */
#define HK_TASK_ID						0x04
#define DATA_TASK_ID					0x05
#define TIME_TASK_ID					0x06
#define COMS_TASK_ID					0x07
#define EPS_TASK_ID						0x08
#define PAY_TASK_ID						0x09
#define OBC_PACKET_ROUTER_ID			0x0A
#define SCHEDULING_TASK_ID				0x0B
#define FDIR_TASK_ID					0x0C
#define WD_RESET_TASK_ID				0x0D
#define MEMORY_TASK_ID					0x0E
#define HK_GROUND_ID					0x0F
#define TIME_GROUND_ID					0x10
#define MEM_GROUND_ID					0x11
#define GROUND_PACKET_ROUTER_ID 		0x13
#define FDIR_GROUND_ID					0x14
#define SCHED_GROUND_ID					0x15

// Commands DEFINE
#define REQ_SENSOR_DATA   0x00
#define GET_HK_DATA    0x01

/* CAN DEFINITIONS */

#define CAN0_MB0				1
#define CAN0_MB1				2
#define CAN0_MB2				3
#define CAN0_MB3				4
#define CAN0_MB4				5
#define CAN0_MB5				6
#define CAN0_MB6				7
#define CAN0_MB7				8

#define CAN1_MB0				10
#define CAN1_MB1				10
#define CAN1_MB2				11
#define CAN1_MB3				11
#define CAN1_MB4				11
#define CAN1_MB5				14
#define CAN1_MB6				14
#define CAN1_MB7				17

/* IDs for COMS/SUB0 mailboxes */
#define SUB0_ID0				20
#define SUB0_ID1				21
#define SUB0_ID2				22
#define SUB0_ID3				23
#define SUB0_ID4				24
#define SUB0_ID5				25

/* IDs for EPS/SUB1 mailboxes */
#define SUB1_ID0				26
#define SUB1_ID1				27
#define SUB1_ID2				28
#define SUB1_ID3				29
#define SUB1_ID4				30
#define SUB1_ID5				31

/* IDs for PAYLOAD/SUB2 mailboxes */
#define SUB2_ID0				32
#define SUB2_ID1				33
#define SUB2_ID2				34
#define SUB2_ID3				35
#define SUB2_ID4				36
#define SUB2_ID5				37

/* MessageType_ID  */
#define MT_DATA					0x00
#define MT_HK					0x01
#define MT_COM					0x02
#define MT_TC					0x03

/* SENDER_ID */
#define COMS_ID					0x00
#define EPS_ID					0x01
#define PAY_ID					0x02
#define OBC_ID					0x03
#define HK_TASK_ID				0x04
#define DATA_TASK_ID			0x05
#define TIME_TASK_ID			0x06
#define COMS_TASK_ID			0x07
#define EPS_TASK_ID				0x08
#define PAY_TASK_ID				0x09
#define OBC_PACKET_ROUTER_ID	0x0A
#define SCHEDULING_TASK_ID		0x0B
#define FDIR_TASK_ID			0x0C
#define WD_RESET_TASK_ID		0x0D
#define MEMORY_TASK_ID			0x0E
#define HK_GROUND_ID			0x0F
#define TIME_GROUND_ID			0x10
#define MEM_GROUND_ID			0x11
#define GROUND_PACKET_ROUTER_ID 0x13
#define FDIR_GROUND_ID			0x14
#define SCHED_GROUND_ID			0x15

/* COMMAND SMALL-TYPE: */
#define REQ_RESPONSE			0x01
#define REQ_DATA				0x02
#define REQ_HK					0x03
#define RESPONSE 				0x04
#define REQ_READ				0x05
#define ACK_READ				0x06
#define REQ_WRITE				0x07
#define ACK_WRITE				0x08
#define SET_SENSOR_HIGH			0x09
#define SET_SENSOR_LOW			0x0A
#define SET_VAR					0x0B
#define SET_TIME				0x0C
#define SEND_TM					0x0D
#define SEND_TC					0x0E
#define TM_PACKET_READY			0x0F
#define OK_START_TM_PACKET		0x10
#define TC_PACKET_READY			0x11
#define OK_START_TC_PACKET		0x12
#define TM_TRANSACTION_RESP		0x13
#define TC_TRANSACTION_RESP		0x14
#define SAFE_MODE_TYPE			0x15
#define SEND_EVENT				0x16
#define ASK_OBC_ALIVE			0x17
#define OBC_IS_ALIVE			0x18
#define SSM_ERROR_ASSERT		0x19
#define SSM_ERROR_REPORT		0x1A
#define ENTER_LOW_POWER_COM		0x1B
#define EXIT_LOW_POWER_COM		0x1C
#define ENTER_COMS_TAKEOVER_COM	0x1D
#define EXIT_COMS_TAKEOVER_COM	0x1E
#define PAUSE_OPERATIONS		0x1F
#define RESUME_OPERATIONS		0x20
#define LOW_POWER_MODE_ENTERED	0x21
#define LOW_POWER_MODE_EXITED	0x22
#define COMS_TAKEOVER_ENTERED	0x23
#define COMS_TAKEOVER_EXITED	0x24
#define OPERATIONS_PAUSED		0x25
#define OPERATIONS_RESUMED		0x26
#define OPEN_VALVES				0x27
#define COLLECT_PD				0x28
#define PD_COLLECTED			0x29

// If there is data in hk_array
bool is_hk_ready = false;
bool is_sci_ready = false;

struct packet{
	byte array[PACKET_LENGTH];
};

uint8_t hk_def[58];

#if !PROGRAM_SELECT

/* Global Variables for Transceiver Operations */
unsigned long previousTime = 0;
unsigned long currentTime = millis();
long int lastTransmit;
long int lastCycle;
long int lastAck;
long int lastToggle;
long int lastCalibration;
byte rx_mode, tx_mode, rx_length, tx_length;
//byte new_packet[PACKET_LENGTH];
byte tm_to_decode[PACKET_LENGTH];
byte packet_receivedf;
byte tx_fail_count;
byte ack_acquired;
byte transmitting_sequence_control;
byte tc_to_uplink[PACKET_LENGTH];

// BIG_ARRAY
uint8_t hk_array[76];

// Commands Flags
uint8_t toggle_values = 0;
uint8_t req_hk = 0;
uint8_t req_time = 0;

#endif

// The FIFO buffer for serial output(trans)
QueueArray<uint32_t> trans_serial_queue;

/********************************** CAN DEFINES**********************************/

typedef struct
{
    boolean is_ok = false; // Ok to send or not
    boolean is_message = false; // Message from user
    byte id;      // MOB
    byte data[8]; // Data
}Frame;

// Pin definitions specific to how the MCP2515 is wired up.
#if (PROGRAM_SELECT == 1)
const int SPI_CS_PIN = 10;

MCP_CAN CAN(SPI_CS_PIN);  // Set CS pin

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

#endif
