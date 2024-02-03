import json
import string
import mqtt
import persist
# Change this to the calibrated 
var pulses_per_mm = 3.3

var rainMem = 0.0
var rainRate = 0.0

var sendMqtt = 0
var mm_per_pulse = 1/pulses_per_mm


def rain2mqtt()
    var rainToday = persist.RainTotal - persist.RainAtMidnight
    var rainWeek = persist.RainTotal - persist.RainWeek
    var rainMonth = persist.RainTotal - persist.RainMonth
	var rain_data_msg = json.dump({ "RainToday":rainToday,"RainRate":rainRate,"RainWeek":rainWeek,"RainMonth":rainMonth,"RainTotal":persist.RainTotal,"RainYear":persist.RainYear})
	mqtt.publish("stat/ShedIO/rain",rain_data_msg)
end

def rainGaugePulse()
    persist.RainTotal = persist.RainTotal + mm_per_pulse
    persist.save()
    sendMqtt = 1
end

def rain_ten_sec()
    if  persist.RainTotal >  rainMem
        rainRate = (persist.RainTotal - rainMem) * 360 # Rain rate mm/hr
    else
        rainRate = 0
    end
    rainMem = persist.RainTotal
    if sendMqtt
        rain2mqtt()
        sendMqtt = 0
    end
end

def rain_day()
	log("Each Day")
	# Calculate the annual rainfall
	var year_avg = persist.RainYear/365
	persist.RainYear = persist.RainYear + (persist.RainTotal - persist.RainAtMidnight) - year_avg
	persist.RainAtMidnight = persist.RainTotal
	persist.save()
end

def rain_week()
	log("Each Week")
	persist.RainWeek = persist.RainTotal
	persist.save()
end

def rain_month()
	log("Each Month")
	persist.RainMonth = persist.RainTotal
	persist.save()
end

tasmota.add_rule("TELE#SWITCH1",rain2mqtt)
tasmota.add_rule("SWITCH1#STATE",rainGaugePulse)
tasmota.add_cron("*/10 * * * * *",rain_ten_sec,"calc_rate")
tasmota.add_cron("10 0 0 * * *", rain_day, "each_day")
tasmota.add_cron("10 0 0 * * 0", rain_week, "each_week")
tasmota.add_cron("20 0 0 1 * *", rain_month, "each_month")

# To reset the total
# persist.RainTotal = xxxx
