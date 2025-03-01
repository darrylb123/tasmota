#######################################################################################
# flowmeter.be
#######################################################################################
import json
import string
import mqtt
import persist
var sensors = json.load(tasmota.read_sensors())
var old_water_count = sensors['COUNTER']['C1']
var old_tank_count = sensors['COUNTER']['C2']

var tank_lpm = 0
var tank_today = 0

var ten_min_count = 0
var pulses_per_l = 255.0
# Initialise the json messages, replaced with the real ones later
var water_msg = map()
var flow_msg = map()
water_msg = {'state': "",'area':"",'timeout':0,'totalLitres':0, 'maxlpm':0,'endcount':0,'highflow':false,'stopcause':""}
flow_msg = {'lpm':0,'Count':0,'Change':0,'Litres':0}
var front = 2
var back = 3
var pump = 4

def shed_data()
	var shed_data_msg = json.dump({ "TankLPM":tank_lpm,"TankToday":tank_today})
	mqtt.publish("stat/ShedIO/data",shed_data_msg)
end

def tank_flow()
	# measured litres (1024 pulses = 3.1l)
	var lpc = 0.003027344

	var counter = sensors['COUNTER']['C2']
	if counter<old_tank_count
		old_tank_count = counter
	end
	var change_count = counter - old_tank_count
	old_tank_count = counter
	tank_lpm = lpc * change_count
	tank_today = lpc * counter
	var litres = string.format("%6.2f",tank_lpm)
	var today = string.format("%6.2f",tank_today)
	var output_str = string.format("Tank In Litres/min: %s",litres)
	log(output_str)
	output_str = string.format("Tank In Litres: %s",today)
	log(output_str)
end


# called every 10 seconds
def water_flow()
	var counter = sensors['COUNTER']['C1']
	# Send the mqtt message every 10 min if nothing is happening
	ten_min_count = ten_min_count + 1
	if ten_min_count >= 60
		ten_min_count = 0
	end
	# if water flowmeter is registering flow send the message each time
	if counter != old_water_count || ten_min_count == 0
		if counter<old_water_count
			old_water_count = counter
		end
		var change_count = counter  - old_water_count
		var l_per_min = (change_count / pulses_per_l) * 6.0  
		var water_litres = counter/ pulses_per_l
		old_water_count = counter
		var output_str = string.format("Total Count %d Watering Flow Pulses: %d LPM: %3.1f",counter,change_count,l_per_min)
		log(output_str)
		var mqtt_msg = json.dump({ "lpm":l_per_min,"Count":counter,"Change":change_count,"Litres":water_litres})
		flow_msg = json.load(mqtt_msg)
		mqtt.publish("stat/ShedIO/watering",mqtt_msg)	
	end
end


# start pump function for timing
def start_pump()
	tasmota.set_power(pump,true)
end

# stop pump
def stop_pump()
	tasmota.set_power(pump,false)
end

def close_valves()
	tasmota.set_power(front,false)
	tasmota.set_power(back,false)
end

# shut down the watering and log
def end_watering(cause)
    tasmota.set_timer(1000,stop_pump)
	tasmota.set_timer(2000,close_valves)
	log(cause)
	water_msg['stopcause'] = cause 
	mqtt.publish("result/ShedIO/watering",json.dump(water_msg))
end

# stop watering on timeout
def water_timeout()
	end_watering("Timeout Reached")	
	return true
end

# stop watering on high flow after 5min
def high_flow()
	water_msg['highflow'] = true
	return true
end
# stop watering on flow
def water_mgmt()
	var relays = tasmota.get_power()
	if relays[front] == true || relays[back] == true 
		# Start message only
		if water_msg.contains('endcount') 
			var endcount = water_msg['endcount']
			var actual = sensors['COUNTER']['C1']
			if endcount < actual
				print("Volume exceeded")
				end_watering("Flow Target Reached")	
			end

			var maxlpm = water_msg['maxlpm']
			var lpm = flow_msg['lpm']
			var highflow = water_msg['highflow']
			if  (maxlpm < lpm) && highflow
				end_watering("Stopped on high flow")
			end
		end
	else # if both valves are closed stop pump
		if relays[pump]
			tasmota.set_power(pump,false)
		end
	end
end
# '{"state": "start","area":"front","timeout":150,"totalLitres":2000, "maxlpm":24}'
def water_message(topic, idx, payload_s, payload_b)
	water_msg = json.load(payload_s)
	if water_msg['state'] == "start"
		water_msg.insert('endcount',water_msg['totalLitres']*pulses_per_l)
		water_msg.insert('highflow',false)
		water_msg.insert('stopcause', "In Progress" )
		tasmota.set_timer(water_msg['timeout']*60000,water_timeout)
		tasmota.set_timer(300000,high_flow)
		if water_msg['area'] == "front"
			tasmota.set_power(front,true)
			tasmota.set_timer(2000,start_pump)
		end
		if water_msg['area'] == "back"
			tasmota.set_power(back,true)
			tasmota.set_timer(2000,start_pump)
		end
		tasmota.cmd("COUNTER1 0")
		mqtt.publish("result/ShedIO/watering",json.dump(water_msg))
	else
		end_watering("Stop Requested")
	end
	return true
end
def subscribes()
  mqtt.subscribe("cmnd/water/control",water_message)
end

tasmota.add_rule("MQTT#Connected=1", subscribes)

def each_ten_sec()
	sensors=json.load(tasmota.read_sensors())
	water_flow()
	water_mgmt()
end
def each_minute()
	sensors=json.load(tasmota.read_sensors())
	tank_flow()
	shed_data()
end




tasmota.add_cron("*/10 * * * * *",each_ten_sec,"water_flow")
tasmota.add_cron("0 * * * * *", each_minute, "each_minute")

#######################################################################################	
