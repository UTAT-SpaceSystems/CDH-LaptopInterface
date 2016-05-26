/*
* FILE NAME: plot_data
* PURPOSE: Components that helps to plot data coming from CAN bus

* DEVELOPMENT HISTORY:
*   Date          Author              Description of Change
*   02/12/16      Steven Yin          Added functions to plot data
*
*   02/21/16      Steven Yin          Changed data structure
*
*   02/25/16      Steven Yin          perfection of UI
*/



void render_plot()
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
    
    resetFormat();
    
    // Back button
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
    text("BACK", displayWidth - 135, HEADER_HEIGHT - 25);
    
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
    
    // Acceleration button
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
    text("ACCEL", 475, HEADER_HEIGHT + 45);
    
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
    
    // Photodiode button
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
    text("PHOTO", 745, HEADER_HEIGHT + 45);
    
    // Header seperation lines
    fill(white);
    rect(0, HEADER_HEIGHT, displayWidth, 4);
    rect(0, HEADER_HEIGHT + 80, displayWidth, 4);
    
    for(int i = 0; i < full_sensor_list.get(my_plot.value()).sensor_list.size(); i++)
    {
        fill(full_sensor_list.get(my_plot.value()).sensor_list.get(i).sensor_color);
        text(full_sensor_list.get(my_plot.value()).sensor_list.get(i).sensor_name, 20, HEADER_HEIGHT + 190 + i * 60);
    }
    resetFormat();
    
    // Plot space
    rect(296, HEADER_HEIGHT + 150, DELTA_X * (T_MINUS/(UPDATE_INTERVAL/1000)) + 4, 4);
    rect(296, HEADER_HEIGHT + 154, 4, displayHeight - 400);
    rect(300, HEADER_HEIGHT + displayHeight - 250, DELTA_X * (T_MINUS/(UPDATE_INTERVAL/1000)) + 4, 4);
    rect(DELTA_X * (T_MINUS/(UPDATE_INTERVAL/1000)) + 300, HEADER_HEIGHT + 150, 4, displayHeight - 400);
    
    draw_grid();
    
    draw_plot();

}


/*
* Update the LinkedLists
*/
void update_plot_data()
{
    for(int i = 0; i < full_sensor_list.size(); i++)
    {
        for(int j = 0; j < full_sensor_list.get(i).sensor_list.size(); j++)
        {
            if(full_sensor_list.get(i).sensor_list.get(j).sensor_is_updated)
            {
                if(full_sensor_list.get(i).sensor_list.get(j).sensor_data.size() < (T_MINUS/(UPDATE_INTERVAL/1000))+1)
                {
                    full_sensor_list.get(i).sensor_list.get(j).sensor_data.add(full_sensor_list.get(i).sensor_list.get(j).sensor_data_buff);
                }
                else
                {
                    full_sensor_list.get(i).sensor_list.get(j).sensor_data.removeFirst();
                    full_sensor_list.get(i).sensor_list.get(j).sensor_data.add(full_sensor_list.get(i).sensor_list.get(j).sensor_data_buff);
                }
                full_sensor_list.get(i).sensor_list.get(j).sensor_is_updated = false;
            }
        }
    }
}

/*
* Function that draw the plot
*/
void draw_plot()
{
    for(int i = 0; i < full_sensor_list.get(my_plot.value()).sensor_list.size(); i++)
    {
        if(full_sensor_list.get(my_plot.value()).sensor_list.get(i).sensor_avail)
        {
            stroke(full_sensor_list.get(my_plot.value()).sensor_list.get(i).sensor_color);
            float dy =  (displayHeight - 400) / (full_sensor_list.get(my_plot.value()).boundary_high - full_sensor_list.get(my_plot.value()).boundary_low);
            for(int j = 0; j < full_sensor_list.get(my_plot.value()).sensor_list.get(i).sensor_data.size() - 1; j++)
            {
                line(300 + j * DELTA_X, HEADER_HEIGHT + displayHeight - 250 - (full_sensor_list.get(my_plot.value()).sensor_list.get(i).sensor_data.get(j) * dy), 300 + (j + 1) * DELTA_X, HEADER_HEIGHT + displayHeight - 250 - full_sensor_list.get(my_plot.value()).sensor_list.get(i).sensor_data.get(j + 1) * dy);
            }
            resetFormat();
        }
    }
}

