# Export Logs Extension for In-App Console

A Flutter plugin that adds log export functionality to the [in_app_console](https://pub.dev/packages/in_app_console) package. Export your app logs to a file with just one tap.

## What does it do?

This extension adds an "Export Logs" button to your in-app console that lets you save all console logs to a text file

## Screenshots
<img src="https://github.com/mduccc/in_app_console/blob/main/iac_export_logs_ext/screenshots/simulator_screenshot_AD73AE3A-782D-4365-A581-4B166B1573F3.png?raw=true" width="45%"/>


## Register the extension

```dart
  // Register the export logs extension
  InAppConsole.instance.registerExtension(
    InAppConsoleExportLogsExtension(),
  );
```
