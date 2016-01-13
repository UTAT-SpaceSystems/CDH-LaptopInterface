/*
* FILE NAME: canbus_gui
* PURPOSE: CAN bus analyzer for UTAT Space System's Heron MK1 CubeSat

* DEVELOPMENT HISTORY:
*   Date          Author              Release          Description of Change
*   06/14/15      Omar Abdeldayem     1.0              Monitoring (send, receive & log) fully functional 
*                 Albert Xie
*
*   01/12/16      Steven Yin          1.1              Compatible with Processing 3.0.1, Added COM selector, Prevent overwriting log file
*/

// Imports
import java.util.Date;
import java.text.*;
import javax.swing.JOptionPane;
import java.util.Queue;
import java.util.LinkedList;
import processing.serial.*;

// COM port result
String port_selection;

// If Serial was started
boolean is_started = false;

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

// Data streams for the bus and outgoing messages
String can_status_message;
Queue bus_stream;
boolean bus_status = false;

String msg_status_message;
Queue outgoing_message_stream;
boolean msg_status = false;

// Subsystems & properties
Subsystem adcs, cdh, coms, eps, payl;

final String[] ADCS_IDS = {};
final String[] CDH_IDS = {"10"};
final String[] COMS_IDS = {};
final String[] EPS_IDS = {};
final String[] PAYL_IDS = {};

final float SENSOR_OFFSET = 1426063360; // 0x55000000

// Serial Constants
int baud_rate;

String out_id, out_data;
String in_string;
String filter;

Serial arduino;

// Set GUI fullscreen 
void settings()
{
     fullScreen();
}

/*
* Setup Fucntion
*/
void setup()
{   
    // Setup the com port
    port_selection = (String) JOptionPane.showInputDialog(null,"Choose COM port:","UTAT",JOptionPane.QUESTION_MESSAGE,null,Serial.list(),Serial.list()[0]);
  
    size(displayWidth, displayHeight);  
  
    //Loading assets
    mono = loadFont("FreeSans-48.vlw");
    bold = loadFont("FreeSansBold-48.vlw");
    title = loadFont("FreeSansBoldOblique-48.vlw");
    crest = loadImage("crest.png");
    
    column_centers = new int[fields.length];
    
    // Set message heights
    can_status_pos = new int[]{displayWidth - 170, (HEADER_HEIGHT / 2) - 30};
    msg_status_pos = new int[]{displayWidth - 170, (HEADER_HEIGHT / 2) - 10};
    
    // Create subsystems
    adcs = new Subsystem(ADCS_IDS);
    cdh = new Subsystem(CDH_IDS);
    coms = new Subsystem(COMS_IDS);
    eps = new Subsystem(EPS_IDS);
    payl = new Subsystem(PAYL_IDS);
    
    // Baud rate must match the Arduino serial baud rate
    baud_rate = 9600;
    // Message filtering default
    filter = "00";
    in_string = "#\n";
    
    // Read current time info
    Date d = new Date();
    SimpleDateFormat date = new SimpleDateFormat("yyyyMMddhhmmss");
    String log_name = date.format(d);
    // Create the log file and dispose handler to clean up on exit
    log = createWriter("log"+ log_name +".txt");
    dh = new DisposeHandler(this);
    
    // Stream data structs
    bus_stream = new LinkedList();
    outgoing_message_stream = new LinkedList();
}

