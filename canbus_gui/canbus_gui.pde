//Imports
//import processing.serial.*;

// Aesthetics 
boolean sketchFullScreen() { return true; }

// Assets
PImage crest;
PFont mono, bold, title;

// Constants
color white = color(255, 255, 255);
color black = color(0, 0, 0);
color blue = color(0, 0, 47);
color red = color(255, 0, 0);
color green = color(58, 255, 41);
color grey = color(200, 200, 200);
String[] fields = {"TEMP (K)", "VOLTAGE (V)", "PARAM 3", "PARAM 4", "PARAM5", "PARAM6", "PARAM7", "PARAM8", "PARAM9"};
String[] rows = { "ADCS", "CDH", "COMS", "EPS", "PAYLOAD"};
boolean bus_status = false;

/*
// Serial Constants
int baudRate = 9600;
String inString;
Serial myPort;
*/

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
  
  /*
  println(Serial.list());
  // Check the listed serial ports in your machine
  // and use the correct index number in Serial.list()[].
  myPort = new Serial(this, Serial.list()[0], baud_rate);
  */
}

void draw()
{
  //Defaults
  smooth(8);
  background(white);
  frame.setTitle("CAN Readings");
  
  //Header Definitions
  fill(blue);
  int header_height = 120;
  rect(0, 0, displayWidth, header_height);
  
  /********************************************************************************************/
  //Rendering Header
  textFont(title, 50);
  fill(white);
  text("title here", 175, 75);
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
    rect(initial_spacing - 10 + (i * (displayWidth - initial_spacing) / fields.length), header_height, 1, displayHeight - header_height - 130);
    resetFormat();
  }
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
    text(rows[i], left_justify, header_height + underline_height + 20 + (i * ((displayHeight - header_height - underline_height - footer_height) / rows.length)));
  }
  
  rect(0, displayHeight - footer_height, displayWidth, 1);
  text("LOG:", left_justify, displayHeight - footer_height - 12);
  rect(0, displayHeight - footer_height - 30, displayWidth, 1);
  
  /*
  textFont(title, 45);
  fill(black);
  text(inString, displayHeight/2, displayWidth/2);
  */
}

/*
void serialEvent (Serial myPort)
{
  in_string = myPort.readStringUntil('\n');
  text(in_string, 10, displayHeight - 180);
  // ID String
  if (in_string.substring(0, 4).equals("ID: "))
  {
    id_str = in_string.substring(3, in_string.length);
    id_int = Integer.parseInt(id_str);
    switch(id_int)
    {
      // CAN1_MB0
      case 10:
        break;
      // CAN1_MB1
      case 11:
        break;
      // CAN1_MB2
      case 12:
        break;
      // CAN1_MB3
      case 13:
        break;
      // CAN1_MB4
      case 14:
        break;
      // CAN1_MB5
      case 15:
        break;  
      // CAN1_MB6
      case 16:
        break;
      // CAN1_MB7
      case 17:
        break;
      default:
        // Data not adressed to any of the CAN1 (and later CAN0) mailboxes 
        // will default output to the log
        break;
    }
  }
  
  // Data
  else if (inString.substring(0, 6).equals("DATA: "))
  {
    data_str = in_string.substring(6, in_string.length).trim();
    long data = Long.parseLong(data_str);
   
  }
}
*/
