# Change Log

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