import json
import string
import mqtt
import persist
import gpio
# Change this to the calibrated 
var pulses_per_mm = real(4.8) 
# Was 4.5

var rainRate = 0.0
var counter_no = 2
var rainMem = 0.0
var sendMqtt = 0
var mm_per_pulse = 1/pulses_per_mm

class RainGauge
    var count, last_state
    def every_100ms()
        if !gpio.digital_read(5) 
            if !self.last_state 
                tasmota.set_timer(20,/->self.check())
                self.last_state = true
            end
        else
            self.last_state = false
        end
    end
    def check()
        if !gpio.digital_read(5)
            self.count = self.count + 1
        end
    end
    def pc()
        print(self.count)
    end
    def init()
        self.count = 0
        self.last_state = false
    end
end
# d1 = RainGauge()
# tasmota.add_driver(d1)


def rain2mqtt()
    var rainToday = persist.RainTotal - persist.RainAtMidnight
    var rainWeek = persist.RainWeek
    var rainMonth = persist.RainTotal - persist.RainMonth
	var rain_data_msg = json.dump({ "RainToday":rainToday,"RainRate":rainRate,"RainWeek":rainWeek,"RainMonth":rainMonth,"RainTotal":persist.RainTotal,"RainYear":persist.RainYear})
	mqtt.publish("stat/ShedIO/rain",rain_data_msg,true)
	print(rain_data_msg)
end

def rain_ten_sec()
    var counts = gpio.counter_read(2)
    if counts > 0 
        gpio.counter_set(2,0)
        print( "Rain Counts", counts)
        persist.RainTotal  = persist.RainTotal + ( counts * mm_per_pulse )
        persist.save()

        if  persist.RainTotal >  rainMem
            rainRate = (persist.RainTotal - rainMem) * 360 # Rain rate mm/hr
        else
            rainRate = 0
        end
        rainMem = persist.RainTotal
        rain2mqtt()
    else
        rainRate = 0
    end
end

def rain_day()
	log("Each Day")
	# Calculate the annual rainfall
	var rainToday = persist.RainTotal - persist.RainAtMidnight
	var year_avg = persist.RainYear/365
	persist.RainYear = persist.RainYear + rainToday - year_avg
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



tasmota.add_cron("*/10 * * * * *",rain_ten_sec,"calc_rate")
tasmota.add_cron("0 */10 * * * *",rain2mqtt,"send_data")
tasmota.add_cron("10 0 0 * * *", rain_day, "each_day")
tasmota.add_cron("20 0 0 1 * *", rain_month, "each_month")

# To reset the total
# persist.RainTotal = persist.RainAtMidnight
