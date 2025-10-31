# Export Logs Extension for In-App Console

A Flutter plugin that adds log export functionality to the [in_app_console](https://pub.dev/packages/in_app_console) package. Export your app logs to a file with just one tap.

## What does it do?

This extension adds an "Export Logs" button to your in-app console that lets you save all console logs to a text file

## Screenshots
<img src="https://raw.githubusercontent.com/mduccc/in_app_console/170ee66c27ef65a9db892cbfb554023941f784ae/iac_export_logs_ext/screenshots/screenshot.png" width="45%"/>


## Register the extension

```dart
  // Register the export logs extension
  InAppConsole.instance.registerExtension(
    InAppConsoleExportLogsExtension(),
  );
```
