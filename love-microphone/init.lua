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

local CAPTURE_SIZE = 2048

local device = {}

local function newDevice(name, frequency, alcdevice)
	name = name or "_DEFAULT"

	local internal = {}

	for key, value in pairs(device) do
		internal[key] = value
	end

	-- constructor logic
	internal._alcdevice = alcdevice
	internal._name = name
	internal._valid = true
	internal._samplesIn = ffi.new("ALCint[1]")
	internal._buffer = love.sound.newSoundData(CAPTURE_SIZE * 2, frequency, 16, 1)
	internal._dataCallback = nil

	local wrap = newproxy(true)
	local meta = getmetatable(wrap)
	meta.__index = internal
	meta.__newindex = internal
	meta.__gc = internal.close

	return wrap
end

function device:setDataCallback(callback)
	self._dataCallback = callback
end

function device:start()
	if (not self._valid) then
		return false, "Device is closed."
	end

	al.alcCaptureStart(self._alcdevice)

	return true
end

function device:stop()
	if (not self._valid) then
		return false, "Device is closed."
	end

	al.alcCaptureStop(self._alcdevice)

	return true
end

function device:close()
	if (not self._valid) then
		return false, "Device already closed."
	end

	al.alcCaptureStop(self._alcdevice)
	al.alcCaptureCloseDevice(self._alcdevice)

	self._valid = false
	microphone._devices[self._name] = nil

	return true
end

function device:getSoundData()
	return self._buffer
end

function device:poll()
	al.alcGetIntegerv(self._alcdevice, al.ALC_CAPTURE_SAMPLES, 1, self._samplesIn)

	local samplesIn = self._samplesIn[0]
	if (samplesIn > CAPTURE_SIZE) then
		al.alcCaptureSamples(self._alcdevice, self._buffer:getPointer(), CAPTURE_SIZE)

		if (self._dataCallback) then
			self._dataCallback(device, self._buffer)
		elseif (love.microphonedata) then
			love.microphonedata(device, self._buffer)
		end
	end
end

--[[
	microphone.import()

	Sets the module as love.microphone. Not always desired.
]]
function microphone.import()
	love.microphone = microphone
end

--[[
	microphone.openDevice(string? deviceName, int frequency, float sampleLength)
		deviceName: The device to open. Specify nil to get the default device.
		frequency: The sample rate in Hz to open the source at; defaults to 22050 Hz.
		sampleLength: How long in seconds a sample should be; defaults to 0.5 s.

	Open a new microphone device or returns an existing opened device
]]
function microphone.openDevice(name, frequency, sampleLength)
	if (microphone._devices[name]) then
		return microphone._devices[name]
	end

	frequency = frequency or 22050
	sampleLength = sampleLength or 0.5

	sampleSize = math.ceil(frequency * sampleLength)

	local pInputDevice = al.alcCaptureOpenDevice(name, frequency, al.AL_FORMAT_MONO16, sampleSize)

	local object = newDevice(name, frequency, pInputDevice)

	return object
end

return microphone