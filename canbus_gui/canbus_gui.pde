/*
* FILE NAME: canbus_gui
* PURPOSE: CAN bus analyzer for UTAT Space System's Heron CubeSat

* DEVELOPMENT HISTORY:
*   Date          Author              Description of Change
*   06/14/15      Omar Abdeldayem     Monitoring (send, receive & log) fully functional 
*                 Albert Xie
*
*   01/12/16      Steven Yin          Compatible with Processing 3.0.1, Added COM selector, Prevent overwriting log file
*
*   02/19/16      Steven Yin          Change file structure, and added plot_data
*
*   02/21/16      Steven Yin          Re-structured the program
*
*   02/25/16      Steven Yin          perfection of UI
*
*   03/21/16      Steven Yin          Updated housekeeping definitions
*
*   03/29/16      Steven Yin          perfection of UI(work in progress)
*/


void close()
{
    arduino.stop();
    log.flush();
    log.close();
}

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
    if(Serial.list().length == 0)
    {
       JOptionPane.showMessageDialog(null,"No COM deviece connectd, existing.","UTAT",JOptionPane.ERROR_MESSAGE);
       System.exit(0);
    }
    port_selection = (String) JOptionPane.showInputDialog(null,"Choose COM port:","UTAT",JOptionPane.QUESTION_MESSAGE,null,Serial.list(),Serial.list()[0]);
    if(port_selection == null)
    {
       System.exit(0);    
    }

    size(displayWidth, displayHeight);
    
    // Updating inteval in milliseconds
    if(mode == 0)
    {
        UPDATE_INTERVAL = 5000;
        T_MINUS = 300;
    }
    else
    {
        UPDATE_INTERVAL = 10000;
        T_MINUS = 600;
    }
  
    // Loading assets
    sourcepro = loadFont("SourceSansPro-Semibold-48.vlw");
    title = loadFont("FreeSansBoldOblique-48.vlw");
    crest = loadImage("crest.png");
    
    column_centers = new int[fields.length];
    
    // Delta x for the plot
    DELTA_X = (displayWidth - 400)/(T_MINUS/(UPDATE_INTERVAL/1000));
    
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
    arduino_stream = new LinkedList();
    outgoing_message_stream = new LinkedList();
    can_stream = new LinkedList();
    
    // Initialize sensors
    sensor_init();
    
    // Add sensorgroup to full_sensor_list
    full_sensor_list.add(temp);
    full_sensor_list.add(volt);
    full_sensor_list.add(curr);
    full_sensor_list.add(acce);
    full_sensor_list.add(pres);
    full_sensor_list.add(humi);
    
    // Set the boundaries NEED TO BE CHANGED
    for(int i = 0; i < fields.length; i++)
    {
        full_sensor_list.get(i).boundary_high = 65535;
        full_sensor_list.get(i).boundary_low = 0;
    }
}

