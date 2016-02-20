/*
* FILE NAME: canbus_gui_defs
* PURPOSE: Definitions for the laptop interface

* DEVELOPMENT HISTORY:
*   Date          Author              Description of Change
*   2/13/16       Steven Yin          File created
*
*/

// Imports
import java.util.Date;
import java.text.*;
import javax.swing.JOptionPane;
import java.util.Queue;
import java.util.LinkedList;
import processing.serial.*;

// The time object
Date time;
SimpleDateFormat time_f = new SimpleDateFormat("hh"+":"+"mm"+":"+"ss");

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
PFont mono, bold, title;

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

String[] fields = {"TEMP [C]", "VOLTAGE [V]", "CURRENT [mA]", "BATTERY %", "PRES [KPa]", "HUMIDITY %"};
String[] rows = { "ADCS", "CDH", "COMS", "EPS", "PAYL"};

int[] column_centers = new int[fields.length];
int[] can_status_pos = new int[2];
int[] msg_status_pos = new int[2];

// Data streams for arduino, outgoing messages ans can bus
Queue arduino_stream;

String msg_status_message;
Queue outgoing_message_stream;
boolean msg_status = false;

String can_status_message;
Queue can_stream;
boolean can_status;

// Subsystems & properties
Subsystem adcs, cdh, coms, eps, payl;

// Put all the Subsystems in arraylist therefore easy to loop through
ArrayList<Subsystem> s_list = new ArrayList<Subsystem>();

//final String[] ADCS_IDS = {};
//final String[] CDH_IDS = {"10"};
//final String[] COMS_IDS = {};
//final String[] EPS_IDS = {};
//final String[] PAYL_IDS = {};

// Number of messages shown
final int MESSAGE_NUM = 25;

final float SENSOR_OFFSET = 1426063360; // 0x55000000

// Serial Constants
int baud_rate;

String out_id, out_data;
String in_string;
String filter;

Serial arduino;

// Normal interface or plot interface
boolean isPlot = false;

class Subsystem
{
    //String[] mailbox_ids;
    
    boolean temp_avail = false,
    volt_avail = false,
    curr_avail = false,
    humid_avail = false,
    batt_avail = false,
    pres_avail = false;
    
    float temp, volt, curr, humid, batt, pres;
    
    // LinkedList that saves all data in the past x data points
    LinkedList<Float>[] my_data_list = new LinkedList[fields.length];
    
    // Data update status updated if true
    boolean is_updated[] = new boolean[fields.length];

    // Data buffer saves updated data
    float my_data[] = new float[fields.length];
    
    // The plot colour for this subsystem
    color plot_color;
    
    Subsystem (color c)
    {
        //mailbox_ids = mb_ids;
        plot_color = c;
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
final int UPDATE_INTERVAL = 5000;

// Last time sensor data request
long last_date = 0;

// T minus(the time period showed on the plot) in seconds
final int T_MINUS = 300;

// Setting the delta x for the scaling
int DELTA_X;

// Grid x
final int GRID_X = 10;

// Grid y
final int GRID_Y = 10;

// The types for the selection of which to plot
public enum plot_type
{
    tempreture,
    voltage,
    current,
    battery,
    pressure,
    humidity;
}

final color plot_red = color(255, 0, 0);
final color plot_green = color(0, 255, 0);
final color plot_blue = color(0, 0, 255);
final color plot_yellow = color(255, 255, 0);
final color plot_pink = color(255, 0, 255);

// Plot tempreture by default
plot_type my_plot = plot_type.tempreture;

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

// Boundaries for plotting NEED TO BE CHANGED
float boundaries_high[] = {100, 100, 100, 100, 100, 100};
float boundaries_low[] = {0, 0, 0, 0, 0, 0};