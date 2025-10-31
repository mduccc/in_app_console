# Log Statistics Extension for In-App Console

A Flutter plugin that adds log statistics and analytics functionality to the [in_app_console](https://pub.dev/packages/in_app_console) package. View comprehensive log analytics and breakdowns directly in your in-app console.

## What does it do?

This extension displays real-time log statistics including total log counts, breakdowns by log type (info, warning, error), and logs grouped by module. It provides instant visibility into your app's logging patterns and helps identify issues quickly.

## Screenshots

<img src="https://raw.githubusercontent.com/mduccc/in_app_console/3f59d05ea85afb5cb1c618452e9dee71f6eb1bfb/iac_statistics_ext/screenshots/screenshot.png" width="45%"/>

## Register the extension

```dart
  // Register the log statistics extension
  InAppConsole.instance.registerExtension(
    LogStatisticsExtension(),
  );
```
