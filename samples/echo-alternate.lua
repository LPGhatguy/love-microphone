--[[
	Records a user's microphone and echos it back to them.

	This is an alternate form that uses a microphone-specific callback.
	For most applications using multiple microphones, this is probably better.
]]

-- Alias love-microphone as love.microphone
require("love-microphone").import()

local device

function love.load()
	-- Open the microphone device
	device = love.microphone.openDevice()

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