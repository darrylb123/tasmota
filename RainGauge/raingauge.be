import json
import string
import mqtt
import persist
import gpio
# Change this to the calibrated 
var pulses_per_mm = real(3.3) 
# Was 4.5

var rainRate = 0.0
var counter_no = int(0)
var rainMem = persist.RainTotal
var sendMqtt = 0
var mm_per_pulse = 1/pulses_per_mm



def rain2mqtt()
    var rainToday = persist.RainTotal - persist.RainAtMidnight
    var rainWeek = persist.RainWeek + rainToday

    var rainMonth = persist.RainTotal - persist.RainMonth
	var rain_data_msg = json.dump({ "RainToday":rainToday,"RainRate":rainRate,"RainWeek":rainWeek,"RainMonth":rainMonth,"RainTotal":persist.RainTotal,"RainYear":persist.RainYear})
	mqtt.publish("stat/RainGauge/rain",rain_data_msg,true)
	print(rain_data_msg)
end

def calc_rate()
     if  persist.RainTotal >  rainMem
         rainRate = (persist.RainTotal - rainMem) * 6 # Rain rate mm/hr
	 var rain_rate_msg = json.dump({ "RainRate":rainRate })
	 mqtt.publish("stat/RainGauge/rain",rain_rate_msg,true)
     else
         rainRate = 0
     end
     rainMem = persist.RainTotal   
end

def rain_ten_sec()
    var counts = gpio.counter_read(counter_no)
    if counts > 0 
        gpio.counter_set(counter_no,0)
        print( "Rain Counts", counts)
        persist.RainTotal  = persist.RainTotal + ( counts * mm_per_pulse )
        persist.save()
        rain2mqtt()
    end
end

def rain_day()
	log("Each Day")
	# Calculate the annual rainfall
	var rainToday = persist.RainTotal - persist.RainAtMidnight
	var year_avg = persist.RainYear/365
	persist.RainYear = persist.RainYear + (rainToday) - year_avg
	persist.RainAtMidnight = persist.RainTotal
	persist.RainHist[6] = persist.RainHist[5] 
	persist.RainHist[5] = persist.RainHist[4]
	persist.RainHist[4] = persist.RainHist[3]
	persist.RainHist[3] = persist.RainHist[2]
	persist.RainHist[2] = persist.RainHist[1]
	persist.RainHist[1] = persist.RainHist[0]
	persist.RainHist[0]  = rainToday
	persist.RainWeek = persist.RainHist[0] + persist.RainHist[1] + persist.RainHist[2] + persist.RainHist[3] + persist.RainHist[4] + persist.RainHist[5] + persist.RainHist[6]
	persist.save()
end


def rain_month()
	log("Each Month")
	persist.RainMonth = persist.RainTotal
	persist.save()
end



tasmota.add_cron("*/10 * * * * *",rain_ten_sec,"ten_sec")
tasmota.add_cron("0 */10 * * * *",rain2mqtt,"send_data")
tasmota.add_cron("0 * * * * *",calc_rate,"each_minute")
tasmota.add_cron("10 0 0 * * *", rain_day, "each_day")
tasmota.add_cron("20 0 0 1 * *", rain_month, "each_month")

# To reset the total
# persist.RainTotal = persist.RainAtMidnight
