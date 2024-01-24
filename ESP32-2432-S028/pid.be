#pid.be
class PID
    var last_error, last_time, p_gain, i_gain, d_gain, i_error

	def init(p_gain, i_gain, d_gain, now)
		self.last_error = 0.0
		self.last_time = now
		self.p_gain = real(p_gain)
		self.i_gain = real(i_gain)
		self.d_gain = real(d_gain)
		self.i_error = 0.0
	end
	def Compute(measure, target, now)
		var dt = (now - self.last_time)

		# Error is what the PID alogithm acts upon to derive the output
		
		var error = target - measure

		# The proportional term takes the distance between current input and target
		# and uses this proportially (based on Kp) to control the ESC pulse width

		var p_error = error
	
		# The integral term sums the errors across many compute calls to allow for
		# external factors like wind speed and friction

		self.i_error += (error + self.last_error) * dt

		# The differential term accounts for the fact that as error approaches 0,
		# the output needs to be reduced proportionally to ensure factors such as
		# momentum do not cause overshoot.

		var d_error = (error - self.last_error) / dt


		# The overall output is the sum of the (P)roportional, (I)ntegral and (D)iffertial terms

		var p_output = self.p_gain * p_error
		var i_output = self.i_gain * self.i_error
		var d_output = self.d_gain * d_error

		# Store off last input for the next differential calculation and time for next integral calculation

		self.last_error = error
		self.last_time = now

		# Return the output, which has been tuned to be the increment / decrement in ESC PWM
		return p_output  + i_output + d_output
	end
end

