# Change Log

## 0.6.0
- Added QueueableSource:setVolume() method (thanks, pgimeno)
- Fixed documentation typo (thanks, tst2005)

## 0.5.0
- 8-bit audio support (thanks to miko for recommendation)
- Added Device:getBitDepth() method
- Device:new() is now typechecked properly
- Cleaned up typechecking code slightly
- Cleaned up documentation

## 0.4.3
- Fixed-size buffers are now larger, thanks to KittyCat@#openal for the recommendation.

## 0.4.2
- bufferCount is now honored when creating QueueableSource objects.

## 0.4.1
- Fixed version field being incorrect.
- Added QueueableSource:getFreeBufferCount()
- Added optional argument to QueueableSource constructor to specify number of buffers to use.
- Removed outdated demos and todo document

## 0.4.0
- "fast as possible" mode added for microphone input; uses a new variable buffer size.
	- Pass 0 as the third argument (sampleLength) to openDevice to enable this mode.
- Removed Device:getSoundData since it doesn't work for this new mode.

## 0.3.0
- QueueableSource object, created with microphone.newQueueableSource.
- Updated demos to use QueueableSource and promote the microphone-specific callback method.

## 0.2.4
- Functions now do typechecking on their arguments. They will return nil and an error message like usual.

## 0.2.3
- Updated documentation for core functions.

## 0.2.2
- Fixed data callbacks not passing the first parameter (the device) properly

## 0.2.1
- Moved Device functionality to separate file, cleaned up main code considerably
- Standardized file headers

## 0.2.0
- Added getVersion to retrieve version
- Documented all methods
- Fixed latency issues; sample length is now latency
- Added microphone.getDeviceList and microphone.getDefaultDeviceName
- Added todo.md document for future plans
- Noted in readme that linux is now tested

## 0.1.0
- Initial release