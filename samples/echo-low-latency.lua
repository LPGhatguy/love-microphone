--[[
	Records a user's microphone and echos it back to them.

	This variant uses "fast as possible mode" to get a lower latency audio stream.
]]

-- Alias love-microphone as microphone
local microphone = require("love-microphone")
local device, source

function love.load()
	-- Report the name of the microphone we're going to use
	print("Opening microphone:", microphone.getDefaultDeviceName())

	-- Open the default microphone device with default quality and as little latency as possible.
	device = microphone.openDevice(nil, nil, 0)

	-- Create a new QueueableSource to echo our audio
	source = microphone.newQueueableSource()

	-- Register our local callback
	device:setDataCallback(function(device, data)
		source:queue(data)
		source:play()
	end)

	-- Start recording
	device:start()
end

-- Add microphone polling to our update loop
function love.update()
	device:poll()
end