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

<img src="https://github.com/mduccc/in_app_console/blob/1.0.1/screenshots/list.png?raw=true)" alt="Log List" width="45%"/> <img src="https://github.com/mduccc/in_app_console/blob/1.0.1/screenshots/detail.png?raw=true)" alt="Log Detail" width="45%"/>

<img src="https://github.com/mduccc/in_app_console/blob/1.0.1/screenshots/console.png?raw=true)" alt="Log List"/>

## Usage

### 1. Add dependency
```yaml
dependencies:
  in_app_console: ^1.0.1
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
