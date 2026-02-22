# Device Info Extension for In-App Console

A Flutter plugin that adds device information display to the [in_app_console](https://pub.dev/packages/in_app_console) package. View hardware and system specs directly in your in-app console.

## What does it do?

This extension displays real-time device information including platform, OS version, device model, manufacturer, CPU architecture, and total RAM. Supports Android and iOS.

## Register the extension

```dart
InAppConsole.instance.registerExtension(
  IacDeviceInfoExtension(),
);
```
