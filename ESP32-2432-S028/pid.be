#pid.be
class PID
    var last_error, last_time, p_gain, i_gain, d_gain, i_error, p_error, d_error, p_output, i_output, d_output, output , dt
    var measure, target

	def init(p_gain, i_gain, d_gain, now)
		self.last_error = 0.0
		self.last_time = now
		self.p_gain = real(p_gain)
		self.i_gain = real(i_gain)
		self.d_gain = real(d_gain)
		self.p_error = 0.0
		self.i_error = 0.0
		self.d_error = 0.0
		self.p_output = 0.0
		self.i_output = 0.0
		self.d_output = 0.0
	    
	end
	def Compute(measure, target, now)
		self.dt = real(now - self.last_time)/3600.0

		# Error is what the PID alogithm acts upon to derive the output
		
		var error = target - measure
		self.measure = measure
		self.target = target

		# The proportional term takes the distance between current input and target
		# and uses this proportionally (based on Kp) to control the ESC pulse width

		self.p_error = error
	
		# The integral term sums the errors across many compute calls to allow for
		# external factors like wind speed and friction

		self.i_error += (error + self.last_error) * self.dt

		# The differential term accounts for the fact that as error approaches 0,
		# the output needs to be reduced proportionally to ensure factors such as
		# momentum do not cause overshoot.

		self.d_error = (error - self.last_error) / self.dt


		# The overall output is the sum of the (P)roportional, (I)ntegral and (D)iffertial terms

		self.p_output = self.p_gain * self.p_error
		self.i_output = self.i_gain * self.i_error
		self.d_output = self.d_gain * self.d_error

		# Store off last input for the next differential calculation and time for next integral calculation

		self.last_error = error
		self.last_time = now

		# Return the output, which has been tuned to be the increment / decrement in ESC PWM
		self.output = self.p_output  + self.i_output + self.d_output
		return self.output
	end
	def SetParams()
	    var tasmem = tasmota.cmd("mem")
	    self.p_gain = number(tasmem['Mem1'])
	    self.i_gain = number(tasmem['Mem2'])
	    self.d_gain = number(tasmem['Mem3'])
	end
	
	def Print()
	    print(string.format("Measure: %f Target:%f DT: %f Error: %f %f %f Outputs: %f %f %f Sum: %f",self.measure,self.target,self.dt,self.p_error,self.i_error,self.d_error,self.p_output,self.i_output,self.d_output,self.output))
	end
end

