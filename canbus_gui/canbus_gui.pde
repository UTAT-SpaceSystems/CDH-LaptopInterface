// Imports
import javax.swing.JOptionPane;
import java.util.Queue;
import java.util.LinkedList;
import processing.serial.*;

// Set GUI fullscreen
boolean sketchFullScreen() { return true; }

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

String can_status_message;
Queue bus_stream;
boolean bus_status = false;

String msg_status_message;
Queue outgoing_message_stream;
boolean msg_status = false;

// Subsystems & properties
Subsystem adcs, cdh, coms, eps, payl;
final int[] ADCS_IDS = {};
final int[] CDH_IDS = {10, 11, 12, 13, 14, 15, 16, 17};
final int[] COMS_IDS = {};
final int[] EPS_IDS = {};
final int[] PAYL_IDS = {};

final float SENSOR_OFFSET = 1426063360; // 0x55000000 

// Serial Constants
int baud_rate;
String out_id, out_data;
String in_string;
Serial arduino;

/*
* Setup Fucntion
*
*/
void setup()
{
    size(displayWidth, displayHeight);
    
    //Loading assets
    mono = loadFont("FreeSans-48.vlw");
    bold = loadFont("FreeSansBold-48.vlw");
    title = loadFont("FreeSansBoldOblique-48.vlw");
    crest = loadImage("crest.png");
        
    column_centers = new int[fields.length];
    can_status_pos = new int[]{displayWidth - 170, (HEADER_HEIGHT / 2) - 30};
    msg_status_pos = new int[]{displayWidth - 170, (HEADER_HEIGHT / 2) - 10};
    
    adcs = new Subsystem(ADCS_IDS);
    cdh = new Subsystem(CDH_IDS);
    coms = new Subsystem(COMS_IDS);
    eps = new Subsystem(EPS_IDS);
    payl = new Subsystem(PAYL_IDS);
    
    baud_rate = 9600;
    in_string = "";
    
    if (Serial.list().length > 0)
    {
        arduino = new Serial(this, Serial.list()[0], baud_rate);
    }
    
    bus_stream = new LinkedList();
    outgoing_message_stream = new LinkedList();
}

void draw()
{
    //Defaults
    smooth();
    background(black);
    frame.setTitle("CAN Bus");
    render_graphics();
    serial_event(arduino);
    
    // ------------------- FOR OFFLINE DEMO ONLY -------------------------//
    if (bus_stream.size() < 14)
    {
        bus_stream.add("ID: 00        DATA: 00000000000000");
    }
    else
    {
        bus_stream.remove();  
        bus_stream.add("ID: 01        DATA: 00000000000000");
    }
    // -------------------------------------------------------------------//
    
    if (!in_string.equals("#\n") && !in_string.equals("") && !(in_string.charAt(0) == '^'))
    {
        
        if (in_string.equals("READY\n"))
        {
            bus_status = true;
        }
        else if (in_string.equals("ERROR\n"))
        {
            bus_status = false;
        }
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
            int[] frame = parse_data(in_string);
            if (bus_stream.size() < 14)
            {
                 bus_stream.add("ID: " + frame[0] + "        DATA: " + frame[1]);
            }
             else
            {
                 bus_stream.remove();  
                 bus_stream.add("ID: " + frame[0] + "        DATA: " + frame[1]);
            }
            //String hex = bytes_to_word_little_endian(in_string);
            //Long l = Long.parseLong(hex, 16);
            //float f = Float.intBitsToFloat(l.intValue());
            //float temp = convert_to_temp(f);
            //println(f);
            
            /********************** ADCS *********************
            /*if (mailed_to(frame[0], adcs.mailbox_ids))
            {
            }
            /********************** CDH **********************
            else if (mailed_to(frame[0], cdh.mailbox_ids))
            {
                if (!cdh.temp_avail)
                {
                    cdh.temp_avail = true;
                }
                
                float data = (float) Long.parseLong(frame[1], 16);
                
                cdh.temp = convert_to_temp(data - SENSOR_OFFSET);
            }
            /********************** COMS *********************
            else if (mailed_to(frame[0], coms.mailbox_ids))
            {
            }
            /********************** EPS **********************
            else if (mailed_to(frame[0], eps.mailbox_ids))
            {
            }
            /********************** PAYL *********************
            else if (mailed_to(frame[0], payl.mailbox_ids))
            {
            }*/
        }
    }
}

boolean mailed_to (int id, int[] mailbox_ids)
{
    
    for (int i = 0; i < mailbox_ids.length; i++)
    {
        if (id == mailbox_ids[i])
        {
            return true;
        }
    }
    return false;
}

String bytes_to_word_little_endian(String data)
{
    String[] raw = split(data.substring(1, data.length() - 3), "/");
    String word = "";
    
    for (int i = 8; i > 0 ;  i--)
    {
       word += raw[i];
    }
    return word;
}

float convert_to_temp(float temp)
{
  float r_ratio, log_result = 0.0, result = 0.0;
  
  int i, flag = 0;
  
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

void serial_event(Serial arduino)
{
    if (arduino != null)
    {
        String temp = arduino.readStringUntil('\n');
        if(temp != null)
        {
            in_string = temp;
        }
    }
}

int[] parse_data(String str)
{
    String[] raw = split(str.substring(1, str.length() - 3), "/");
    int[] values = new int[raw.length];
    for(int i = 0; i < raw.length; i++ )
    {
        values[i] = unhex(raw[i]);
    }
    return values;
}

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
    //rect(
    text("DATA STREAMS", (displayWidth / 2) - 55, 400);
    rect(0, 419, displayWidth, 4);
    rect(displayWidth / 4, 419, 4, displayHeight - 419);
    rect(displayWidth / 2, 419, 4, displayHeight - 419);
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
        String message = "^" + out_id + out_data + "\n";
        
        if (outgoing_message_stream.size() < 14)
        {
           outgoing_message_stream.add("ID: " + out_id + "        DATA: " + out_data);
        }
        else
        {
             outgoing_message_stream.remove();  
             outgoing_message_stream.add("ID: " +  out_id + "        DATA: " + out_data);
        }
        
    //    arduino.write(message);
    }
}


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
    int[] mailbox_ids;
    
    boolean temp_avail = false,
            volt_avail = false,
            curr_avail = false,
            humid_avail = false,
            batt_avail = false,
            pres_avail = false;
            
    float temp, volt, curr, humid, batt, pres;
    
    Subsystem (int[] mb_ids)
    {
        mailbox_ids = mb_ids;
    }
    
}

