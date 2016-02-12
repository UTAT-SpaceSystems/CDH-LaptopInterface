/*
* FILE NAME: plot_data
* PURPOSE: Components that helps to plot data coming from CAN bus

* DEVELOPMENT HISTORY:
*   Date          Author              Description of Change
*   2/12/16       Steven Yin          Added functions to plot data
*
*/

// Updating inteval in milliseconds
final int UPDATE_INTERVAL = 5000;

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

// Plot nothing by default
plot_type my_plot = plot_type.tempreture;

void render_plot()
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
    
    // Back button
    if (mouseX > displayWidth - 320 && mouseX < displayWidth - 200 && mouseY > HEADER_HEIGHT - 105 && mouseY < HEADER_HEIGHT - 65)
    {
        fill(white);
    }
    else
    {
        fill(grey);
    }
    rect(displayWidth - 320, HEADER_HEIGHT - 105, 120, 40, 8);
    fill(black);
    text("BACK", displayWidth - 285, HEADER_HEIGHT - 80);
    
    resetFormat();
    
    // Tempreture button
    if (mouseX > 20 && mouseX < 140 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
    {
        fill(white);
    }
    else
    {
        fill(grey);
    }
    rect(20, HEADER_HEIGHT + 20, 120, 40, 8);
    fill(black);
    text("TEMP", 55, HEADER_HEIGHT + 45);
    
    resetFormat();
    
    // Voltage button
    if (mouseX > 160 && mouseX < 280 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
    {
        fill(white);
    }
    else
    {
        fill(grey);
    }
    rect(160, HEADER_HEIGHT + 20, 120, 40, 8);
    fill(black);
    text("VOLTAGE", 185, HEADER_HEIGHT + 45);
    
    resetFormat();
    
    // Current button
    if (mouseX > 300 && mouseX < 420 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
    {
        fill(white);
    }
    else
    {
        fill(grey);
    }
    rect(300, HEADER_HEIGHT + 20, 120, 40, 8);
    fill(black);
    text("CURRENT", 325, HEADER_HEIGHT + 45);
    
    resetFormat();
    
    // Battery button
    if (mouseX > 440 && mouseX < 560 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
    {
        fill(white);
    }
    else
    {
        fill(grey);
    }
    rect(440, HEADER_HEIGHT + 20, 120, 40, 8);
    fill(black);
    text("BATTERY", 465, HEADER_HEIGHT + 45);
    
    resetFormat();
    
    // Pressure button
    if (mouseX > 580 && mouseX < 700 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
    {
        fill(white);
    }
    else
    {
        fill(grey);
    }
    rect(580, HEADER_HEIGHT + 20, 120, 40, 8);
    fill(black);
    text("PRES", 615, HEADER_HEIGHT + 45);
    
    resetFormat();
    
    // Humidity button
    if (mouseX > 720 && mouseX < 840 && mouseY > HEADER_HEIGHT + 20 && mouseY < HEADER_HEIGHT + 60)
    {
        fill(white);
    }
    else
    {
        fill(grey);
    }
    rect(720, HEADER_HEIGHT + 20, 120, 40, 8);
    fill(black);
    text("HUMIDITY", 745, HEADER_HEIGHT + 45);
    
    // Header seperation lines
    fill(white);
    rect(0, HEADER_HEIGHT, displayWidth, 6);
    rect(0, HEADER_HEIGHT + 80, displayWidth, 6);
    
    // Draw the colour box
    rect(20, HEADER_HEIGHT + 150, 150, 4);
    rect(20, HEADER_HEIGHT + 150, 4, 300);
    rect(20, HEADER_HEIGHT + 446, 150, 4);
    rect(170, HEADER_HEIGHT + 150, 4, 300);
    
    rect(20, HEADER_HEIGHT + 209, 150, 4);
    rect(20, HEADER_HEIGHT + 268, 150, 4);
    rect(20, HEADER_HEIGHT + 327, 150, 4);
    rect(20, HEADER_HEIGHT + 386, 150, 4);
    
    text("ADCS", 40, HEADER_HEIGHT + 189);
    text("CDH", 40, HEADER_HEIGHT + 248);
    text("COMS", 40, HEADER_HEIGHT + 307);
    text("EPS", 40, HEADER_HEIGHT + 366);
    text("PAYL", 40, HEADER_HEIGHT + 425);
    
    fill(s_list.get(0).plot_color);
    rect(110, HEADER_HEIGHT + 167, 30, 30);
    fill(s_list.get(1).plot_color);
    rect(110, HEADER_HEIGHT + 226, 30, 30);
    fill(s_list.get(2).plot_color);
    rect(110, HEADER_HEIGHT + 285, 30, 30);
    fill(s_list.get(3).plot_color);
    rect(110, HEADER_HEIGHT + 344, 30, 30);
    fill(s_list.get(4).plot_color);
    rect(110, HEADER_HEIGHT + 403, 30, 30);
    resetFormat();
    
    // Plot space
    rect(296, HEADER_HEIGHT + 150, DELTA_X * (T_MINUS/(UPDATE_INTERVAL/1000)) + 4, 4);
    rect(296, HEADER_HEIGHT + 154, 4, displayHeight - 400);
    rect(300, HEADER_HEIGHT + displayHeight - 250, DELTA_X * (T_MINUS/(UPDATE_INTERVAL/1000)) + 4, 4);
    rect(DELTA_X * (T_MINUS/(UPDATE_INTERVAL/1000)) + 300, HEADER_HEIGHT + 150, 4, displayHeight - 400);
    
    draw_grid();
    
    for(int i = 0; i < s_list.size(); i++)
    {
        stroke(s_list.get(i).plot_color);
        draw_plot(s_list.get(i));
        resetFormat();
    }
}

/*
* Inititalize each linked list with default constructor
*/
void linked_list_init()
{
    for(int i = 0; i < fields.length; i++)
    {
        for(int j = 0; j < s_list.size(); j++)
        {
            s_list.get(j).my_data_list[i] = new LinkedList();
        }
    }
}

/*
* Update the LinkedLists
*/

void update_plot_data()
{
    for(int i = 0; i < fields.length; i++)
    {
        for(int j = 0; j < s_list.size(); j++)
        {
            if(s_list.get(j).is_updated[i])
            {
                if(s_list.get(j).my_data_list[i].size() < (T_MINUS/(UPDATE_INTERVAL/1000))+1)
                {
                    s_list.get(j).my_data_list[i].add(s_list.get(j).my_data[i]);
                }
                else
                {
                    s_list.get(j).my_data_list[i].removeFirst();
                    s_list.get(j).my_data_list[i].add(s_list.get(j).my_data[i]);
                }
                s_list.get(j).is_updated[i] = false;
            }
        }
    }
  
}

/*
* Function that draw the plot
* Subsystem s is the subsystem that is going to be ploted
*/

void draw_plot(Subsystem s)
{
    // X axis label
    textSize(24);
    text("T - " + T_MINUS + "s", 300 - 34, HEADER_HEIGHT + displayHeight - 200);
    text("T - 0s", 300 + DELTA_X * (T_MINUS/(UPDATE_INTERVAL/1000)) - 20, HEADER_HEIGHT + displayHeight - 200);
    
    // Selection plot_type
    switch(my_plot)
    {
        case tempreture:
        {
            if(s.temp_avail)
            {
                for(int i = 0; i < s.my_data_list[0].size() - 1; i++)
                {
                    line(300+i*DELTA_X, 700-s.my_data_list[0].get(i), 300+(i+1)*DELTA_X, 700-s.my_data_list[0].get(i+1));
                }
            }
        }
        case voltage:
        {
            if(s.volt_avail)
            {
                for(int i = 0; i < s.my_data_list[1].size() - 1; i++)
                {
                    //Need to be done
                }
            }
        }
        case current:
        {
            if(s.curr_avail)
            {
                for(int i = 0; i < s.my_data_list[2].size() - 1; i++)
                {
                    //Need to be done
                }
            }
        }
        case battery:
        {
            if(s.batt_avail)
            {
                for(int i = 0; i < s.my_data_list[3].size() - 1; i++)
                {
                    //Need to be done
                }
            }
        }
        case pressure:
        {
            if(s.pres_avail)
            {
                for(int i = 0; i < s.my_data_list[4].size() - 1; i++)
                {
                    //Need to be done
                }
            }
        }
        case humidity:
        {
            if(s.humid_avail)
            {
                for(int i = 0; i < s.my_data_list[5].size() - 1; i++)
                {
                    //Need to be done
                }
            }
        }
    }
}

/*
* Function that draw the grid in the plot
*/
void draw_grid()
{
    int x_interval = (DELTA_X * (T_MINUS/(UPDATE_INTERVAL/1000)))/GRID_X;
    int y_interval = (displayHeight - 400)/GRID_Y;
    
    stroke(100, 100, 100);
    
    for(int i = 1; i < GRID_X; i++)
    {
        line(i*x_interval + 300, HEADER_HEIGHT + 154, i*x_interval + 300, HEADER_HEIGHT + displayHeight - 250);
    }
    for(int i = 1; i < GRID_Y; i++)
    {
        line(300, HEADER_HEIGHT + 150 + i*y_interval, displayWidth - 120, HEADER_HEIGHT + 150 + i*y_interval); 
    }
    resetFormat();
}