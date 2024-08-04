# Speed measuring and control
import math
class speedo
    var spInt, spIntMem, stopped, pin22, count, throttle, demand, actual, engagedMem, speed, speedFilter
    static var tyre_circum = 1.99  / 6 # 6 magnets
    static var p_gain = 5
    static var i_gain = 2
    static var d_gain = 0
    static var pwm_out = 27
    static var wheel = 22
    static var limitMode = 5
    static var cruiseMode = 18
    static var raiseSP = 19
    static var lowerSP = 23
    
    var pid
    # Calculate the speed for one rotation based on how many milliseconds
    # tyre 25x8x12 diameter is 0.635m or 1.99m circumferference
    # 1000 millis for 1 rotation is 1.99m/sec or 7.181km/h
    # requires COUNTERTYPE 1 so that counter is microsecond duration
    
    # If speed control not engaged, make the output = throttle position
    # if engaged and limit mode is Limit, use throttle position as output until the speed exceeds the setpoint then control the speed. IE limit maximum speed.
    # if engaged and cruise mode, limit minimum speed throttle takes over above the speed setpoint
    def every_100ms()
        var position

        if (speedEngaged < 2)
            self.actual = self.throttle
        else
            if speedLimMode == 0  # Limit Speed mode
            	speedEngaged = 2
                if ( self.throttle < self.demand )
                    self.actual = self.throttle
                else
                    self.actual = self.demand
                end
            elif speedLimMode == 1  # Cruise Speed mode
            	speedEngaged = 1
                if ( self.throttle > self.demand )
                    self.actual = self.throttle
                else
                    self.actual = self.demand
                end
            end
        end
	self.set_actual(self.actual)
    end
    # Not used
    def fast_loop()
    # called at each iteration (200/sec), and needs to be registered separately and explicitly
        # look for falling transition on proximity switch
        if !gpio.digital_read(22)
            if self.pin22
                self.pin22 = false
                self.spInt = tasmota.millis() - self.count
                self.count = tasmota.millis()
            end
        else
            self.pin22 = true
        end
    end
    def every_250ms()
    	# read the speed counter and ignore outliers
        var elapsed = gpio.counter_read(0) / 1000 # number of microseconds since last pulse.
       	    self.spInt = elapsed
        # end
        # 
        # if no update to speedcount in 5 seconds
        # print(self.spIntMem, self.spInt, self.stopped )
        
        if self.spIntMem == self.spInt 
            self.stopped = self.stopped - 1
            if self.stopped == 0
                self.stopped = 10
                stat_line.set_text("Speed: 0")
                self.speed = 0.0
            end
        else
            # calculate speed and display
            self.spIntMem = self.spInt
            self.stopped = 5
            if self.spInt > 0
                self.speedFilter += self.tyre_circum / ( self.spInt /1000.0 ) * 3.6
                var readspeed = self.speedFilter / 5
                self.speedFilter -= readspeed
                if math.abs(self.speed - readspeed) < 10 # Ignore pulses < 0.1 seconds
                     self.speed = readspeed
                     stat_line.set_text(string.format("Speed: %4.1f",self.speed))
                end
            end
        end
    end
    # main speed control loop
    def every_second()
	var limit = !gpio.digital_read(self.limitMode)
	var cruise = !gpio.digital_read(self.cruiseMode)
	var up = !gpio.digital_read(self.raiseSP)
	var down = !gpio.digital_read(self.lowerSP)
	if up
		speedSP += 0.5
		set_line.set_text(string.format("Setpoint: %4.1f",speedSP))
		persist.setpoint = speedSP
		persist.save()
	elif down
		speedSP -= 0.5
		set_line.set_text(string.format("Setpoint: %4.1f",speedSP))
		persist.setpoint = speedSP
		persist.save()
	end
	if limit
		speedLimMode = 0
	elif cruise
		speedLimMode = 1
	else
		speedLimMode = 2
	end
	
	ddlist.set_selected(speedLimMode)
	if limit || cruise
		speedEngaged = 1
	else
		speedEngaged = 0
	end
	
	colourEngaged ()
        # Throttle must be held partly open to maintain cruise control once enabled
        if (speedEngaged == 2) && ((self.throttle < 500) || (self.speed < 1.0))
            speedEngaged = 1
            self.engagedMem = false
            colourEngaged()
        end
            
        
        if speedEngaged &&  ( (self.speed > (speedSP-2)) || speedLimMode == 0 )
            speedEngaged = 2
            colourEngaged()
            if !self.engagedMem
                self.pid.iReset() # Reset integral to 0
                self.engagedMem = true
            end
        end
        if (speedEngaged == 2)
            var outp = self.actual + int(self.pid.Compute(self.speed,speedSP,tasmota.millis()))
            if outp < 0
                outp = 0
            end
            self.demand = outp
            self.pid.Print()
        end
        print(string.format("Speed %3.1f Throttle: %d Demand: %d Actual: %d",self.speed,self.throttle, self.demand, self.actual))
        # print("Current Interval",self.spInt)
    end


    def set_throttle(value)
        var closed = 655
        var full = 2565 - closed
        self.throttle = int(((real(value) - closed) / full) *1024)
        if self.throttle > 1023
        	self.throttle = 1023
        end
        # print("Output ", self.throttle)
    end
    def set_actual(value)
    	var closed = 377
    	var full = 1023 - closed
    	var volts = 0
    	volts = int(((real(value) * 0.9 ) + closed ))
        if volts > 1023
        	volts = 1023
        end
    	gpio.set_pwm(self.pwm_out,volts)
    end
    def SetParams()
    self.pid.SetParams()
    end
    
    def init()
        self.spInt = 0
        self.count = 0
        self.pin22 = false
        self.stopped = 5
        self.throttle = 377
        self.demand = 0
        self.actual = 377
        self.speed = 0.0
        self.speedFilter = 0
        self.engagedMem = false
        self.pid = PID(self.p_gain,self.i_gain,self.d_gain,tasmota.millis())
        gpio.pin_mode(self.wheel,gpio.INPUT_PULLUP)
        gpio.pin_mode(self.limitMode,gpio.INPUT_PULLUP)
        gpio.pin_mode(self.cruiseMode,gpio.INPUT_PULLUP)
        gpio.pin_mode(self.lowerSP,gpio.INPUT_PULLUP)
        gpio.pin_mode(self.raiseSP,gpio.INPUT_PULLUP)
        gpio.set_pwm(self.pwm_out,0)
        tasmota.add_driver(self) 
        tasmota.cmd("pwmfrequency 40000")
        tasmota.cmd("counter1 0")
        # register fast_loop method
        # tasmota.add_fast_loop(/-> self.fast_loop())
        self.pid.SetParams()
    end
end

var sP= speedo()

def read_throttle(value)
    sP.set_throttle(value)
end
tasmota.add_rule("ANALOG#A1",read_throttle)

def setp()
    sP.SetParams()
end
tasmota.add_rule("MEM1",setp)
tasmota.add_rule("MEM2",setp)
tasmota.add_rule("MEM3",setp)

