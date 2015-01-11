--[[
	love-microphone
	init.lua

	Main file for love-microphone, creates the microphone namespace.
]]

local ffi = require("ffi")
local al = require("love-microphone.openal")
local Device = require("love-microphone.Device")
local QueueableSource = require("love-microphone.QueueableSource")

local microphone = {
	_devices = {}
}

--[[
	(int major, int minor, int revision) microphone.getVersion()

	Returns the version of love-microphone currently running.
]]
function microphone.getVersion()
	return 0, 4, 3
end

--[[
	void microphone.import()

	Imports the module into love.microphone. Not always desired.
]]
function microphone.import()
	love.microphone = microphone
end

--[[
	QueueableSource microphone.newQueueableSource()

	Creates a new QueueableSource object to play lists of SoundData.
]]
function microphone.newQueueableSource(bufferCount)
	return QueueableSource:new(bufferCount)
end

--[[
	Device microphone.openDevice(string? deviceName, [int frequency, float sampleLength])
		deviceName: The device to open. Specify nil to get the default device.
		frequency: The sample rate in Hz to open the source at; defaults to 22050 Hz.
		sampleLength: How long in seconds a sample should be; defaults to 0.5 s. Directly affects latency.

	Open a new microphone device or returns an existing opened device
]]
function microphone.openDevice(name, frequency, sampleLength)
	if (name and type(name) ~= "string") then
		return nil, "Invalid argument #1: Device name must be of type 'string' if given."
	end

	if (frequency and type(frequency) ~= "number" and frequency % 1 == 0) then
		return nil, "Invalid argument #2: Frequency must of type 'number' and an integer if given."
	end

	if (sampleLength and type(sampleLength) ~= "number") then
		return nil, "Invalid argument #3: Sample length must be of type 'number' if given."
	end

	if (microphone._devices[name]) then
		return microphone._devices[name]
	end

	local device = Device:new(name, frequency, sampleLength)

	microphone._devices[name or microphone.getDefaultDeviceName()] = device

	return device
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