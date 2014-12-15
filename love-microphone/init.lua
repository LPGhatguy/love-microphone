--[[
	love.microphone
	init.lua

	Requires LuaJIT
]]

local al = require("love-microphone.openal")
local ffi = require("ffi")
local microphone = {
	_devices = {}
}

--[[
	(int major, int minor, int revision) microphone.getVersion()

	Returns the version of love-microphone currently running
]]
function microphone.getVersion()
	return 0, 2, 0
end

-- Microphone device class
local Device = {}

--[[
	void device:setDataCallback(void callback(Device device, SoundData data))
		callback: The function to receive the data

	Sets the function that this microphone will call when it receives a buffer full of data.
	By default, tries to call love.microphonedata.
]]
function Device:setDataCallback(callback)
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
			self._dataCallback(device, self._buffer)
		elseif (love.microphonedata) then
			love.microphonedata(device, self._buffer)
		end
	end
end

--[[
	void microphone.import()

	Sets the module as love.microphone. Not always desired.
]]
function microphone.import()
	love.microphone = microphone
end

--[[
	Device microphone.openDevice(string? deviceName, int frequency, float sampleLength)
		deviceName: The device to open. Specify nil to get the default device.
		frequency: The sample rate in Hz to open the source at; defaults to 22050 Hz.
		sampleLength: How long in seconds a sample should be; defaults to 0.5 s. Directly affects latency.

	Open a new microphone device or returns an existing opened device
]]
function microphone.openDevice(name, frequency, sampleLength)
	if (microphone._devices[name]) then
		return microphone._devices[name]
	end

	frequency = frequency or 22050
	sampleLength = sampleLength or 0.5

	-- Convert sampleLength to be in terms of audio samples
	sampleSize = math.floor(frequency * sampleLength)

	local alcdevice = al.alcCaptureOpenDevice(name, frequency, al.AL_FORMAT_MONO16, sampleSize)

	-- Create our actual microphone device object
	local internal = {}

	for key, value in pairs(Device) do
		internal[key] = value
	end

	-- Set some private fields
	internal._sampleSize = sampleSize
	internal._alcdevice = alcdevice
	internal._name = name or "_DEFAULT"
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
	string[] microphone.getDeviceList()

	Returns a list of microphones on the system.
]]
function microphone.getDeviceList()
	local pDeviceList = al.alcGetString(nil, al.ALC_CAPTURE_DEVICE_SPECIFIER)
	local list = {}

	while (pDeviceList[0] ~= 0) do
		local str = ffi.string(pDeviceList)
		pDeviceList = pDeviceList + #str + 1

		table.insert(list, str)
	end

	return list
end

--[[
	string microphone.getDefaultDeviceName()

	Returns the name of the default microphone.
]]
function microphone.getDefaultDeviceName()
	return ffi.string(al.alcGetString(nil, al.ALC_CAPTURE_DEFAULT_DEVICE_SPECIFIER))
end

return microphone