/*
* Draw function
*/
void draw()
{
    //Defaults
    smooth();
    
    background(black);
    surface.setTitle("CAN Bus"); // surface.setTitle for Processing 3
    
    render_graphics();
    
    // If the Serial was started
    if(!is_started)
    {
        // Start the Serial
        arduino = new Serial(this, port_selection, baud_rate);
        // Since this is a one time setup, we state that we now have set up the connection.
        is_started = true;
    }
    
    // Check to see if there are messages on the bus 
    serial_event(arduino);
    
    // ^ case is to ignore echo when the PC sends a message
    // # is a blank default until messages start coming in
    if (!in_string.equals("#\n") && !(in_string.charAt(0) == '^'))
    {
        // CAN status confirmation
        if (in_string.equals("READY\n"))
        {
            bus_status = true;
        }
        else if (in_string.equals("ERROR\n"))
        {
            bus_status = false;
        }
        // Sending message from PC status
        else if (in_string.equals("MSG SENT\n"))
        {
            msg_status = true;
        }
        else if (in_string.equals("MSG ERR\n"))
        {
            msg_status = false;
        }
        else
        {
            String[] frame = parse_data(in_string);
            
            // Check for matching or default filter
            if (filter.equals(frame[0]) || filter.equals("00"))
            {
                // Stream size check
                if (bus_stream.size() < 14)
                {
                    bus_stream.add("ID: " + frame[0] + "        DATA: " + frame[1]);
                }
                else
                {
                    bus_stream.remove();
                    bus_stream.add("ID: " + frame[0] + "        DATA: " + frame[1]);
                }
                
                // Write the data in a log file
                log.println("ID: " + frame[0] + "        DATA: " + frame[1]);
            }
            
            /********************** ADCS *********************/
            if (mailed_to(frame[0], adcs.mailbox_ids))
            {
            }
            /********************** CDH **********************/
            else if (mailed_to(frame[0], cdh.mailbox_ids))
            {
                if (!cdh.temp_avail)
                {
                    cdh.temp_avail = true;
                }
                
                float data = (float) Long.parseLong(frame[1], 16);
                
                cdh.temp = convert_to_temp(data - SENSOR_OFFSET);
                //println(data - SENSOR_OFFSET);
            }
            /********************** COMS *********************/
            else if (mailed_to(frame[0], coms.mailbox_ids))
            {
            }
            /********************** EPS **********************/
            else if (mailed_to(frame[0], eps.mailbox_ids))
            {
            }
            /********************** PAYL *********************/
            else if (mailed_to(frame[0], payl.mailbox_ids))
            {
            }
        }
    }
    
    // Reset the input string
    in_string = "#\n";
}

/*
* Checks to see if a message belongs to a particular subsystem.
* String id - Incoming message id
* String[] mailbox_ids - Subsystem mailbox ids
* Returns true if the message is addressed to the subsystem
*/
boolean mailed_to (String id, String[] mailbox_ids)
{
    
    for (int i = 0; i < mailbox_ids.length; i++)
    {
        // Partial or incomplete messages may throw an exception
        try
        {
            if (Integer.toString(unhex(id)).equals(mailbox_ids[i]))
            {
                return true;
            }
        }
        // Ignore the data 
        catch (NumberFormatException e)
        {
            return false;
        }
    }
    return false;
}

float convert_to_temp(float temp)
{
    float r_ratio, log_result = 0.0, result = 0.0;
    
    int i;
    
    r_ratio = temp / 1023;  // Convert ADC value to the ratio (of resistances).
    
    r_ratio = 1 / (r_ratio);  // Take the inverse.
    
    r_ratio = 1 - r_ratio;    // Substract this from one in order to approximate logarithm.
    
    for (i = 1; i < 5; i++)    // Natural Logarithm approximation.
    {
        if(i > 1)
        {
            r_ratio = r_ratio * r_ratio;
        }
        
        r_ratio = r_ratio / i;
        
        log_result += r_ratio;
    }
    
    result = (1 / 293.15) + (log_result / 3950);
    
    result = 1 / result;
    
    result = result - 273.15;    // Degrees Celsius.
    
    return result;
}

/**
* Checks to see if a message is available on a serial port.
* Serial arduino - The serial port to read from
*/
void serial_event(Serial arduino)
{
    if (arduino != null)
    {
        String temporary = arduino.readStringUntil('\n');
        if(temporary != null)
        {
            in_string = temporary;
        }
    }
}

/**
* Parses the data sent by the Arduino from the bus into the id and message.
* String str - String read from serial
* Returns a String array with two elements, the first being the ID & and the second is the message.
*/
String[] parse_data(String str)
{
    
    String[] raw = split(str.substring(1, str.length() - 3), "/");
    String[] values = new String[2];
    String message = "";
    
    values[0] = raw[0];
    
    // Reverse the order of the bytes
    for(int i = raw.length - 5; i >= 1; i--)
    {
        message += raw[i];
    }
    
    values[1] = message;
    
    return values;
}

