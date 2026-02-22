# Export Logs Extension for In-App Console

A Flutter plugin that adds log export functionality to the [in_app_console](https://pub.dev/packages/in_app_console) package. Export your app logs to a file with just one tap.

## What does it do?

This extension adds two actions to your in-app console:
- **Save as file** — writes all console logs to a `.txt` file via the native file picker dialog
- **Share** — shares the log file through the system share sheet

Each export includes timestamps, log levels, module labels, error messages, and stack traces.

## Screenshots
<img src="https://github.com/mduccc/in_app_console/blob/c3be19a99aca65235e0af6f7ad4cd3cafc1bf5b5/packages/iac_export_logs_ext/screenshots/screenshot.png?raw=true" width="45%"/>

## Register the extension

```dart
InAppConsole.instance.registerExtension(
  InAppConsoleExportLogsExtension(),
);
```
