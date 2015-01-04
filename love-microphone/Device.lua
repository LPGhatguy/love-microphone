--[[
	love-microphone
	Device.lua

	Holds methods for the Device class to be used by the love-microphone core.
]]

local ffi = require("ffi")
local al = require("love-microphone.openal")

local Device = {}

--[[
	Device Device:new(string deviceName, int frequency, float sampleLength)
		deviceName: The device to open. Specify nil to get the default device.
		frequency: The sample rate in Hz to open the source at; defaults to 22050 Hz.
		sampleLength: How long in seconds a sample should be; defaults to 0.5 s. Directly affects latency.

	Creates a new Device object corresponding to the given microphone.
	Will not check for duplicate handles on the same device, have care.
]]
function Device:new(name, frequency, sampleLength)
	frequency = frequency or 22050
	sampleLength = sampleLength or 0.5

	-- Convert sampleLength to be in terms of audio samples
	sampleSize = math.floor(frequency * sampleLength)

	local alcdevice = al.alcCaptureOpenDevice(name, frequency, al.AL_FORMAT_MONO16, sampleSize)

	-- Create our actual microphone device object
	local internal = {}

	for key, value in pairs(Device) do
		if (key ~= "new") then
			internal[key] = value
		end
	end

	-- Set some private fields
	internal._sampleSize = sampleSize
	internal._alcdevice = alcdevice
	internal._name = name
	internal._valid = true
	internal._samplesIn = ffi.new("ALCint[1]")
	internal._buffer = love.sound.newSoundData(sampleSize, frequency, 16, 1)
	internal._dataCallback = nil

	-- Wrap everything in a convenient userdata
	local wrap = newproxy(true)
	local meta = getmetatable(wrap)
	meta.__index = internal
	meta.__newindex = internal
	meta.__gc = internal.close

	return wrap
end

--[[
	void device:setDataCallback(void callback(Device device, SoundData data)?)
		callback: The function to receive the data

	Sets the function that this microphone will call when it receives a buffer full of data.
	Send no arguments to remove the current callback.
	By default, tries to call love.microphonedata.
]]
function Device:setDataCallback(callback)
	if (callback and type(callback) ~= "function") then
		return nil, "Invalid argument #1: Callback must be of type 'function' if given."
	end

	self._dataCallback = callback
end

--[[
	bool device:start()

	Starts recording audio with this microphone.
	Returns true if successful.
]]
function Device:start()
	if (not self._valid) then
		return false, "Device is closed."
	end

	al.alcCaptureStart(self._alcdevice)

	return true
end

--[[
	bool device:stop()

	Stops recording audio with this microphone.
	Returns true if successful.
]]
function Device:stop()
	if (not self._valid) then
		return false, "Device is closed."
	end

	al.alcCaptureStop(self._alcdevice)

	return true
end

--[[
	bool device:close()

	Closes the microphone object and stops it from being used.
	Returns true if successful.
]]
function Device:close()
	if (not self._valid) then
		return false, "Device already closed."
	end

	al.alcCaptureStop(self._alcdevice)
	al.alcCaptureCloseDevice(self._alcdevice)

	self._valid = false
	microphone._devices[self._name] = nil

	return true
end

--[[
	SoundData device:getSoundData()

	Returns the internal SoundData used for storing the audio buffer.
	Can be altered every time device:poll() is called, copy it if you need to analyze it.
]]
function Device:getSoundData()
	return self._buffer
end

--[[
	void device:poll()

	Polls the microphone for data, updates the buffer, and calls any registered callbacks if there is data.
]]
function Device:poll()
	al.alcGetIntegerv(self._alcdevice, al.ALC_CAPTURE_SAMPLES, 1, self._samplesIn)

	local samplesIn = self._samplesIn[0]
	if (samplesIn >= self._sampleSize) then
		al.alcCaptureSamples(self._alcdevice, self._buffer:getPointer(), self._sampleSize)

		if (self._dataCallback) then
			self:_dataCallback(self._buffer)
		elseif (love.microphonedata) then
			love.microphonedata(self, self._buffer)
		end
	end
end

return Device