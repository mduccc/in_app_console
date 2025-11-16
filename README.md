## Table of Contents

- [Table of Contents](#table-of-contents)
- [Overview](#overview)
- [Designed for Micro-frontend architecture](#designed-for-micro-frontend-architecture)
- [Screenshots](#screenshots)
- [Usage](#usage)
  - [1. Add dependency](#1-add-dependency)
  - [2. Import the package](#2-import-the-package)
  - [3. Create logger and add to console](#3-create-logger-and-add-to-console)
  - [4. Log messages](#4-log-messages)
  - [5. Show console screen](#5-show-console-screen)
- [Extension System](#extension-system)
  - [Using Extensions](#using-extensions)
  - [Creating Custom Extensions](#creating-custom-extensions)
  - [Extension Lifecycle](#extension-lifecycle)
  - [Extension Guidelines](#extension-guidelines)
- [Roadmap](#roadmap)

---

## Overview

In-app console for real-time log viewing. Bridges developers and testers with unified logging across micro-frontend modules. Extensible with custom plugins.

## Designed for Micro-frontend architecture
```
┌─────────────────────────────────────────────────────────────────────────────────────┐
│              Flutter App with Micro-frontend architecture                           │
├─────────────────────────────────────────────────────────────────────────────────────┤
│ [Auth Module]     [Payment Module]     [Profile Module]     [Chat Module]           │
│     Logger            Logger             Logger             Logger                  │
│ setLabel('Auth')  setLabel('Payment')  setLabel('Profile')  setLabel('Chat')        │
│      │                 │                  │                 │                      │
│      └─────────────────┼──────────────────┼─────────────────┘                      │
│                        │                  │                                        │
│                        ▼                  ▼                                        │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                       [Platform Application]                                       │
│                        InAppConsole (Central)                                      │
│                                                                                     │
│    Registered Loggers with Tags: [Auth, Payment, Profile, Chat]                    │
│                                                                                     │
│    Unified History with Tags:                                                      │
│    • [Auth] User login                                                             │
│    • [Payment] Payment failed                                                      │
│    • [Profile] Profile updated                                                     │
│    • [Chat] Message sent                                                           │
│                              │                                                     │
│                              ▼                                                     │
├─────────────────────────────────────────────────────────────────────────────────────┤
│                         Console UI Screen                                          │
│                                                                                     │
│    Tagged Log Display:                                                             │
│    14:23 [Auth] User login successful                                              │
│    14:24 [Payment] Payment gateway timeout                                         │
│    14:25 [Profile] Profile image uploaded                                          │
│    14:26 [Chat] Message sent                                                       │
│                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────┘
```

## Screenshots

<img src="https://github.com/mduccc/in_app_console/blob/2.0.1/screenshots/list.png?raw=true)" alt="Log List" width="45%"/> <img src="https://github.com/mduccc/in_app_console/blob/2.0.1/screenshots/detail.png?raw=true)" alt="Log Detail" width="45%"/>

<img src="https://raw.githubusercontent.com/mduccc/in_app_console/ba5c89b84630c256f8b33a528ea823093b49986d/screenshots/extension_list.png" alt="Extensions List" width="45%"/> <img src="https://github.com/mduccc/in_app_console/blob/2.0.1/screenshots/extension_detail_sample.png?raw=true)" alt="A extension " width="45%"/>

<img src="https://raw.githubusercontent.com/mduccc/in_app_console/ba5c89b84630c256f8b33a528ea823093b49986d/screenshots/extension_export_log.png" alt="A extension " width="45%"/>

<img src="https://github.com/mduccc/in_app_console/blob/2.0.1/screenshots/console.png?raw=true)" alt="Console"/>

## Usage

### 1. Add dependency
```yaml
dependencies:
  in_app_console: ^2.0.1
```

### 2. Import the package
Add the following import to your Dart files where you want to use the in-app console:

```dart
import 'package:in_app_console/in_app_console.dart';
```

### 3. Create logger and add to console
```dart
/// Create logger
final logger = InAppLogger();
logger.setLabel('Chat module'); // Optional: set a label

// Enable console (typically only in debug/development mode)
InAppConsole.kEnableConsole = true;

/// Add logger to console
InAppConsole.instance.addLogger(logger);
```

### 4. Log messages
```dart
// Info logs
logger.logInfo('User logged in successfully');

// Warning logs
logger.logWarning(message: 'Low storage space');

// Error logs
logger.logError(
  message: 'Failed to load data',
  error: error,
  stackTrace: stackTrace,
);
```

### 5. Show console screen
```dart
// Using InAppConsole helper method
InAppConsole.instance.openConsole(context);
```

## Extension System

The in-app console supports a powerful extension system that allows you to add custom functionality without modifying the core package. Extensions can add features like log statistics, log export, network inspection, database viewing, or any custom tooling you need.

### Using Extensions

To use an extension, simply register it with the console:

```dart
// Register extension
InAppConsole.instance.registerExtension(LogStatisticsExtension());

// Unregister when no longer needed (optional)
final extension = LogStatisticsExtension();
InAppConsole.instance.registerExtension(extension);
// Later...
InAppConsole.instance.unregisterExtension(extension);
```

Extensions are displayed in the Extensions screen, accessible from the console UI. Each extension provides its own UI widget and functionality.

### Creating Custom Extensions

You can create custom extensions by implementing the `InAppConsoleExtension` abstract class:

```dart
import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';

/// Sample extension that displays log statistics and analytics.
class LogStatisticsExtension extends InAppConsoleExtension {
  @override
  String get id => 'com.example.log_statistics';

  @override
  String get name => 'Log Statistics';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'View log statistics and analytics';

  @override
  Widget get icon => const Icon(Icons.analytics_outlined);

  late InAppConsoleExtensionContext _extensionContext;

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    // Initialize resources, set up listeners
    _extensionContext = extensionContext;
    debugPrint('[$name] Extension initialized');
  }

  @override
  void onDispose() {
    // Clean up resources
    debugPrint('[$name] Extension disposed');
  }

  @override
  Widget buildWidget(BuildContext context) {
    final logs = _extensionContext.history;

    // Calculate statistics
    final totalLogs = logs.length;
    final infoCount = logs.where((log) => log.type == InAppLoggerType.info).length;
    final warningCount = logs.where((log) => log.type == InAppLoggerType.warning).length;
    final errorCount = logs.where((log) => log.type == InAppLoggerType.error).length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Log Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Total Logs: $totalLogs'),
            Text('Info: $infoCount'),
            Text('Warnings: $warningCount'),
            Text('Errors: $errorCount'),
          ],
        ),
      ),
    );
  }
}
```

### Extension Lifecycle

1. **Registration**: Call `InAppConsole.instance.registerExtension(extension)`
2. **Initialization**: `onInit()` is called when the extension is registered
3. **Rendering**: `buildWidget()` is called to render the extension's UI
4. **Cleanup**: `onDispose()` is called when the extension is unregistered

### Extension Guidelines

- **Unique IDs**: Use reverse domain notation (e.g., `com.yourcompany.extension_name`)
- **Custom Icons**: Provide a custom icon widget (Icon, Image, etc.) to visually identify your extension
- **Widget Building**: Keep extensions performant and avoid heavy operations in `buildWidget()`
- **Access Console Data**: Use the `InAppConsoleExtensionContext` provided in `onInit()` to access log data via `extensionContext.history`
- **Context Access**: Use the provided `BuildContext` in `buildWidget()` for theming and navigation

## Roadmap

~~Support plugging extensions into the in-app console~~ ✅ **Completed in v2.0.0**

Extension packages:
- [x] **iac_export_logs_ext** - Export captured logs to external files or share via system share sheet
- [ ] **iac_network_inspector_ext** - (Inprogress) Inspect HTTP/HTTPS network requests made via Dio, view request/response details, and copy as CURL
- [x] **iac_statistics_ext** -  View statistics and analytics of captured logs (counts by type, frequency charts, etc.)
- [ ] **iac_device_info_ext** - Display device information (OS version, model, screen size, CPU, etc.)

Future enhancements:
 - [ ] Community extension packages (log export, network inspector, database viewer)