/*
* Draw function
*/
void draw()
{
    //Defaults
    smooth();

    background(black);
    surface.setTitle("HERON Laptop Interface"); // surface.setTitle for Processing 3
    
    // Update plot data in the background
    update_plot_data();
    
    // Determines which mode to go into
    if(isPlot)
    {
        render_plot();
    }
    else
    {
        render_graphics();
    }
    
    // If the Serial was started
    if(!is_started)
    {
       // Start the Serial
       arduino = new Serial(this, port_selection, baud_rate);
       // Since this is a one time setup, we state that we now have set up the connection.
       is_started = true;
    }
    
    establishContact();
    
    request_sensor_update();
    
    // Check to see if there are messages on the bus 
    serial_event(arduino);
    
    // Ignore blank message and echo inputs
    if (!in_string.equals("#\n") && !(in_string.charAt(0) == '^') && !(in_string.charAt(0) == '~'))
    {
        //Status confirmation
        if (in_string.charAt(0) == '@')
        {
            if (in_string.equals("@ARDUINO_OK\n"))
            {
                arduino_status = 1;
            }
            else if (in_string.equals("@CAN_OK\n"))
            {
                can_status = 1;
            }
            else if (in_string.equals("@CAN_ERR\n"))
            {
                can_status = 2;
            }
            else if (in_string.equals("@MSG_OK\n"))
            {
                msg_status = 1;
            }
            else if (in_string.equals("@MSG_ERR\n"))
            {
                msg_status = 2;
            }
            else if (in_string.equals("@TRANS_OK\n"))
            {
                trans_status = 1;
            }
            else if (in_string.equals("@PACKET_OK\n"))
            {
                packet_status = 1;
            }
        }
        else if (in_string.charAt(0) == '*') // A message from Arduino
        {
            if (arduino_stream.size() < MESSAGE_NUM)
                {
                    time = new Date();
                    arduino_stream.add("TIME: " + time_f.format(time) + "        MESSAGE: " + in_string.substring(1,in_string.length()));
                }
                else
                {
                    arduino_stream.remove();
                    time = new Date();
                    arduino_stream.add("TIME: " + time_f.format(time) + "        MESSAGE: " + in_string.substring(1,in_string.length()));
                }
                
            // Write the data in a log file
            time = new Date();
            log.println("TIME: " + time_f.format(time) + "        MESSAGE: " + in_string.substring(1,in_string.length()));
        }
        else if (in_string.charAt(0) == '$')
        {
            String[] frame = parse_data(in_string);
            if(frame[1] != "")
            {
                // Check for matching or default filter
                if (filter.equals(frame[0]) || filter.equals("00"))
                {
                    // Stream size check
                    if (can_stream.size() < MESSAGE_NUM)
                    {
                        time = new Date();
                        can_stream.add("TIME: " + time_f.format(time) + "            MOB_ID: " + frame[0] + "            DATA: " + frame[1]);
                    }
                    else
                    {
                        can_stream.remove();
                        time = new Date();
                        can_stream.add("TIME: " + time_f.format(time) + "            MOB_ID: " + frame[0] + "            DATA: " + frame[1]);
                    }
                    
                    // Write the data in a log file
                    time = new Date();
                    log.println("TIME: " + time_f.format(time) + "            MOB_ID: " + frame[0] + "            CAN_DATA: " + frame[1]);
                
                    int sensor_id = Integer.parseInt(frame[1].substring(4,6), 16);
                    
                    switch(sensor_id)
                    {
                        // Example case
                        /*
                        case SENSOR_NAME:
                        // If no conversion on senssor data is needed otherwise convert data to integer
                            full_sensor_list.get(0).sensor_list.get(1).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(1).sensor_data_buff = Integer.parseInt(frame[1].substring(1,3), 16);
                            full_sensor_list.get(0).sensor_list.get(1).sensor_is_updated = true;
                        */
                        case PANELX_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(1).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case PANELX_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(2).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case PANELY_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(1).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(1).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(1).sensor_list.get(1).sensor_is_updated = true;
                            break;
                        }
                        case PANELY_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(1).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(1).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(2).sensor_list.get(1).sensor_is_updated = true;
                            break;
                        }
                        case BATTM_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(2).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(2).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(1).sensor_list.get(2).sensor_is_updated = true;
                            break;
                        }
                        case BATT_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(3).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(3).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(1).sensor_list.get(3).sensor_is_updated = true;
                            break;
                        }
                        case BATTIN_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(2).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(2).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(2).sensor_list.get(2).sensor_is_updated = true;
                            break;
                        }
                        case BATTOUT_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(3).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(3).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(2).sensor_list.get(3).sensor_is_updated = true;
                            break;
                        }
                        case BATT_TEMP:
                        {
                            full_sensor_list.get(0).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(0).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case EPS_TEMP:
                        {
                            full_sensor_list.get(0).sensor_list.get(1).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(1).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(0).sensor_list.get(1).sensor_is_updated = true;
                            break;
                        }
                        case COMS_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(4).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(4).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(1).sensor_list.get(4).sensor_is_updated = true;
                            break;
                        }
                        case COMS_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(4).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(4).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(2).sensor_list.get(4).sensor_is_updated = true;
                            break;
                        }
                        case PAY_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(5).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(5).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(1).sensor_list.get(5).sensor_is_updated = true;
                            break;
                        }
                        case PAY_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(5).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(5).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(2).sensor_list.get(5).sensor_is_updated = true;
                            break;
                        }
                        case OBC_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(6).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(6).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(1).sensor_list.get(6).sensor_is_updated = true;
                            break;
                        }
                        case OBC_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(6).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(6).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(2).sensor_list.get(6).sensor_is_updated = true;
                            break;
                        }
                        case SHUNT_DPOT:
                        break;
                        case COMS_TEMP:
                        {
                            full_sensor_list.get(0).sensor_list.get(2).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(2).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(0).sensor_list.get(2).sensor_is_updated = true;
                            break;
                        }
                        case OBC_TEMP:
                        {
                            full_sensor_list.get(0).sensor_list.get(3).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(3).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(0).sensor_list.get(3).sensor_is_updated = true;
                            break;
                        }
                        case PAY_TEMP0:
                        {
                            full_sensor_list.get(0).sensor_list.get(4).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(4).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(0).sensor_list.get(4).sensor_is_updated = true;
                            break;
                        }
                        case PAY_TEMP1:
                        {
                            full_sensor_list.get(0).sensor_list.get(5).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(5).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(0).sensor_list.get(5).sensor_is_updated = true;
                            break;
                        }
                        case PAY_TEMP2:
                        {
                            full_sensor_list.get(0).sensor_list.get(6).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(6).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(0).sensor_list.get(6).sensor_is_updated = true;
                            break;
                        }
                        case PAY_TEMP3:
                        {
                            full_sensor_list.get(0).sensor_list.get(7).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(7).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(0).sensor_list.get(7).sensor_is_updated = true;
                            break;
                        }
                        case PAY_TEMP4:
                        {
                            full_sensor_list.get(0).sensor_list.get(8).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(8).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(0).sensor_list.get(8).sensor_is_updated = true;
                            break;
                        }
                        case PAY_HUM:
                        {
                            full_sensor_list.get(5).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(5).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(5).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case PAY_PRESS:
                        {
                            full_sensor_list.get(4).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(4).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(4).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case PAY_ACCEL:
                        {
                            full_sensor_list.get(3).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(3).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(12,16), 16);
                            full_sensor_list.get(3).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                    }
                }
            }
        }
        else if(in_string.charAt(0) == '?')
        {
            String[] frame = parse_data_trans(in_string);
            if(frame[1] != "")
            {
                // Check for matching or default filter
                if (filter.equals(frame[0]) || filter.equals("00"))
                {
                    // Stream size check
                    if (can_stream.size() < MESSAGE_NUM)
                    {
                        time = new Date();
                        can_stream.add("TIME: " + time_f.format(time) +  "            DATA: " + frame[1]);
                    }
                    else
                    {
                        can_stream.remove();
                        time = new Date();
                        can_stream.add("TIME: " + time_f.format(time) +  "            DATA: " + frame[1]);
                    }
                    
                    // Write the data in a log file
                    time = new Date();
                    log.println("TIME: " + time_f.format(time) +  "            TRANS_DATA: " + frame[1]);
                
                    int sensor_id = Integer.parseInt(frame[1].substring(0,2), 16);
                    
                    switch(sensor_id)
                    {
                        // Example case
                        /*
                        case SENSOR_NAME:
                        // If no conversion on senssor data is needed otherwise convert data to integer
                            full_sensor_list.get(0).sensor_list.get(1).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(1).sensor_data_buff = Integer.parseInt(frame[1].substring(1,3), 16);
                            full_sensor_list.get(0).sensor_list.get(1).sensor_is_updated = true;
                        */
                        case PANELX_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(1).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case PANELX_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(2).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case PANELY_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(1).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(1).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(1).sensor_list.get(1).sensor_is_updated = true;
                            break;
                        }
                        case PANELY_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(1).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(1).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(2).sensor_list.get(1).sensor_is_updated = true;
                            break;
                        }
                        case BATTM_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(2).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(2).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(1).sensor_list.get(2).sensor_is_updated = true;
                            break;
                        }
                        case BATT_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(3).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(3).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(1).sensor_list.get(3).sensor_is_updated = true;
                            break;
                        }
                        case BATTIN_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(2).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(2).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(2).sensor_list.get(2).sensor_is_updated = true;
                            break;
                        }
                        case BATTOUT_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(3).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(3).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(2).sensor_list.get(3).sensor_is_updated = true;
                            break;
                        }
                        case BATT_TEMP:
                        {
                            full_sensor_list.get(0).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(0).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case EPS_TEMP:
                        {
                            full_sensor_list.get(0).sensor_list.get(1).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(1).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(0).sensor_list.get(1).sensor_is_updated = true;
                            break;
                        }
                        case COMS_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(4).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(4).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(1).sensor_list.get(4).sensor_is_updated = true;
                            break;
                        }
                        case COMS_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(4).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(4).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(2).sensor_list.get(4).sensor_is_updated = true;
                            break;
                        }
                        case PAY_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(5).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(5).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(1).sensor_list.get(5).sensor_is_updated = true;
                            break;
                        }
                        case PAY_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(5).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(5).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(2).sensor_list.get(5).sensor_is_updated = true;
                            break;
                        }
                        case OBC_V:
                        {
                            full_sensor_list.get(1).sensor_list.get(6).sensor_avail = true;
                            full_sensor_list.get(1).sensor_list.get(6).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(1).sensor_list.get(6).sensor_is_updated = true;
                            break;
                        }
                        case OBC_I:
                        {
                            full_sensor_list.get(2).sensor_list.get(6).sensor_avail = true;
                            full_sensor_list.get(2).sensor_list.get(6).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(2).sensor_list.get(6).sensor_is_updated = true;
                            break;
                        }
                        case COMS_TEMP - 1:
                        {
                            full_sensor_list.get(0).sensor_list.get(2).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(2).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(0).sensor_list.get(2).sensor_is_updated = true;
                            break;
                        }
                        case OBC_TEMP - 1:
                        {
                            full_sensor_list.get(0).sensor_list.get(3).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(3).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(0).sensor_list.get(3).sensor_is_updated = true;
                            break;
                        }
                        case PAY_TEMP0 - 1:
                        {
                            full_sensor_list.get(0).sensor_list.get(4).sensor_avail = true;
                            full_sensor_list.get(0).sensor_list.get(4).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(0).sensor_list.get(4).sensor_is_updated = true;
                            break;
                        }
                        case PAY_HUM - 5:
                        {
                            full_sensor_list.get(5).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(5).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(5).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case PAY_PRESS - 5:
                        {
                            full_sensor_list.get(4).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(4).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(4).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case PAY_ACCEL - 5:
                        {
                            full_sensor_list.get(3).sensor_list.get(0).sensor_avail = true;
                            full_sensor_list.get(3).sensor_list.get(0).sensor_data_buff = Integer.parseInt(frame[1].substring(2,6), 16);
                            full_sensor_list.get(3).sensor_list.get(0).sensor_is_updated = true;
                            break;
                        }
                        case ABS_TIME_D - 7:
                        {
                            // day = Integer.parseInt(frame[1].substring(2,6), 16);
                            break;
                        }
                        case ABS_TIME_H - 7:
                        {
                            // hour = Integer.parseInt(frame[1].substring(2,6), 16);
                            break;
                        }
                        case ABS_TIME_M - 7:
                        {
                            // minute = Integer.parseInt(frame[1].substring(2,6), 16);
                            break;
                        }
                    }
                }
            }
        }
    }
    
    // Reset the input string
    in_string = "#\n";
}

