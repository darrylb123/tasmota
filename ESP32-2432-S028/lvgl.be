# Display Rendering and callbacks
lv.start()

# var scr1 = lv.obj_create(None, None);
# var scr2  = lv.obj_create(None, None);
# lv.scr_load(scr1);

hres = lv.get_hor_res()       # should be 320
vres = lv.get_ver_res()       # should be 240

scr = lv.scr_act()            # default screen object
f20 = lv.montserrat_font(20)  # load embedded Montserrat 20
f28 = lv.montserrat_font(28)  # load embedded Montserrat 28

#- Background with a gradient from black #000000 (bottom) to dark blue #0000A0 (top) -#
scr.set_style_bg_color(lv.color(0x000000), lv.PART_MAIN | lv.STATE_DEFAULT)
scr.set_style_bg_grad_color(lv.color(0x000000), lv.PART_MAIN | lv.STATE_DEFAULT)
scr.set_style_bg_grad_dir(lv.GRAD_DIR_VER, lv.PART_MAIN | lv.STATE_DEFAULT)

#- Upper state line -#
stat_line = lv.label(scr)
if f28 != nil stat_line.set_style_text_font(f28, lv.PART_MAIN | lv.STATE_DEFAULT) end
stat_line.set_long_mode(lv.LABEL_LONG_SCROLL)                                        # auto scrolling if text does not fit
stat_line.set_width(hres)
stat_line.set_align(lv.TEXT_ALIGN_LEFT)                                              # align text left
stat_line.set_style_bg_color(lv.color(0x1fa3ec), lv.PART_MAIN | lv.STATE_DEFAULT)    # background #000088
stat_line.set_style_bg_opa(lv.OPA_COVER, lv.PART_MAIN | lv.STATE_DEFAULT)            # 100% background opacity
stat_line.set_style_text_color(lv.color(0xFFFFFF), lv.PART_MAIN | lv.STATE_DEFAULT)  # text color #FFFFFF
stat_line.set_text(string.format("Speed: %4.1f",speedCur))
stat_line.refr_size()                                                                # new in LVGL8
stat_line.refr_pos() 
   
#- Second state line -#
set_line = lv.label(scr)
set_line.set_pos(0,40)
if f28 != nil set_line.set_style_text_font(f20, lv.PART_MAIN | lv.STATE_DEFAULT) end
set_line.set_long_mode(lv.LABEL_LONG_SCROLL)                                        # auto scrolling if text does not fit
set_line.set_width(hres)
set_line.set_align(lv.TEXT_ALIGN_LEFT)                                              # align text left
set_line.set_style_bg_color(lv.color(0x1fa3ec), lv.PART_MAIN | lv.STATE_DEFAULT)    # background #000088
set_line.set_style_bg_opa(lv.OPA_COVER, lv.PART_MAIN | lv.STATE_DEFAULT)            # 100% background opacity
set_line.set_style_text_color(lv.color(0xFFFFFF), lv.PART_MAIN | lv.STATE_DEFAULT)  # text color #FFFFFF
set_line.set_text(string.format("Setpoint: %4.1f",speedSP))
set_line.refr_size()                                                                # new in LVGL8
set_line.refr_pos()                                                                     # new in LVGL8

#- display wifi strength indicator icon (for professionals ;) -#
#wifi_icon = lv_wifi_arcs_icon(stat_line)    # the widget takes care of positioning and driver stuff
# clock_icon = lv_clock_icon(stat_line)


#- create a style for the buttons -#
btn_style = lv.style()
btn_style.set_radius(10)                        # radius of rounded corners
btn_style.set_bg_opa(lv.OPA_COVER)              # 100% backgrond opacity
if f20 != nil btn_style.set_text_font(f20) end  # set font to Montserrat 20
btn_style.set_bg_color(lv.color(0x1fa3ec))      # background color #1FA3EC (Tasmota Blue)
btn_style.set_border_color(lv.color(0x0000FF))  # border color #0000FF
btn_style.set_text_color(lv.color(0xFFFFFF))    # text color white #FFFFFF

#- create buttons -#
prev_btn = lv.btn(scr)                            # create button with main screen as parent
prev_btn.set_pos(20,vres-40)                      # position of button
prev_btn.set_size(80, 30)                         # size of button
prev_btn.add_style(btn_style, lv.PART_MAIN | lv.STATE_DEFAULT)   # style of button
prev_label = lv.label(prev_btn)                   # create a label as sub-object
prev_label.set_text(lv.SYMBOL_DOWN)                          # set label text
prev_label.center()