/**
* Displays all the data for each satellite subsystem.
* !Currently only displays subsystem temperatures!
*/
void display_values(int rowY, Subsystem s)
{
    if (s.temp_avail)
    {
        fill(green);
        text(s.temp, column_centers[0], rowY);
    }
    else
    {
        fill(red);
        text("NA",  column_centers[0], rowY);
    }
    
    if (s.volt_avail)
    {
        text(s.volt, column_centers[1], rowY);
    }
    else
    {
        fill(red);
        text("NA", column_centers[1], rowY);
    }
    
    if (s.curr_avail)
    {
        fill(green);
        text(s.curr, column_centers[2], rowY);
    }
    else
    {
        fill(red);
        text("NA",  column_centers[2], rowY);
    }
    
    if (s.batt_avail)
    {
        fill(green);
        text(s.batt, column_centers[3], rowY);
    }
    else
    {
        fill(red);
        text("NA",  column_centers[3], rowY);
    }
    
    if (s.pres_avail)
    {
        fill(green);
        text(s.pres, column_centers[4], rowY);
    }
    else
    {
        fill(red);
        text("NA",  column_centers[4], rowY);
    }
    
    if (s.humid_avail)
    {
        fill(green);
        text(s.humid, column_centers[5], rowY);
    }
    else
    {
        fill(red);
        text("NA",  column_centers[5], rowY);
    }
    
    resetFormat();
}

/**
* Renders all graphics in the GUI.
*/
void render_graphics()
{
    //Header Definitions
    fill(blue);
    rect(0, 0, displayWidth, HEADER_HEIGHT);
    
    //Rendering Header
    textFont(title, 50);
    fill(white);
    text("HERON MK1 CAN Bus", 175, 75);
    image(crest, 10, 20);
    resetFormat();
    
    //Rendering CAN Status Inicator
    fill(white);
    text("CAN Status:", can_status_pos[0], can_status_pos[1]);
    text("MSG Status:", msg_status_pos[0], msg_status_pos[1]);
    
    // Bus status
    if(bus_status)
    {
        fill(green);
        can_status_message = "OK";
    }
    else
    {
        fill(red);
        textFont(bold, 16);
        can_status_message = "ERROR";
    }
    
    text(can_status_message, can_status_pos[0] + 95, can_status_pos[1]);
    
    // Message send status
    if (msg_status)
    {
        fill(green);
        msg_status_message = "SENT";
    }
    else
    {
        fill(grey);
        msg_status_message = "NA/ERR";
    }
    
    text(msg_status_message, msg_status_pos[0] + 95, msg_status_pos[1]);
    
    resetFormat();
    
    // Send message button
    if (mouseX > displayWidth - 170 && mouseX < displayWidth - 50 && mouseY > HEADER_HEIGHT - 50 && mouseY < HEADER_HEIGHT - 10)
    {
        fill(white);
    }
    else
    {
        fill(grey);
    }
    
    rect(displayWidth - 170, HEADER_HEIGHT - 50, 120, 40, 8);
    fill(black);
    text("SEND MSG", displayWidth - 155, HEADER_HEIGHT - 25);
        
    // Subsystems and columns
    resetFormat();
    text("SUBSYSTEMS", LEFT_JUSTIFY, HEADER_HEIGHT + 30);
    
    //Dynamically Adjusts the widths of columns
    for(int i = 0; i < fields.length; i++)
    {
        text(fields[i], INITIAL_SPACING + (i * (displayWidth - INITIAL_SPACING) / fields.length), HEADER_HEIGHT + 30);
        rect(INITIAL_SPACING - 10 + (i * (displayWidth - INITIAL_SPACING) / fields.length), HEADER_HEIGHT, 4, 250);
        column_centers[i] = INITIAL_SPACING - 25 + (i * (displayWidth - INITIAL_SPACING) / fields.length) + ((displayWidth - INITIAL_SPACING) / fields.length)/2 ;        
    }
    
    rect(0, 370, displayWidth, 4);
    fill(blue);
    rect(0, 374, displayWidth, 45);
    //Underlines the column headers
    fill(white);
    rect(0, HEADER_HEIGHT + UNDERLINE_HEIGHT, displayWidth, 6);
    resetFormat();
    
    //Drawing the row labels
    for(int i = 0; i < rows.length; i++)
    {
        //Have to figure out how to dynamically describe the 20
        text(rows[i], LEFT_JUSTIFY, HEADER_HEIGHT + UNDERLINE_HEIGHT + 25 + (i*40));   //((displayHeight - HEADER_HEIGHT - UNDERLINE_HEIGHT - FOOTER_HEIGHT) / rows.length)));
        
        switch(i)
        {
            case 0:
            display_values(HEADER_HEIGHT + UNDERLINE_HEIGHT + 25 + (i*40), adcs);
            break;
            case 1:
            display_values(HEADER_HEIGHT + UNDERLINE_HEIGHT + 25 + (i*40), cdh);
            break;
            case 2:
            display_values(HEADER_HEIGHT + UNDERLINE_HEIGHT + 25 + (i*40), coms);
            break;
            case 3:
            display_values(HEADER_HEIGHT + UNDERLINE_HEIGHT + 25 + (i*40), eps);
            break;
            case 4:
            display_values(HEADER_HEIGHT + UNDERLINE_HEIGHT + 25 + (i*40), payl);
            break;
        }
        
    }
    
    text("DATA STREAMS", (displayWidth / 2) - 55, 400);
    rect(0, 419, displayWidth, 4);
    rect(displayWidth / 4, 419, 4, displayHeight - 419);
    rect(displayWidth / 2, 419, 4, displayHeight - 419);
    
    // Filter button
    if (mouseX > displayWidth - 170 && mouseX < displayWidth - 50 && mouseY > 380 && mouseY < 410)
    {
        fill(white);
    }
    else
    {
        fill(grey);
    }
    
    rect(displayWidth - 170,  380, 120, 30, 8);
    fill(black);
    text("FILTER", displayWidth - 135, 400);
    
    resetFormat();
    text("BUS", displayWidth / 8, 445);
    text("SENT MESSAGES", displayWidth/2 - (displayWidth / 8) - 60, 445);
    rect(0, 455, displayWidth, 4);
    
    fill(yellow);
    
    display_stream(bus_stream, LEFT_JUSTIFY);
    display_stream(outgoing_message_stream, (displayWidth / 4) + LEFT_JUSTIFY);
}

