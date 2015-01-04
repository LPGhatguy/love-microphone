--[[
	Records a user's microphone and echos it back to them.

	This version uses vanilla LOVE sources, which is not ideal.
]]

-- Alias love-microphone as microphone
local microphone = require("love-microphone")

local device

function love.load()
	-- Report the name of the microphone we're going to use
	print("Opening microphone:", microphone.getDefaultDeviceName())
	
	-- Open the default microphone device with default quality and 100ms latency
	device = microphone.openDevice(nil, nil, 0.1)

	-- Register our local callback
	device:setDataCallback(function(device, data)
		love.audio.newSource(data):play()
	end)

	-- Start recording
	device:start()
end

-- Add microphone polling to our update loop
function love.update(dt)
	device:poll()
end