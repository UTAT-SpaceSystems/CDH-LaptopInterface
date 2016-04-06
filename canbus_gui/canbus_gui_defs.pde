/*
* FILE NAME: canbus_gui_defs
* PURPOSE: Definitions for the laptop interface

* DEVELOPMENT HISTORY:
*   Date          Author              Description of Change
*   02/13/16      Steven Yin          File created
*
*   02/21/16      Steven Yin          Changed data structure
*
*/

// Imports
import java.util.Date;
import java.text.*;
import javax.swing.JOptionPane;
import java.util.Queue;
import java.util.LinkedList;
import processing.serial.*;

// Working mode
int mode = 1;

// The time object
Date time;
SimpleDateFormat time_f = new SimpleDateFormat("kk"+":"+"mm"+":"+"ss");
SimpleDateFormat sat_time_f = new SimpleDateFormat("dd"+":"+"kk"+":"+"mm");

// COM port result
String port_selection;

// If Serial was started
boolean is_started = false;

// Save the status for the handshake
boolean firstContact = false;

// Data Logging
PrintWriter log;
DisposeHandler dh;

// Assets
PImage crest;
PFont sourcepro, title;

// GUI Constants
final int HEADER_HEIGHT = 120;
final int FOOTER_HEIGHT = 130;
final int UNDERLINE_HEIGHT = 45;
final int LEFT_JUSTIFY = 15;
final int INITIAL_SPACING = 200;

final color white = color(255, 255, 255);
final color black = color(0, 0, 0);
final color blue = color(0, 0, 47);
final color red = color(255, 0, 0);
final color green = color(58, 255, 41);
final color grey = color(200, 200, 200);
final color yellow = color(255, 255, 0);

// The types for the selection of which to plot
public enum SensorType
{
    tempreture(0),
    voltage(1),
    current(2),
    acceleration(3),
    pressure(4),
    humidity(5);
    
    int num; // Number 0-5
    
    SensorType(int a)
    {
        num = a;
    }
    
    int value()
    {
        return num;
    }
}

// The big object for everything
ArrayList<SensorGroup> full_sensor_list = new ArrayList();

String[] fields = {"TEMP [C]", "VOLTAGE [V]", "CURRENT [mA]", "ACCELERATION %", "PRES [KPa]", "HUMIDITY %"};

int[] column_centers = new int[fields.length];

// Data streams for arduino, outgoing messages ans can bus
String arduino_status_message;
Queue arduino_stream;

String msg_status_message;
String packet_status_message;
Queue outgoing_message_stream;

String can_status_message;
String trans_status_message;
Queue can_stream;

// Staus variables
int arduino_status = 0;
int can_status = 0;
int trans_status = 0;
int msg_status = 0;
int packet_status = 0;

// Sat time available
boolean is_sat_time_avail = false;

// Sensor Groups
SensorGroup temp = new SensorGroup(SensorType.tempreture);
SensorGroup volt = new SensorGroup(SensorType.voltage);
SensorGroup curr = new SensorGroup(SensorType.current);
SensorGroup acce = new SensorGroup(SensorType.acceleration);
SensorGroup pres = new SensorGroup(SensorType.pressure);
SensorGroup humi = new SensorGroup(SensorType.humidity);

// Number of messages shown
final int MESSAGE_NUM = 30;

// Serial Constants
int baud_rate;

String out_id, out_data;
String in_string;
String filter;

Serial arduino;

// Normal interface or plot interface
boolean isPlot = false;

class SensorGroup
{
    SensorType type;
    ArrayList<Sensor> sensor_list = new ArrayList();
    float boundary_low;
    float boundary_high; 
    
    SensorGroup(SensorType t) // Constructor
    {
        type = t;
    }
    
    void add_sensor(Sensor s) // Method that add a sensor to a group
    {
        sensor_list.add(s);
    }
}

class Sensor
{
    String sensor_name;
    int sensor_id;
    boolean sensor_avail = false;
    boolean sensor_is_updated = false;
    LinkedList<Float> sensor_data = new LinkedList();
    float sensor_data_buff;
    color sensor_color;
    
    Sensor(String name, int id, color c) // Constructor
    {
        sensor_name = name;
        sensor_id = id;
        sensor_color = c;
    }
}

public class DisposeHandler
{
    
    DisposeHandler(PApplet pa)
    {
        pa.registerMethod("dispose", this);
    }
    
    public void dispose()
    {
        log.flush(); // Writes the remain
        log.close(); // Finishes the file
    }
}

/*
 *
 *   plot_data defines
 *
 */
 
// Updating inteval in milliseconds
int UPDATE_INTERVAL;

// Last time sensor data request
long last_date = 0;

// T minus(the time period showed on the plot) in seconds
int T_MINUS = 300;

// Setting the delta x for the scaling
int DELTA_X;

// Grid x
final int GRID_X = 10;

// Grid y
final int GRID_Y = 10;

final color plot_red = color(255, 0, 0);
final color plot_green = color(0, 255, 0);
final color plot_blue = color(0, 0, 255);
final color plot_yellow = color(255, 255, 0);
final color plot_pink = color(255, 0, 255);
final color plot_cyan = color(0, 255, 255);
final color plot_orange = color(255, 128, 0);
final color plot_purple = color(128, 0, 255);
final color plot_brown = color(128, 64, 0);

// Plot tempreture by default
SensorType my_plot = SensorType.tempreture;

/* SENSOR NAMES      */
final int PANELX_V = 0x01;
final int PANELX_I = 0x02;
final int PANELY_V = 0x03;
final int PANELY_I = 0x04;
final int BATTM_V = 0x05;
final int BATT_V = 0x06;
final int BATTIN_I = 0x07;
final int BATTOUT_I = 0x08;
final int BATT_TEMP = 0x09;
final int EPS_TEMP = 0x0A;
final int COMS_V = 0x0B;
final int COMS_I = 0x0C;
final int PAY_V = 0x0D;
final int PAY_I = 0x0E;
final int OBC_V = 0x0F;
final int OBC_I = 0x10;
final int SHUNT_DPOT = 0x11;
final int COMS_TEMP = 0x12;
final int OBC_TEMP = 0x13;
final int PAY_TEMP0 = 0x14;
final int PAY_TEMP1 = 0x15;
final int PAY_TEMP2 = 0x16;
final int PAY_TEMP3 = 0x17;
final int PAY_TEMP4 = 0x18;
final int PAY_HUM = 0x19;
final int PAY_PRESS = 0x1A;
final int PAY_ACCEL = 0x1B;
final int MPPTX = 0x1C;
final int MPPTY = 0x1D;
final int ABS_TIME_D = 0x1E;
final int ABS_TIME_H = 0x1F;
final int ABS_TIME_M = 0x20;