/*
* Function that draw the grid and the label
*/
void draw_grid()
{
    float x_interval = (DELTA_X * (T_MINUS/(UPDATE_INTERVAL/1000)))/GRID_X;
    float y_interval = (displayHeight - 400)/GRID_Y;
    
    stroke(100, 100, 100);
    
    for(int i = 1; i < GRID_X; i++) // 
    {
        line(i * x_interval + 300, HEADER_HEIGHT + 154, i * x_interval + 300, HEADER_HEIGHT + displayHeight - 250);
    }
    for(int i = 1; i < GRID_Y; i++)
    {
        line(300, HEADER_HEIGHT + 150 + i * y_interval, displayWidth - 120, HEADER_HEIGHT + 150 + i * y_interval); 
    }
    resetFormat();
    
    draw_label(y_interval);
}

void draw_label(float y_interval)
{
    // X axis label
    textSize(24);
    text("T - " + T_MINUS + "s", 300 - 34, HEADER_HEIGHT + displayHeight - 200);
    text("T - 0s", 300 + DELTA_X * (T_MINUS/(UPDATE_INTERVAL/1000)) - 20, HEADER_HEIGHT + displayHeight - 200);
    
    // Y axis label
    textSize(20);
    for(int i = 0; i <= GRID_Y; i++)
    {
        text(full_sensor_list.get(my_plot.value()).boundary_low + (GRID_Y - i) * ((full_sensor_list.get(my_plot.value()).boundary_high - full_sensor_list.get(my_plot.value()).boundary_low) / GRID_Y), 200, HEADER_HEIGHT + 150 + i * y_interval);
    }
    resetFormat();
}