next_btn = lv.btn(scr)                            # right button
next_btn.set_pos(220,vres-40)
next_btn.set_size(80, 30)
next_btn.add_style(btn_style, lv.PART_MAIN | lv.STATE_DEFAULT)
next_label = lv.label(next_btn)
next_label.set_text(lv.SYMBOL_UP)
next_label.center()

home_btn = lv.btn(scr)                            # center button
home_btn.set_pos(120,vres-40)
home_btn.set_size(80, 30)
home_btn.add_style(btn_style, lv.PART_MAIN | lv.STATE_DEFAULT)
home_label = lv.label(home_btn)
home_label.set_text("Save")                 # set text as Home icon
home_label.center()

onoff_btn = lv.btn(scr)                            # center button
onoff_btn.set_pos(220,vres-150)
onoff_btn.set_size(80, 80)
onoff_btn.add_style(btn_style, lv.PART_MAIN | lv.STATE_DEFAULT)
onoff_label = lv.label(onoff_btn)
if !speedEngaged
    onoff_btn.set_style_bg_color(lv.color(0x1fa3ec), lv.PART_MAIN | lv.STATE_DEFAULT)
    onoff_label.set_text("Off")                 # set text as Home icon
else
    onoff_btn.set_style_bg_color(lv.color(0xD00000), lv.PART_MAIN | lv.STATE_DEFAULT)
    onoff_label.set_text("On")                 # set text as Home icon
end
onoff_label.center()

# toggle the speed cruise control
def toggle_engaged()
    speedEngaged = !speedEngaged
    if !speedEngaged
        onoff_btn.set_style_bg_color(lv.color(0x1fa3ec), lv.PART_MAIN | lv.STATE_DEFAULT)
        onoff_label.set_text("Off")                 # set text as Home icon
    else
        onoff_btn.set_style_bg_color(lv.color(0xD00000), lv.PART_MAIN | lv.STATE_DEFAULT)
        onoff_label.set_text("On")                 # set text as Home icon
    end
end
#- callback function when a button is pressed, react to EVENT_CLICKED event -#
def btn_clicked_cb(obj, event)
    var btn = "Unknown"
    if   obj == prev_btn  
        btn = "Prev"
        speedSP -= 0.5
        set_line.set_text(string.format("Setpoint: %4.1f",speedSP))
    elif obj == next_btn  
        btn = "Next"
        speedSP += 0.5
        set_line.set_text(string.format("Setpoint: %4.1f",speedSP))
    elif obj == home_btn  
        btn = "Save"
        persist.setpoint = speedSP
        persist.save()
    elif obj == onoff_btn  
        btn = "OnOff"
        toggle_engaged()
    end
    print(btn, "button pressed")
    tasmota.cmd("buzzer 1")
end

def buzzer_enable()
  tasmota.cmd("buzzerpwm 1") # use PWM on buzzer pin (GPIO21)
  tasmota.cmd("pwmfrequency 1000") # highest volume at 2700 as per datasheet of LET7525AS-3.6L-2.7-15-R
  tasmota.cmd("setoption111 1")
end

buzzer_enable()


prev_btn.add_event_cb(btn_clicked_cb, lv.EVENT_CLICKED, 0)
next_btn.add_event_cb(btn_clicked_cb, lv.EVENT_CLICKED, 0)
home_btn.add_event_cb(btn_clicked_cb, lv.EVENT_CLICKED, 0)
onoff_btn.add_event_cb(btn_clicked_cb, lv.EVENT_CLICKED, 0)


def dropdown_changed_cb(obj, event)
    var option = "Unknown"

    var modes = ['Limit High', 'Limit Low' ]

    var code = event.code

    if code == lv.EVENT_VALUE_CHANGED
       print("Dropdown code :", code )
       speedLimMode = obj.get_selected()
   
       print("Dropdown set:", modes[speedLimMode])
       persist.limit = speedLimMode
       persist.save()
     end

end

var modes = ['Limit High', 'Limit Low' ]

var modes_str = modes.concat('\n')
ddlist = lv.dropdown(scr)
ddlist.set_options(modes_str)
ddlist.set_selected(speedLimMode)
ddlist.set_pos(20,vres-150)
# ddlist.center()
ddlist.add_event_cb(dropdown_changed_cb, lv.EVENT_ALL, None)

