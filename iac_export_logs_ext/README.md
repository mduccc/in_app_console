# iac_export_logs_ext

An extension for the `in_app_console` package that provides log export functionality with platform-specific implementations.

## Features

- **Export logs to file**: Save console logs to a text file
- **iOS Native Share**: Uses native method channels with LinkPresentation for sharing on iOS
- **Android Direct Save**: Saves logs directly to external storage on Android
- **Extension Architecture**: Implements the `InAppConsoleExtension` interface

## Platform Support

- ✅ iOS (using UIActivityViewController with LinkPresentation)
- ✅ Android (direct file save to external storage)
- ⚠️ Desktop platforms (uses downloads directory)

## Implementation Details

### iOS
On iOS, the extension:
1. Writes log content to a file in the temporary directory
2. Passes the file path to native code via method channel
3. Native code presents the iOS share sheet (UIActivityViewController)
4. Uses LinkPresentation framework for rich sharing experience
5. Supports iPad with proper popover presentation
6. Returns boolean indicating success/completion

### Android
On Android, logs are saved directly to the external storage directory.

## Usage

```dart
import 'package:iac_export_logs_ext/iac_export_logs_ext.dart';
import 'package:in_app_console/in_app_console.dart';

// Register the extension
InAppConsole.instance.registerExtension(
  InAppConsoleExportLogsExtension(),
);
```

## Technical Architecture

The package follows Flutter's plugin architecture with:
- **Platform Interface** (`iac_export_logs_ext_platform_interface.dart`): Abstract interface defining `shareFile(filePath)` method
- **Method Channel** (`iac_export_logs_ext_method_channel.dart`): Default implementation using method channels
- **Native iOS Code** (`IacExportLogsExtPlugin.swift`): Swift implementation with LinkPresentation
  - Receives file path (not file content)
  - Verifies file exists before sharing
  - Returns boolean for success/completion
- **Extension Widget** (`in_app_console_export_logs_extension.dart`): UI and business logic
  - Writes log content to file first
  - Passes file path to native code for sharing on iOS

## Dependencies

This package does NOT use `share_plus`. Instead, it implements custom method channels for platform-specific sharing functionality.

Required dependencies:
- `flutter`
- `plugin_platform_interface`
- `path_provider`
- `in_app_console`

