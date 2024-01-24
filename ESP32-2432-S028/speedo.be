# Speed measuring and control

class speedo
    var spInt, spIntMem, stopped, pin22, count
    static var tyre_circum = 1.99
    static var p_gain = 50
    static var i_gain = 1
    static var d_gain = 1
    static var pwm_out =27
    static var wheel = 22
    var pid
    # Calculate the speed for one rotation based on how many milliseconds
    # tyre 25x8x12 diameter is 0.635m or 1.99m circumferference
    # 1000 millis for 1 rotation is 1.99m/sec or 7.181km/h
    def every_second()
        var speed = 0.0
        # if no update to speedcount in 5 seconds
 #       print(self.spIntMem, self.spInt, self.stopped )
        if self.spIntMem == self.spInt
            self.stopped = self.stopped - 1
            if self.stopped == 0
                self.stopped = 5
                stat_line.set_text("Speed: 0")
            end
        else
            self.spIntMem = self.spInt
            self.stopped = 5
            if self.spInt > 0
                speed = self.tyre_circum / ( self.spInt /1000.0 ) * 3.6
                stat_line.set_text(string.format("Speed: %4.1f",speed))
            end
        end
        if (speedEngaged)
            gpio.set_pwm(self.pwm_out,int(self.pid.Compute(speedSP,speed,tasmota.millis())))
        else
            gpio.set_pwm(self.pwm_out,0)
        end
        
        # print("Current Interval",self.spInt)
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

    def init()
        self.spInt = 0
        self.count = 0
        self.pin22 = false
        self.stopped = 5
        self.pid = PID(self.p_gain,self.i_gain,self.d_gain,tasmota.millis())
        gpio.pin_mode(self.wheel,gpio.INPUT_PULLUP)
        gpio.set_pwm(self.pwm_out,0)
        tasmota.add_driver(self) 
        # register fast_loop method
        tasmota.add_fast_loop(/-> self.fast_loop())
    end
end
speedo()