void mouseClicked()
{
    if (mouseX > displayWidth - 170 && mouseX < displayWidth - 50 && mouseY > HEADER_HEIGHT - 50 && mouseY < HEADER_HEIGHT - 10)
    {
        String out_id = JOptionPane.showInputDialog("Enter the mailbox ID: ");
        String out_data = JOptionPane.showInputDialog("Enter an 8-byte hexadecimal message (format: FFFFFFFFFFFFFFFF): ");
        
        // Hat indicates message coming from PC unlike $ for messages being read from bus
        // Nothing is sent by the arduino until it reads a message started by ^
        String message = "";
        
        if (out_id != null && out_data != null)
        {
            message = "^" + out_id + out_data + "\n";
        }
        
        if (outgoing_message_stream.size() < 14)
        {
            outgoing_message_stream.add("ID: " + out_id + "        DATA: " + out_data);
        }
        else
        {
            outgoing_message_stream.remove();
            outgoing_message_stream.add("ID: " +  out_id + "        DATA: " + out_data);
        }
        
        arduino.write(message);
    }
    else if (mouseX > displayWidth - 170 && mouseX < displayWidth - 50 && mouseY > 380 && mouseY < 410)
    {
        filter = JOptionPane.showInputDialog("Enter the ID you wish to filter by:");
    }
    
}

/**
* Display a stream of data in the GUI
* X location of the stream
*/
void display_stream(Queue q, int x_pos)
{
    int offset_multiplier = q.size();
    for(Object obj : q)
    {
        String frame = (String) obj;
        text(frame, x_pos, displayHeight - (offset_multiplier * 20));
        offset_multiplier--;
    }
}

/*
* Return text() to default parameters
* should be called after rendering any unique text elements
* to ensure the next text element is returned to defaults
*/
void resetFormat()
{
    fill(white);
    textFont(mono, 16);
}

class Subsystem
{
    String[] mailbox_ids;
    
    boolean temp_avail = false,
    volt_avail = false,
    curr_avail = false,
    humid_avail = false,
    batt_avail = false,
    pres_avail = false;
    
    float temp, volt, curr, humid, batt, pres;
    
    Subsystem (String[] mb_ids)
    {
        mailbox_ids = mb_ids;
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