/**
* Checks to see if a message is available on a serial port.
* Serial arduino - The serial port to read from
*/
void serial_event(Serial arduino)
{
    if (arduino.available() > 0)
    {
        String temporary = arduino.readStringUntil('\n');
        if(temporary != null)
        {
            if((temporary.charAt(0) == '@') || (temporary.charAt(0) == '*') || (temporary.charAt(0) == '$') || (temporary.charAt(0) == '?'))
            {
                in_string = temporary;
            }
        }
    }
}

/**
* Parses the data sent by the Arduino from the can bus into the id and message.
* String str - String read from serial
* Returns a String array with two elements, the first being the ID & and the second is the message.
*/
String[] parse_data(String str)
{    
    String[] raw = split(str.substring(1, str.length()), "/");
    String[] values = new String[2];
    String message = "";
    values[0] = raw[0];

    for(int i = 1; i <= 8; i++)
    {
        message += raw[i];
    }
    values[1] = message;

    return values;
}

/**
* Parses the data sent by the Arduino from the transceriver into the id and data.
* String str - String read from serial
* Returns a String array with two elements, the first being the ID & and the second is the data.
*/
String[] parse_data_trans(String str)
{    
    String raw = str.substring(1, str.length());
    String[] values = new String[2];
    values[0] = "00";
    values[1] = raw;

    return values;
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
    text("HERON Laptop Interface", 175, 75);
    image(crest, 10, 20);
    resetFormat();
    
    //Rendering mode
    fill(white);
    textFont(title, 20);
    if(mode == 0)
        text("CAN_MODE",displayWidth - 165, (HEADER_HEIGHT / 2) - 30);
    else if(mode == 1)
        text("TRANS_MODE",displayWidth - 165, (HEADER_HEIGHT / 2) - 30);
    
    // Header seperation lines
    fill(white);
    rect(displayWidth / 2, HEADER_HEIGHT, 4, 250);
    rect(0, HEADER_HEIGHT + 125, displayWidth, 4);
    rect(0, HEADER_HEIGHT, displayWidth, 4);
    rect(0, 370, displayWidth, 4);
        
    //Rendering status
    textSize(20);
    text("Arduino Status:", 100, HEADER_HEIGHT + 50);
    if(mode == 0)
    {
        text("CAN Status:", 400, HEADER_HEIGHT + 50);
        text("MSG Status:", 700, HEADER_HEIGHT + 50);
    }
    else 
    {
        text("TRANS Status:", 400, HEADER_HEIGHT + 50);
        text("PACKET Status:", 700, HEADER_HEIGHT + 50);
    }

    // Arduino status
    switch(arduino_status)
    {
        case 0:
        fill(grey);
        arduino_status_message = "NOT CONNECTED";
        break;
        
        case 1:
        fill(green);
        arduino_status_message = "OK";
        break;
    }
    
    text(arduino_status_message, 100, HEADER_HEIGHT + 100);
    
    // CAN bus/TRANS status
    if(mode == 0)
    {
        switch(can_status)
        {
            case 0:
            fill(grey);
            can_status_message = "NA";
            break;
            
            case 1:
            fill(green);
            can_status_message = "OK";
            break;
            
            case 2:
            fill(red);
            can_status_message = "ERROR";
            break;
        }
        text(can_status_message, 400, HEADER_HEIGHT + 100);
    }
    else
    {
        switch(trans_status)
        {
            case 0:
            fill(grey);
            trans_status_message = "NA";
            break;
            
            case 1:
            fill(green);
            trans_status_message = "OK";
            break;
        }
        text(trans_status_message, 400, HEADER_HEIGHT + 100);
    }
    
    // Message send/PACKET status
    if(mode == 0)
    {
        switch(msg_status)
        {
            case 0:
            fill(grey);
            msg_status_message = "NA";
            break;
            
            case 1:
            fill(green);
            msg_status_message = "OK";
            break;
            
            case 2:
            fill(red);
            msg_status_message = "ERROR";
            break;
        }
        text(msg_status_message, 700, HEADER_HEIGHT + 100);
    }
    else
    {
        switch(packet_status)
        {
            case 0:
            fill(grey);
            packet_status_message = "NA";
            break;
            
            case 1:
            fill(green);
            packet_status_message = "OK";
            break;
            
            case 2:
            fill(red);
            packet_status_message = "ERROR";
            break;
        }
        text(packet_status_message, 700, HEADER_HEIGHT + 100);
    }
    
    //Rendering time
    fill(white);
    text("Computer Time:", 100, HEADER_HEIGHT + 175);
    time = new Date();
    text(time_f.format(time), 100, HEADER_HEIGHT + 225);
    
    fill(white);
    text("SAT Time:", 400, HEADER_HEIGHT + 175);
    if(mode == 0)
    {
        fill(grey);
        text("NA", 400, HEADER_HEIGHT + 225);
    }
    else 
    {
        if(!is_sat_time_avail)
        {
            fill(grey);
            text("NA", 400, HEADER_HEIGHT + 225);
        }
        else
        {
            // TODO
            fill(white);
            //text(sat_time, 400, HEADER_HEIGHT + 225);
        }
    }
    
    resetFormat();
    
    //Send message button
    if (mouseX > displayWidth - 170 && mouseX < displayWidth - 50 && mouseY > HEADER_HEIGHT + 50 && mouseY < HEADER_HEIGHT + 90)
    {
       fill(white);
    }
    else
    {
       fill(grey);
    }
    
    rect(displayWidth - 170, HEADER_HEIGHT + 50, 120, 40, 8);
    fill(black);
    text("SEND MSG", displayWidth - 155, HEADER_HEIGHT + 75);
    
    resetFormat();
    
    // PLOT_DATA button
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
    text("PLOT DATA", displayWidth - 155, HEADER_HEIGHT - 25);
    
    fill(blue);
    rect(0, 374, displayWidth, 45);
    resetFormat();
    
    text("DATA STREAMS", (displayWidth / 2) - 55, 400);
    rect(displayWidth / 4, 419, 4, displayHeight - 419);
    rect(displayWidth / 2, 419, 4, displayHeight - 419);
    rect(0, 419, displayWidth, 4);
    
    resetFormat();
    text("ARDUINO", displayWidth / 8 - 20, 445);
    if(mode == 0)
    {
        text("SENT MESSAGES", displayWidth/2 - (displayWidth / 8) - 60, 445);
        text("CAN BUS", 3*displayWidth/4 - 60, 445);
    }
    else
    {
        text("SENT COMMAND", displayWidth/2 - (displayWidth / 8) - 60, 445);
        text("TRANSCEIVER", 3*displayWidth/4 - 60, 445);
    }
    rect(0, 455, displayWidth, 4);
    
    fill(yellow);
    
    display_stream(arduino_stream, LEFT_JUSTIFY);
    display_stream(outgoing_message_stream, (displayWidth / 4) + LEFT_JUSTIFY);
    display_stream(can_stream, (displayWidth / 2) + LEFT_JUSTIFY);
}

