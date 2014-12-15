--[[
	Records a user's microphone and echos it back to them.
]]

-- Alias love-microphone as love.microphone
require("love-microphone").import()

local device

function love.load()
	-- Open the microphone device
	device = love.microphone.openDevice()

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