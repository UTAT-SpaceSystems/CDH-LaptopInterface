// Imports
import processing.serial.*;

// Set GUI fullscreen
boolean sketchFullScreen() { return true; }

// Assets
PImage crest;
PFont mono, bold, title;

// GUI Constants
color white = color(255, 255, 255);
color black = color(0, 0, 0);
color blue = color(0, 0, 47);
color red = color(255, 0, 0);
color green = color(58, 255, 41);
color grey = color(200, 200, 200);
String[] fields = {"TEMP [K]", "VOLTAGE [V]", "CURRENT [mA]", "BATTERY %", "PRES [KPa]", "HUMIDITY", "PARAM7", "PARAM8", "PARAM9"};
String[] rows = { "ADCS", "CDH", "COMS", "EPS", "PAYLOAD"};
boolean bus_status = false;

// Subsystem properties


// Serial Constants
int baudRate = 9600;
String inString = "";
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
    
    println(Serial.list());
    arduino = new Serial(this, Serial.list()[0], baudRate);
}

void draw()
{
    //Defaults
    smooth();
    background(white);
    frame.setTitle("CAN Bus");
    renderGraphics();
    
    serialEvent(arduino);
    
    if (!inString.equals("#\n") && !inString.equals(""))
    {
        
        if (inString.equals("READY\n"))
        {
            bus_status = true;
        }
        else if (inString.equals("ERROR\n"))
        {
            bus_status = false;
        }
        else
        {
            int[] frame = parseData(inString);
            println(frame);
        }
    }
    
}

void serialEvent(Serial arduino)
{
    String temp = arduino.readStringUntil('\n');
    if(temp != null)
    {
        inString = temp;
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


void renderGraphics()
{
    //Header Definitions
    fill(blue);
    int header_height = 120;
    rect(0, 0, displayWidth, header_height);
    
    /********************************************************************************************/
    //Rendering Header
    textFont(title, 50);
    fill(white);
    text("HERON MK1 CAN Bus", 175, 75);
    image(crest, 10, 20);
    resetFormat();
    
    //Rendering CAN Status Inicator
    fill(white);
    int[] CAN_offset = {displayWidth - 170, header_height / 2};
    text("CAN Status:", CAN_offset[0], CAN_offset[1]);
    String message;
    if(bus_status)
    {
        fill(green);
        message = "OK";
    }
    else
    {
        fill(red);
        textFont(bold, 16);
        message = "ERROR";
    }
    text(message, CAN_offset[0] + 95, CAN_offset[1]);
    resetFormat();
    /********************************************************************************************/
    
    int left_justify = 15;
    text("SUBSYSTEMS", left_justify, header_height + 30);
    int initial_spacing = 200;
    
    //Dynamically Adjusts the widths of columns
    for(int i = 0; i < fields.length; i++)
    {
        text(fields[i], initial_spacing + (i * (displayWidth - initial_spacing) / fields.length), header_height + 30);
        fill(grey);
        rect(initial_spacing - 10 + (i * (displayWidth - initial_spacing) / fields.length), header_height, 1, 250);
        resetFormat();
    }
    rect(0, 370, displayWidth, 1);
    int underline_height = 45;
    //Underlines the column headers
    fill(grey);
    rect(0, header_height + underline_height, displayWidth, 1);
    resetFormat();
    
    
    int footer_height = 130;
    
    //Drawing the row labels
    for(int i = 0; i < rows.length; i++)
    {
        //Have to figure out how to dynamically describe the 20
        text(rows[i], left_justify, header_height + underline_height + 25 + (i*40));   //((displayHeight - header_height - underline_height - footer_height) / rows.length)));
    }
    /*
    rect(0, displayHeight - footer_height, displayWidth, 1);
    text("LOG:", left_justify, displayHeight - footer_height - 12);
    rect(0, displayHeight - footer_height - 30, displayWidth, 1);
    */
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

