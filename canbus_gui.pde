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
String[] fields = {"TEMP (K)", "VOLTAGE (V)", "PARAM 3", "PARAM 4" };
String[] rows = { "ADCS", "CDH", "COMS", "EPS", "PAYLOAD" };
boolean bus_status = false;

/*
// Serial Constants
int baud_rate = 9600;
String inString;
Serial myPort;
*/

/*
int y_first = 200;
int y_offset = 25;

int x_subsys = 10;
int x_temp = 200;
int x_volt = 300;
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
  int initial_spacing = 225;
  for(int i = 0; i < fields.length; i++)
  {
    text(fields[i], initial_spacing + (i * 150), header_height + 30);
    fill(grey);
    rect(initial_spacing - 10 + (i * 150), header_height, 1, displayHeight - header_height - 130);
    resetFormat();
  }
  
  fill(grey);
  rect(0, header_height + 45, displayWidth, 1);
  resetFormat();
  
  for(int i = 0; i < rows.length; i++)
  {
    text(rows[i], left_justify, 100 + header_height + (i*50));
  }
  
  rect(0, displayHeight - 130, displayWidth, 1);
  text("LOG:", left_justify, displayHeight - 108);
  rect(0, displayHeight - 100, displayWidth, 1);
  
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
  if (in_string.substring(0, 3).equals("ID:"))
  {
    id_str = in_string.substring(3, in_string.length);
    id_int = Integer.parseInt(id_str);
    switch(id_int)
    {
      case 0:
        break;
      case 1:
        break
      case 2:
        break;
      case 3:
        break;
      case 4:
        break;
      default:
        break;
    }
  } 
  // Data
  else if (inString.substring(0, 3).equals("DA:"))
  {
    data_str = in_string.substring(3, in_string.length).trim();
    long data = Long.parseLong(data_str);
  }
}
*/