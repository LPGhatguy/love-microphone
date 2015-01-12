--[[
	love-microphone
	Device.lua

	Holds methods for the Device class to be used by the love-microphone core.
]]

local ffi = require("ffi")
local al = require("love-microphone.openal")

local Device = {}
local formats = {
	[8] = al.AL_FORMAT_MONO8,
	[16] = al.AL_FORMAT_MONO16
}

--[[
	Device Device:new(string? deviceName, [int frequency, float sampleLength, uint format])
		deviceName: The device to open. Specify nil to get the default device.
		frequency: The sample rate in Hz to open the source at; defaults to 22050 Hz.
		sampleLength: How long in seconds a sample should be; defaults to 0.5 s. Directly affects latency.
		format: How many bits per sample; defaults to 16.

	Creates a new Device object corresponding to the given microphone.
	Will not check for duplicate handles on the same device, have care.
]]
function Device:new(name, frequency, sampleLength, format)
	if (name ~= nil and type(name) ~= "string") then
		return nil, "Invalid argument #1: Device name must be of type 'string' if given."
	end

	if (frequency ~= nil and (type(frequency) ~= "number" or frequency % 1 ~= 0)) then
		return nil, "Invalid argument #2: Frequency must of type 'number' and an integer if given."
	end

	if (sampleLength ~= nil and type(sampleLength) ~= "number") then
		return nil, "Invalid argument #3: Sample length must be of type 'number' if given."
	end

	if (format ~= nil and (type(format) ~= "number" or format % 1 ~= 0)) then
		return nil, "Invalid argument #4: Format must be of type 'number' and an integer if given."
	end

	frequency = frequency or 22050
	sampleLength = sampleLength or 0.5
	format = format or 16

	local fastAsPossible = false

	if (sampleLength == 0) then
		sampleLength = 0.1
		fastAsPossible = true
	end

	local alFormat = formats[format]

	if (not alFormat) then
		return nil, "Invalid argument #4: Format must be a valid OpenAL bit depth (8 or 16) if given."
	end

	-- Convert sampleLength to be in terms of audio samples
	sampleSize = math.floor(frequency * sampleLength)

	local alcdevice = al.alcCaptureOpenDevice(name, frequency, alFormat, sampleSize * 2)

	-- Create our actual microphone device object
	local internal = {}

	for key, value in pairs(Device) do
		if (key ~= "new") then
			internal[key] = value
		end
	end

	-- Set some private fields
	internal._sampleSize = sampleSize

	-- Samples should be read as quickly as possible!
	if (fastAsPossible) then
		internal._fastAsPossible = true
		internal._sampleSize = nil
	else
		-- We can only use an internal buffer if we have fixed buffer sizing.
		internal._buffer = love.sound.newSoundData(sampleSize, frequency, format, 1)
	end

	internal._alcdevice = alcdevice
	internal._format = format
	internal._alformat = alFormat
	internal._name = name
	internal._valid = true
	internal._samplesIn = ffi.new("ALCint[1]")
	internal._frequency = frequency
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
	void Device:setDataCallback(void callback(Device device, SoundData data)?)
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
	bool Device:start()

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
	bool Device:stop()

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
	bool Device:close()

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
	void Device:poll()

	Polls the microphone for data, updates the buffer, and calls any registered callbacks if there is data.
]]
function Device:poll()
	al.alcGetIntegerv(self._alcdevice, al.ALC_CAPTURE_SAMPLES, 1, self._samplesIn)

	-- fastAsPossible requires variable buffer sizing; we can't reuse the internal buffer.
	local samplesIn = self._samplesIn[0]
	if (self._fastAsPossible) then
		if (samplesIn == 0) then
			return
		end

		local samples = samplesIn

		local buffer = love.sound.newSoundData(samples, self._frequency, self._format, 1)
		al.alcCaptureSamples(self._alcdevice, buffer:getPointer(), samples)

		if (self._dataCallback) then
			self:_dataCallback(buffer)
		elseif (love.microphonedata) then
			love.microphonedata(self, buffer)
		end
	elseif (samplesIn >= self._sampleSize) then
		local samples = self._sampleSize
		local buffer

		local buffer = self._buffer
		al.alcCaptureSamples(self._alcdevice, buffer:getPointer(), samples)

		if (self._dataCallback) then
			self:_dataCallback(buffer)
		elseif (love.microphonedata) then
			love.microphonedata(self, buffer)
		end
	end
end

--[[
	uint Device:getBitDepth()

	Returns the bit depth of the microphone.
]]
function Device:getBitDepth()
	return self._format
end

return Device