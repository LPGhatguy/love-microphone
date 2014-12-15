--[[
	Records a user's microphone and echos it back to them.
]]

-- Alias love-microphone as microphone
local microphone = require("love-microphone")

local device

function love.load()
	-- Report the name of the microphone we're going to use
	print("Opening microphone:", microphone.getDefaultDeviceName())

	-- Open the default microphone device with default quality and 100ms latency
	device = microphone.openDevice(nil, nil, 0.1)

	-- Start recording
	device:start()
end

-- Whenever we get new data
function love.microphonedata(device, data)
	-- Play it in a new source
	love.audio.newSource(data):play()

	-- This will hopefully be more optimal in the future
end

-- Add microphone polling to our update loop
function love.update(dt)
	device:poll()
end