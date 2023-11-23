# Speed measuring and control

class speedo
    var spInt, pin22, count
    def every_second()
        # called every second via normal way
        stat_line.set_text(string.format("Speed: %4.1f",self.spInt))
        #   print("Current Interval",self.spInt)
    end
    def print_int()
        print("Current Interval",self.spInt)
    end
    def fast_loop()
    # called at each iteration, and needs to be registered separately and explicitly
        self.count  = self.count +1
        # look for falling transition on proximity switch
        if !gpio.digital_read(22)
            if self.pin22
                self.pin22 = false
                self.spInt = self.count
                self.count = 0
            end
        else
            self.pin22 = true
        end
    end

    def init()
        self.spInt = 0
        self.count = 0
        self.pin22 = false
        tasmota.add_driver(self) 
        # register fast_loop method
        tasmota.add_fast_loop(/-> self.fast_loop())
    end
end

speedo()



