## From pain point  to Idea

**Pain point**
- Developers can build and view logs, but testers normally can't.
- In micro-frontend architecture, it's difficult to track logs when each module logs differently.

**Idea**
- The package bridges that gap by providing unified in-app log viewing.
- Enables both developers and testers to easily check logs across all modules in one centralized console, making debugging faster and bug reports more detailed.

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

<img src="https://github.com/mduccc/in_app_console/blob/2.0.0/screenshots/list.png?raw=true)" alt="Log List" width="45%"/> <img src="https://github.com/mduccc/in_app_console/blob/2.0.0/screenshots/detail.png?raw=true)" alt="Log Detail" width="45%"/>

<img src="https://github.com/mduccc/in_app_console/blob/2.0.0/screenshots/console.png?raw=true)" alt="Log List"/>

<img src="https://github.com/mduccc/in_app_console/blob/2.0.0/screenshots/extension_list.png?raw=true)" alt="Extensions List" width="45%"/>

<img src="https://github.com/mduccc/in_app_console/blob/2.0.0/screenshots/extension_detail_sample.png?raw=true)" alt="A extension " width="45%"/>

## Usage

### 1. Add dependency
```yaml
dependencies:
  in_app_console: ^2.0.0
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

The in-app console supports a powerful extension system that allows you to add custom functionality without modifying the core package. Extensions can add features like log export, network inspection, database viewing, or any custom tooling you need.

### Using Extensions

To use an extension, simply register it with the console:

```dart
import 'package:your_extension_package/your_extension.dart';

// Register extension
InAppConsole.instance.registerExtension(YourExtension());

// Unregister when no longer needed
InAppConsole.instance.unregisterExtension(yourExtension);
```

Extensions are displayed in the Extensions screen, accessible from the console UI. Each extension provides its own UI widget and functionality.

### Creating Custom Extensions

You can create custom extensions by implementing the `InAppConsoleExtension` abstract class:

```dart
import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';

class LogExportExtension extends InAppConsoleExtension {
  @override
  String get id => 'com.example.log_export';

  @override
  String get name => 'Log Export';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Export logs to file';

  @override
  Widget get icon => const Icon(Icons.download);

  late InAppConsoleExtensionContext _extensionContext;

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    // Initialize resources, set up listeners
    _extensionContext = extensionContext;
    print('Log Export extension initialized');
  }

  @override
  void onDispose() {
    // Clean up resources
    print('Log Export extension disposed');
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(name),
        subtitle: Text(description),
        trailing: ElevatedButton(
          onPressed: () => _exportLogs(),
          child: Text('Export'),
        ),
      ),
    );
  }

  void _exportLogs() {
    // Access console logs
    final logs = _extensionContext.history;
    // Implement export logic
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
- **Lightweight**: Keep extensions performant and avoid heavy operations in `buildWidget()`
- **Access Console Data**: Use the `InAppConsoleExtensionContext` provided in `onInit()` to access log data via `extensionContext.history`
- **Context Access**: Use the provided `BuildContext` in `buildWidget()` for theming and navigation

## Roadmap

~~Support plugging extensions into the in-app console~~ ✅ **Completed in v2.0.0**

Future enhancements:

  [ ] Community extension packages (log export, network inspector, database viewer)