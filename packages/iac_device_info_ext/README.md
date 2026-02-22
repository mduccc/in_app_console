# Device Info Extension for In-App Console

A Flutter plugin that adds device information display to the [in_app_console](https://pub.dev/packages/in_app_console) package. View hardware and system specs directly in your in-app console.

## What does it do?

This extension displays real-time device information including platform, OS version, device model, manufacturer, CPU architecture, and total RAM. Supports Android and iOS.

## Screenshot

<img src="https://raw.githubusercontent.com/mduccc/in_app_console/2c6a6c1aff170e0408768bbdea0103dbbb49dd80/packages/iac_device_info_ext/screenshot/screenshot.png" width=35%> 

## Register the extension

```dart
InAppConsole.instance.registerExtension(
  IacDeviceInfoExtension(),
);
```
