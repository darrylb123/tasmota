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

def ha_autoconfigure()
# Auto configure Home Assistant
  var ha_auto = json.dump( {
  "dev": {
    "ids": "ccffe2c0547c00",
    "name": "Rain Gauge",
    "mf": "darrylb123",
    "mdl": "AliEx",
    "sw": "1.0",
    "sn": "ccffe2c0547c00",
    "hw": "1.0rev2"
  },
  "o": {
    "name":"Rain Gauge Readings",
    "sw": "2.1",
    "url": "https://github.com/darrylb123/tasmota/tree/main/RainGauge"
  },
  "cmps": {
    "rain_total": {
      "p": "sensor",
      "name": "Rain Total",
      "device_class":"precipitation",
      "unit_of_measurement":"mm",
      "value_template":"{{ '%0.1f'|format(value_json.RainTotal) }}",
      "unique_id":"rain_gauge_total"
    },
    "rain_today": {
      "p": "sensor",
      "name": "Rain Today",
      "device_class":"precipitation",
      "unit_of_measurement":"mm",
      "value_template":"{{ '%0.1f'|format(value_json.RainToday) }}",
      "unique_id":"rain_gauge_today"
    },
    "rain_week": {
      "p": "sensor",
      "name": "Rain Week",
      "device_class":"precipitation",
      "unit_of_measurement":"mm",
      "value_template":"{{ '%0.1f'|format(value_json.RainWeek) }}",
      "unique_id":"rain_gauge_week"
    },
    "rain_month": {
      "p": "sensor",
      "name": "Rain Month",
      "device_class":"precipitation",
      "unit_of_measurement":"mm",
      "value_template":"{{ '%0.1f'|format(value_json.RainMonth) }}",
      "unique_id":"rain_gauge_month"
    },
    "rain_year": {
      "p": "sensor",
      "name": "Rain Year",
      "device_class":"precipitation",
      "unit_of_measurement":"mm",
      "value_template":"{{ '%0.1f'|format(value_json.RainYear) }}",
      "unique_id":"rain_gauge_year"
    },
    "rain_rate": {
      "p": "sensor",
      "name": "Rain Rate",
      "device_class":"precipitation_intensity",
      "unit_of_measurement":"mm/h",
      "value_template":"{{ '%0.1f'|format(value_json.RainRate) }}",
      "unique_id":"rain_gauge_rate"
    },
  },
  "state_topic":"stat/RainGauge/rain",
  "qos": 2
} )


  mqtt.publish("homeassistant/device/ccffe2c0547c00/config",ha_auto,true)
end

tasmota.add_rule("Mqtt#Connected",ha_autoconfigure)
tasmota.add_cron("*/10 * * * * *",rain_ten_sec,"ten_sec")
tasmota.add_cron("0 */10 * * * *",rain2mqtt,"send_data")
tasmota.add_cron("0 * * * * *",calc_rate,"each_minute")
tasmota.add_cron("10 0 0 * * *", rain_day, "each_day")
tasmota.add_cron("20 0 0 1 * *", rain_month, "each_month")



# To reset the total
# persist.RainTotal = persist.RainAtMidnight
