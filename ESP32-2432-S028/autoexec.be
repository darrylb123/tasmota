import string
import json
import persist
#- start LVGL and init environment -#
# Globals for speed control
var speedSP = 0.0
if persist.has("setpoint")
    speedSP = persist.setpoint
end
var speedCur = 0.0
# Speed limit in mode
# Limit high = 0
# Linit low = 1
var speedLimMode = 1
if persist.has("limit")
    speedLimMode = persist.limit
end
var speedEngaged = 0

# Load the modules
load("lvgl.be")
load("speedo.be")
