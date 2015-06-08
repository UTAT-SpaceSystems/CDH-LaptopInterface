// Imports
import javax.swing.JOptionPane;

import processing.serial.*;

// Set GUI fullscreen
boolean sketchFullScreen() { return true; }

// Assets
PImage crest;
PFont mono, bold, title;

// GUI Constants
int header_height = 120;
int footer_height = 130;
int underline_height = 45;
int left_justify = 15;
int initial_spacing = 200;

color white = color(255, 255, 255);
color black = color(0, 0, 0);
color blue = color(0, 0, 47);
color red = color(255, 0, 0);
color green = color(58, 255, 41);
color grey = color(200, 200, 200);

String[] fields = {"TEMP [K]", "VOLTAGE [V]", "CURRENT [mA]", "BATTERY %", "PRES [KPa]", "HUMIDITY %"};
String[] rows = { "ADCS", "CDH", "COMS", "EPS", "PAYL"};

int[] column_centers = new int[fields.length];
int[] can_status_pos = new int[2];
int[] msg_status_pos = new int[2];

String can_status_message;
boolean bus_status = false;

String msg_status_message;
boolean msg_status = false;

// Subsystem properties
Subsystem adcs, cdh, coms, eps, payl;
int[] adcs_ids, cdh_ids, coms_ids, eps_ids, payl_ids;

// Serial Constants
int baudRate = 9600;
String out_id, out_data;
String in_string = "";
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
    
    // Processing won't cooperate unless the int arrays are declared this way
    adcs_ids = new int[]{};
    cdh_ids = new int[]{10, 11, 12, 13, 14, 15, 16, 17};
    coms_ids = new int[]{};
    eps_ids = new int[]{};
    payl_ids = new int[]{};
    
    can_status_pos[0] = displayWidth - 170;
    can_status_pos[1] = (header_height / 2) - 40;
    
    msg_status_pos[0] = displayWidth - 170;
    msg_status_pos[1] = (header_height / 2) - 20;
    
    adcs = new Subsystem(adcs_ids);
    cdh = new Subsystem(cdh_ids);
    coms = new Subsystem(coms_ids);
    eps = new Subsystem(eps_ids);
    payl = new Subsystem(payl_ids);
    
    println(Serial.list());
    if (Serial.list().length > 0)
    {
        arduino = new Serial(this, Serial.list()[0], baudRate);
    }
}

void draw()
{
    //Defaults
    smooth();
    background(white);
    frame.setTitle("CAN Bus");
    renderGraphics();
    
    serialEvent(arduino);
    
    if (!in_string.equals("#\n") && !in_string.equals(""))
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
            int[] frame = parseData(in_string);
            
            /********************** ADCS *********************/
            if (mailedTo(frame[0], adcs.mailbox_ids))
            {
            }
            /********************** CDH **********************/
            else if (mailedTo(frame[0], cdh.mailbox_ids))
            {
                if (!cdh.temp_avail)
                {
                    cdh.temp_avail = true;
                }
                
                cdh.temp = frame[1];
            }
            /********************** COMS *********************/
            else if (mailedTo(frame[0], coms.mailbox_ids))
            {
            }
            /********************** EPS **********************/
            else if (mailedTo(frame[0], eps.mailbox_ids))
            {
            }
            /********************** PAYL *********************/
            else if (mailedTo(frame[0], payl.mailbox_ids))
            {
            }
        }
    }
}

boolean mailedTo (int id, int[] mailbox_ids)
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

void serialEvent(Serial arduino)
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

int[] parseData(String str)
{
    String[] raw = split(str.substring(1, str.length() - 3), "/");
    int[] values = new int[raw.length];
    for(int i = 0; i < raw.length; i++ )
    {
        values[i] = unhex(raw[i]);
    }
    return values;
}

void displayValues(int rowY, Subsystem s)
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

void renderGraphics()
{
    //Header Definitions
    fill(blue);
    rect(0, 0, displayWidth, header_height);
    
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
    if (mouseX > displayWidth - 170 && mouseX < displayWidth - 50 && mouseY > header_height - 50 && mouseY < header_height - 10)
    {
        fill(white);
    }
    else
    {
        fill(grey);
    }
    
    rect(displayWidth - 170, header_height - 50, 120, 40, 8);
    fill(black);
    text("SEND MSG", displayWidth - 155, header_height - 25);
    
    // Subsystems and columns
    
    text("SUBSYSTEMS", left_justify, header_height + 30);
    
    //Dynamically Adjusts the widths of columns
    for(int i = 0; i < fields.length; i++)
    {
        text(fields[i], initial_spacing + (i * (displayWidth - initial_spacing) / fields.length), header_height + 30);
        fill(grey);
        rect(initial_spacing - 10 + (i * (displayWidth - initial_spacing) / fields.length), header_height, 1, 250);
        column_centers[i] = initial_spacing - 25 + (i * (displayWidth - initial_spacing) / fields.length) + ((displayWidth - initial_spacing) / fields.length)/2 ;
        resetFormat();
    }
    rect(0, 370, displayWidth, 1);
    //Underlines the column headers
    fill(grey);
    rect(0, header_height + underline_height, displayWidth, 1);
    resetFormat();
    
    //Drawing the row labels
    for(int i = 0; i < rows.length; i++)
    {
        //Have to figure out how to dynamically describe the 20
        text(rows[i], left_justify, header_height + underline_height + 25 + (i*40));   //((displayHeight - header_height - underline_height - footer_height) / rows.length)));
        
        switch(i)
        {
            case 0:
            displayValues(header_height + underline_height + 25 + (i*40), adcs);
            break;
            case 1:
            displayValues(header_height + underline_height + 25 + (i*40), cdh);
            break;
            case 2:
            displayValues(header_height + underline_height + 25 + (i*40), coms);
            break;
            case 3:
            displayValues(header_height + underline_height + 25 + (i*40), eps);
            break;
            case 4:
            displayValues(header_height + underline_height + 25 + (i*40), payl);
            break;
        }
        
    }
}

void mouseClicked()
{
    if (mouseX > displayWidth - 170 && mouseX < displayWidth - 50 && mouseY > header_height - 50 && mouseY < header_height - 10)
    {
        String out_id = JOptionPane.showInputDialog("Enter the mailbox ID: ");
        String out_data = JOptionPane.showInputDialog("Enter the message (Hex format: 00/00/00/00/00/00/00/00): ");
        String message = "^" + out_id + "/" + out_data + "/\n";
        
        arduino.write(message);
    }
}

/*
* Return text() to default parameters
* should be called after rendering any unique text elements
* to ensure the next text element is returned to defaults
*/
void resetFormat()
{
    fill(black);
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

