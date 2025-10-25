# In-App Console - Micro-Frontend Architecture Example

This example demonstrates how the `in_app_console` package works excellently with micro-frontend architecture patterns.

## 🏗️ Architecture Overview

The example showcases a Flutter app with multiple independent modules:

- **Auth Module** - Handles user authentication and session management
- **Payment Module** - Processes payments and validates payment methods  
- **Profile Module** - Manages user profile data and image uploads
- **Chat Module** - Handles messaging and chat connectivity

Each module has its own `InAppLogger` instance with a unique label, and all logs are aggregated into a central `InAppConsole` for unified debugging.

## 🚀 Features Demonstrated

### 1. **Module Isolation**
Each module operates independently with its own logger:
```dart
class AuthModule {
  final InAppLogger logger = InAppLogger()..setLabel('Auth');
  // ... module logic
}
```

### 2. **Central Log Aggregation**
All module loggers are registered with the central console:
```dart
InAppConsole.instance.addLogger(authModule.logger);
InAppConsole.instance.addLogger(paymentModule.logger);
InAppConsole.instance.addLogger(profileModule.logger);
InAppConsole.instance.addLogger(chatModule.logger);
```

### 3. **Realistic User Scenarios**
- Complete user journey simulation (login → profile → payment → chat)
- Individual module testing
- Error handling and warning scenarios
- Performance monitoring with timing logs

### 4. **Unified Debugging Experience**
View logs from all modules in a single console with:
- Module-specific filtering (Auth, Payment, Profile, Chat)
- Timestamp ordering across modules
- Error highlighting and stack traces
- Search functionality across all modules

### 5. **Extension System**
The example includes a sample extension that demonstrates how to extend console functionality:
```dart
InAppConsole.instance.registerExtension(LogStatisticsExtension());
```

The **Log Statistics Extension** provides:
- Real-time log analytics (total, info, warning, error counts)
- Module-based log distribution
- Clear logs functionality with confirmation dialog
- Export preview feature (demo mode)

## 📱 Running the Example

1. Navigate to the example directory:
```bash
cd example
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## 🎯 How to Use

1. **Run Complete User Journey** - Simulates a full user flow across all modules
2. **Test Individual Modules** - Trigger specific module actions to see isolated logging
3. **Open Console** - View the unified log console to see all module interactions
4. **Filter by Module** - Use the console's filtering to focus on specific modules
5. **View Extensions** - Tap the "Extensions" button in the console to access installed extensions like Log Statistics

## 💡 Key Benefits for Micro-Frontend Architecture

✅ **Service Isolation** - Each module has independent logging
✅ **Decoupled Communication** - Modules don't reference each other's loggers
✅ **Centralized Monitoring** - Single console shows all service interactions
✅ **Service Identification** - Clear labeling identifies which service logged what
✅ **Dynamic Registration** - Services can register loggers at runtime
✅ **Fault Tolerance** - One service's logger failure doesn't affect others
✅ **Scalability** - Easy to add new services by creating new loggers
✅ **Unified Debugging** - Debug complex multi-service interactions in one place

## 🔌 Extension Development

This example includes a sample extension (`lib/extensions/log_statistics_extension.dart`) that demonstrates how to create custom extensions. To create your own extension:

1. **Implement `InAppConsoleExtension`**:
```dart
class MyExtension extends InAppConsoleExtension {
  @override
  String get id => 'com.yourcompany.my_extension';

  @override
  String get name => 'My Extension';

  @override
  String get version => '1.0.0';

  @override
  Widget get icon => Icon(Icons.star); // Optional custom icon

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    // Initialize your extension
  }

  @override
  Widget buildWidget(BuildContext context) {
    // Return your extension's UI
    return Container();
  }
}
```

2. **Register the extension**:
```dart
InAppConsole.instance.registerExtension(MyExtension());
```

3. **Access console data**:
```dart
// Get log history
final logs = extensionContext.history;

// Listen to log stream
extensionContext.stream.listen((log) {
  // Handle new logs
});
```

See `lib/extensions/log_statistics_extension.dart` for a complete working example!

---

This example proves that `in_app_console` is perfectly designed for modern micro-frontend and microservice architectures! 🎯
