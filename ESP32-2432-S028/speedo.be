# Speed measuring and control

class speedo
    var spInt, spIntMem, stopped, pin22, count, throttle, demand, actual
    static var tyre_circum = 1.99
    static var p_gain = 5
    static var i_gain = 2
    static var d_gain = 0
    static var pwm_out =27
    static var wheel = 22
    
    var pid
    # Calculate the speed for one rotation based on how many milliseconds
    # tyre 25x8x12 diameter is 0.635m or 1.99m circumferference
    # 1000 millis for 1 rotation is 1.99m/sec or 7.181km/h
    # requires COUNTERTYPE 1 so that counter is microsecond duration
    
    def every_250ms()
        var position
        if (speedEngaged < 2)
            self.actual = self.throttle
        else
            if speedLimMode == 0  # Limit Speed mode
                if ( self.throttle < self.demand )
                    self.actual = self.throttle
                else
                    self.actual = self.demand
                end
            elif speedLimMode == 1  # Cruise Speed mode
                if ( self.throttle > self.demand )
                    self.actual = self.throttle
                else
                    self.actual = self.demand
                end
            end
        end
        gpio.set_pwm(self.pwm_out,self.actual)
    end
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
    def every_second()
        var speed = 0.0
        # if no update to speedcount in 5 seconds
        # print(self.spIntMem, self.spInt, self.stopped )
        if self.spIntMem == self.spInt
            self.stopped = self.stopped - 1
            if self.stopped == 0
                self.stopped = 5
                stat_line.set_text("Speed: 0")
                speed = 0.0
            end
        else
            self.spIntMem = self.spInt
            self.stopped = 5
            if self.spInt > 0
                speed = self.tyre_circum / ( self.spInt /1000.0 ) * 3.6
                stat_line.set_text(string.format("Speed: %4.1f",speed))
            end
        end
        # Throttle must be held partly open to maintain cruise control once enabled
        if (speedEngaged == 2) && ((self.throttle < 10) || (speed < 1.0))
            speedEngaged = 1
            colourEngaged()
        end
            
        
        if speedEngaged &&  ( (speed > (speedSP-2)) || speedLimMode == 0 )
            speedEngaged = 2
            colourEngaged()
            self.pid.iReset() # Reset integral to 0
        end
        if (speedEngaged == 2)
            var outp = self.actual + int(self.pid.Compute(speed,speedSP,tasmota.millis()))
            if outp < 0
                outp = 0
            end
            self.demand = outp
            self.pid.Print()
        end
        print(string.format("Speed %3.1f Throttle: %d Demand: %d Actual: %d",speed,self.throttle, self.demand, self.actual))
        # print("Current Interval",self.spInt)
    end


    def set_throttle(value)
        var closed = 176.0
        var full = 3071.0
        self.throttle = int(((real(value) - closed) / full) *1024)
        # print("Output ", self.throttle)
    end
    def SetParams()
    self.pid.SetParams()
    end
    
    def init()
        self.spInt = 0
        self.count = 0
        self.pin22 = false
        self.stopped = 5
        self.throttle = 0
        self.demand = 0
        self.pid = PID(self.p_gain,self.i_gain,self.d_gain,tasmota.millis())
        gpio.pin_mode(self.wheel,gpio.INPUT_PULLUP)
        gpio.set_pwm(self.pwm_out,0)
        tasmota.add_driver(self) 
        # register fast_loop method
        tasmota.add_fast_loop(/-> self.fast_loop())
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
tasmota.add_rule("mem",setp)