void mouseClicked()
{
    if(!isPlot)
    {
        if (mouseX > displayWidth - 170 && mouseX < displayWidth - 50 && mouseY > HEADER_HEIGHT + 50 && mouseY < HEADER_HEIGHT + 90)
        {
            if(mode == 0)
            {
                String out_id = JOptionPane.showInputDialog("Enter the mailbox ID (Integar): ");
                String out_data = JOptionPane.showInputDialog("Enter an 8-byte hexadecimal message (format: FFFFFFFFFFFFFFFF): ");

                // Hat indicates message coming from PC unlike $ for messages being read from bus
                // Nothing is sent by the arduino until it reads a message started by ^
                String message = "";

                if (out_id != null && out_data != null)
                {
                    message = "^" + out_id  + out_data + "\n";
                }

                if (outgoing_message_stream.size() < MESSAGE_NUM)
                {
                    outgoing_message_stream.add("MOB_ID: " + out_id + "        DATA: " + out_data);
                }
                else
                {
                    outgoing_message_stream.remove();
                    outgoing_message_stream.add("MOB_ID: " +  out_id + "        DATA: " + out_data);
                }
                arduino.write(message);
            }
            else 
            {
                // TODO    
            }
        }
        if (mouseX > displayWidth - 170 && mouseX < displayWidth - 50 && mouseY > HEADER_HEIGHT - 50 && mouseY < HEADER_HEIGHT - 10)
        {
             isPlot = true;
        }
    }
    else
    {
        // Back button
        if (mouseX > displayWidth - 170 && mouseX < displayWidth - 50 && mouseY > HEADER_HEIGHT - 50 && mouseY < HEADER_HEIGHT - 10)
        {
            isPlot = false;
        }
        // Tempreturn button
        else if (mouseX > 20 && mouseX < 140 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
        {
            my_plot=SensorType.tempreture;
        }
        // Voltage button
        else if (mouseX > 160 && mouseX < 280 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
        {
            my_plot=SensorType.voltage;
        }
        // Current button
        else if (mouseX > 300 && mouseX < 420 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
        {
            my_plot=SensorType.current;
        }
        // Acceleration button
        else if (mouseX > 440 && mouseX < 560 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
        {
            my_plot=SensorType.acceleration;
        }
        // Pressure button
        else if (mouseX > 580 && mouseX < 700 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
        {
            my_plot=SensorType.pressure;
        }
        // Humidity button
        else if (mouseX > 720 && mouseX < 840 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
        {
            my_plot=SensorType.humidity;
        }
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
    stroke(black);
    textFont(sourcepro, 16);
}

/*
* Put all the sensors into sensorgroups
*/
void sensor_init()
{
    if (mode == 0)
    {
        // Tempreture sensors
        temp.add_sensor(new Sensor("BATT_TEMP", 0x09, plot_red));
        temp.add_sensor(new Sensor("EPS_TEMP", 0x0A, plot_green));
        temp.add_sensor(new Sensor("COMS_TEMP", 0x12, plot_blue));
        temp.add_sensor(new Sensor("OBC_TEMP", 0x13, plot_yellow));
        temp.add_sensor(new Sensor("PAY_TEMP0", 0x14, plot_pink));
        temp.add_sensor(new Sensor("PAY_TEMP1", 0x15, plot_cyan));
        temp.add_sensor(new Sensor("PAY_TEMP2", 0x16, plot_orange));
        temp.add_sensor(new Sensor("PAY_TEMP3", 0x17, plot_purple));
        temp.add_sensor(new Sensor("PAY_TEMP4", 0x18, plot_brown));

        // Voltage sensors
        volt.add_sensor(new Sensor("PANELX_V", 0x01, plot_red));
        volt.add_sensor(new Sensor("PANELY_V", 0x03, plot_green));
        volt.add_sensor(new Sensor("BATTM_V", 0x05, plot_blue));
        volt.add_sensor(new Sensor("BATT_V", 0x06, plot_yellow));
        volt.add_sensor(new Sensor("COMS_V", 0x0B, plot_pink));
        volt.add_sensor(new Sensor("PAY_V", 0x0D, plot_cyan));
        volt.add_sensor(new Sensor("OBC_V", 0x0F, plot_orange));

        // Current sensors
        curr.add_sensor(new Sensor("PANELX_I", 0x02, plot_red));
        curr.add_sensor(new Sensor("PANELY_I", 0x04, plot_green));
        curr.add_sensor(new Sensor("BATTIN_I", 0x07, plot_blue));
        curr.add_sensor(new Sensor("BATTOUT_I", 0x08, plot_yellow));
        curr.add_sensor(new Sensor("COMS_I", 0x0C, plot_pink));
        curr.add_sensor(new Sensor("PAY_I", 0x0E, plot_cyan));
        curr.add_sensor(new Sensor("OBC_I", 0x10, plot_orange));
        
        // Acceleration sensors
        acce.add_sensor(new Sensor("PAY_ACCEL", 0x1B, plot_red));
        
        // Pressure sensors
        pres.add_sensor(new Sensor("PAY_PRESS", 0x1A, plot_red));
        
        // Humidity sensors
        humi.add_sensor(new Sensor("PAY_HUM", 0x19, plot_red));
    }
    else
    {
        // Tempreture sensors
        temp.add_sensor(new Sensor("BATT_TEMP", 0x09, plot_red));
        temp.add_sensor(new Sensor("EPS_TEMP", 0x0A, plot_green));
        temp.add_sensor(new Sensor("COMS_TEMP", 0x12, plot_blue));
        temp.add_sensor(new Sensor("OBC_TEMP", 0x13, plot_yellow));
        temp.add_sensor(new Sensor("PAY_TEMP0", 0x14, plot_pink));

        // Voltage sensors
        volt.add_sensor(new Sensor("PANELX_V", 0x01, plot_red));
        volt.add_sensor(new Sensor("PANELY_V", 0x03, plot_green));
        volt.add_sensor(new Sensor("BATTM_V", 0x05, plot_blue));
        volt.add_sensor(new Sensor("BATT_V", 0x06, plot_yellow));
        volt.add_sensor(new Sensor("COMS_V", 0x0B, plot_pink));
        volt.add_sensor(new Sensor("PAY_V", 0x0D, plot_cyan));
        volt.add_sensor(new Sensor("OBC_V", 0x0F, plot_orange));

        // Current sensors
        curr.add_sensor(new Sensor("PANELX_I", 0x02, plot_red));
        curr.add_sensor(new Sensor("PANELY_I", 0x04, plot_green));
        curr.add_sensor(new Sensor("BATTIN_I", 0x07, plot_blue));
        curr.add_sensor(new Sensor("BATTOUT_I", 0x08, plot_yellow));
        curr.add_sensor(new Sensor("COMS_I", 0x0C, plot_pink));
        curr.add_sensor(new Sensor("PAY_I", 0x0E, plot_cyan));
        curr.add_sensor(new Sensor("OBC_I", 0x10, plot_orange));
        
        // Acceleration sensors
        acce.add_sensor(new Sensor("PAY_ACCEL", 0x1B, plot_red));
        
        // Pressure sensors
        pres.add_sensor(new Sensor("PAY_PRESS", 0x1A, plot_red));
        
        // Humidity sensors
        humi.add_sensor(new Sensor("PAY_HUM", 0x19, plot_red));
    }
}

/*
* Handshake with arduino clear input buffer and get ready for input
*/
void establishContact()
{
  if(firstContact == false)
  {
    delay(200);
    while(arduino.available() > 0)
    {
        String temp =  arduino.readString();
        arduino.clear(); // clear the serial port buffer
        firstContact = true;
        arduino.write(mode + "\n");
        return;
    }
  }
}

/*
 * Request for sensor update based on pre-set time
 */
 void request_sensor_update()
 {
     long dt = System.currentTimeMillis() - last_date;
     if(dt >= UPDATE_INTERVAL)
     {
         String str;
         if(mode == 0)
         {
             str = "~00";
         }
         else 
         {
             str = "~01";
         }
         arduino.write(str); // Reqest all sensor data
         last_date = System.currentTimeMillis();
     }
 }