void update_hk_data()
{
    int sensor_id = 0;
    int value = 0;
    for(int i = 0; i < 58; i+=2)
    {
        sensor_id = hk_def[i];
        value = (int)hk_buffer[i];      // Updated on the fly for both CAN and transceiver modes.
        value |= ((int)hk_buffer[i + 1]) << 8;
        value &= 0xFFFF;
        switch(sensor_id)
        {
            // Example case
            /*
            case SENSOR_NAME:
            // If no conversion on senssor data is needed otherwise convert data to integer
                full_sensor_list.get(0).sensor_list.get(1).sensor_avail = true;
                full_sensor_list.get(0).sensor_list.get(1).sensor_data_buff = value;
                full_sensor_list.get(0).sensor_list.get(1).sensor_is_updated = true;
            */
            case PANELX_V:
            {
                if(value > 8400)
                    value = 8400;
                full_sensor_list.get(1).sensor_list.get(0).sensor_avail = true;
                full_sensor_list.get(1).sensor_list.get(0).sensor_data_buff = value;
                full_sensor_list.get(1).sensor_list.get(0).sensor_is_updated = true;
                break;
            }
            case PANELX_I:
            {
                if(value > 4500)
                    value = 4500;
                full_sensor_list.get(2).sensor_list.get(0).sensor_avail = true;
                full_sensor_list.get(2).sensor_list.get(0).sensor_data_buff = value;
                full_sensor_list.get(2).sensor_list.get(0).sensor_is_updated = true;
                break;
            }
            case PANELY_V:
            {
                if(value > 8400)
                    value = 8400;
                full_sensor_list.get(1).sensor_list.get(1).sensor_avail = true;
                full_sensor_list.get(1).sensor_list.get(1).sensor_data_buff = value;
                full_sensor_list.get(1).sensor_list.get(1).sensor_is_updated = true;
                break;
            }
            case PANELY_I:
            {
                if(value > 4500)
                    value = 4500;
                full_sensor_list.get(2).sensor_list.get(1).sensor_avail = true;
                full_sensor_list.get(2).sensor_list.get(1).sensor_data_buff = value;
                full_sensor_list.get(2).sensor_list.get(1).sensor_is_updated = true;
                break;
            }
            case BATT_V:
            {
                if(value > 8400)
                    value = 8400;
                full_sensor_list.get(1).sensor_list.get(2).sensor_avail = true;
                full_sensor_list.get(1).sensor_list.get(2).sensor_data_buff = value;
                full_sensor_list.get(1).sensor_list.get(2).sensor_is_updated = true;
                break;
            }
            case BATTIN_I:
            {
                if(value > 4500)
                    value = 4500;
                full_sensor_list.get(2).sensor_list.get(2).sensor_avail = true;
                full_sensor_list.get(2).sensor_list.get(2).sensor_data_buff = value;
                full_sensor_list.get(2).sensor_list.get(2).sensor_is_updated = true;
                break;
            }
            case BATTOUT_I:
            {
                if(value > 4500)
                    value = 4500;
                full_sensor_list.get(2).sensor_list.get(3).sensor_avail = true;
                full_sensor_list.get(2).sensor_list.get(3).sensor_data_buff = value;
                full_sensor_list.get(2).sensor_list.get(3).sensor_is_updated = true;
                break;
            }
            case EPS_TEMP:
            {
                if(value > 100)
                    value = 100;
                full_sensor_list.get(0).sensor_list.get(0).sensor_avail = true;
                full_sensor_list.get(0).sensor_list.get(0).sensor_data_buff = value;
                full_sensor_list.get(0).sensor_list.get(0).sensor_is_updated = true;
                break;
            }
            case COMS_V:
            {
                if(value > 8400)
                    value = 8400;
                full_sensor_list.get(1).sensor_list.get(3).sensor_avail = true;
                full_sensor_list.get(1).sensor_list.get(3).sensor_data_buff = value;
                full_sensor_list.get(1).sensor_list.get(3).sensor_is_updated = true;
                break;
            }
            case COMS_I:
            {
                if(value > 4500)
                    value = 4500;
                full_sensor_list.get(2).sensor_list.get(4).sensor_avail = true;
                full_sensor_list.get(2).sensor_list.get(4).sensor_data_buff = value;
                full_sensor_list.get(2).sensor_list.get(4).sensor_is_updated = true;
                break;
            }
            case PAY_V:
            {
                if(value > 8400)
                    value = 8400;
                full_sensor_list.get(1).sensor_list.get(4).sensor_avail = true;
                full_sensor_list.get(1).sensor_list.get(4).sensor_data_buff = value;
                full_sensor_list.get(1).sensor_list.get(4).sensor_is_updated = true;
                break;
            }
            case PAY_I:
            {
                if(value > 4500)
                    value = 4500;
                full_sensor_list.get(2).sensor_list.get(5).sensor_avail = true;
                full_sensor_list.get(2).sensor_list.get(5).sensor_data_buff = value;
                full_sensor_list.get(2).sensor_list.get(5).sensor_is_updated = true;
                break;
            }
            case OBC_V:
            {
                if(value > 8400)
                    value = 8400;
                full_sensor_list.get(1).sensor_list.get(5).sensor_avail = true;
                full_sensor_list.get(1).sensor_list.get(5).sensor_data_buff = value;
                full_sensor_list.get(1).sensor_list.get(5).sensor_is_updated = true;
                break;
            }
            case OBC_I:
            {
                if(value > 4500)
                    value = 4500;
                full_sensor_list.get(2).sensor_list.get(6).sensor_avail = true;
                full_sensor_list.get(2).sensor_list.get(6).sensor_data_buff = value;
                full_sensor_list.get(2).sensor_list.get(6).sensor_is_updated = true;
                break;
            }
            case COMS_TEMP:
            {
                if(value > 100)
                    value = 100;
                full_sensor_list.get(0).sensor_list.get(1).sensor_avail = true;
                full_sensor_list.get(0).sensor_list.get(1).sensor_data_buff = value;
                full_sensor_list.get(0).sensor_list.get(1).sensor_is_updated = true;
                break;
            }
            case OBC_TEMP:
            {
                if(value > 100)
                    value = 100;
                full_sensor_list.get(0).sensor_list.get(2).sensor_avail = true;
                full_sensor_list.get(0).sensor_list.get(2).sensor_data_buff = value;
                full_sensor_list.get(0).sensor_list.get(2).sensor_is_updated = true;
                break;
            }
            case PAY_TEMP0:
            {
                if(value > 100)
                    value = 100;
                full_sensor_list.get(0).sensor_list.get(3).sensor_avail = true;
                full_sensor_list.get(0).sensor_list.get(3).sensor_data_buff = value;
                full_sensor_list.get(0).sensor_list.get(3).sensor_is_updated = true;
                break;
            }
            case PAY_PRESS:
            {
                if(value > 2000)
                    value = 2000;
                full_sensor_list.get(4).sensor_list.get(0).sensor_avail = true;
                full_sensor_list.get(4).sensor_list.get(0).sensor_data_buff = value;
                full_sensor_list.get(4).sensor_list.get(0).sensor_is_updated = true;
                break;
            }
            case PAY_ACCEL_X:
            {
                if(value > 2000)
                    value = 2000;
                full_sensor_list.get(3).sensor_list.get(0).sensor_avail = true;
                full_sensor_list.get(3).sensor_list.get(0).sensor_data_buff = value;
                full_sensor_list.get(3).sensor_list.get(0).sensor_is_updated = true;
                break;
            }
            case PAY_ACCEL_Y:
            {
                if(value > 2000)
                    value = 2000;
                full_sensor_list.get(3).sensor_list.get(1).sensor_avail = true;
                full_sensor_list.get(3).sensor_list.get(1).sensor_data_buff = value;
                full_sensor_list.get(3).sensor_list.get(1).sensor_is_updated = true;
                break;
            }
            case PAY_ACCEL_Z:
            {
                if(value > 2000)
                    value = 2000;
                full_sensor_list.get(3).sensor_list.get(2).sensor_avail = true;
                full_sensor_list.get(3).sensor_list.get(2).sensor_data_buff = value;
                full_sensor_list.get(3).sensor_list.get(2).sensor_is_updated = true;
                break;
            }
            case PAY_FL_PD0:
            {
                if(value > 1024)
                    value = 1024;
                full_sensor_list.get(5).sensor_list.get(0).sensor_avail = true;
                full_sensor_list.get(5).sensor_list.get(0).sensor_data_buff = value;
                full_sensor_list.get(5).sensor_list.get(0).sensor_is_updated = true;
                break;
            }
            case PAY_FL_PD1:
            {
                if(value > 1024)
                    value = 1024;
                full_sensor_list.get(5).sensor_list.get(1).sensor_avail = true;
                full_sensor_list.get(5).sensor_list.get(1).sensor_data_buff = value;
                full_sensor_list.get(5).sensor_list.get(1).sensor_is_updated = true;
                break;
            }
            case PAY_FL_PD2:
            {
                if(value > 1024)
                    value = 1024;
                full_sensor_list.get(5).sensor_list.get(2).sensor_avail = true;
                full_sensor_list.get(5).sensor_list.get(2).sensor_data_buff = value;
                full_sensor_list.get(5).sensor_list.get(2).sensor_is_updated = true;
                break;
            }
            case PAY_FL_PD3:
            {
                if(value > 1024)
                    value = 1024;
                full_sensor_list.get(5).sensor_list.get(3).sensor_avail = true;
                full_sensor_list.get(5).sensor_list.get(3).sensor_data_buff = value;
                full_sensor_list.get(5).sensor_list.get(3).sensor_is_updated = true;
                break;
            }
            case PAY_FL_PD4:
            {
                if(value > 1024)
                    value = 1024;
                full_sensor_list.get(5).sensor_list.get(4).sensor_avail = true;
                full_sensor_list.get(5).sensor_list.get(4).sensor_data_buff = value;
                full_sensor_list.get(5).sensor_list.get(4).sensor_is_updated = true;
                break;
            }
            case PAY_FL_PD5:
            {
                if(value > 1024)
                    value = 1024;
                full_sensor_list.get(5).sensor_list.get(5).sensor_avail = true;
                full_sensor_list.get(5).sensor_list.get(5).sensor_data_buff = value;
                full_sensor_list.get(5).sensor_list.get(5).sensor_is_updated = true;
                break;
            }
            default:
                break;
        }
    }
}