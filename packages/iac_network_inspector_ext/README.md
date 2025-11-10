# iac_network_inspector_ext

A powerful network inspector extension for the [in_app_console](https://pub.dev/packages/in_app_console) package. This extension helps developers and testers inspect HTTP/HTTPS network requests made via Dio directly within the Flutter app UI.

## Features

- 📡 **Capture All HTTP Methods** - Supports GET, POST, PUT, DELETE, PATCH, and all other HTTP methods
- 📦 **Multipart/Form-Data Support** - Handles complex request types including file uploads
- 🔍 **Detailed Request/Response Viewer** - View full request and response details including headers, body, status codes, and timing
- 📋 **Copy as CURL** - Copy any request as a CURL command for testing in terminal or sharing with team members
- 🏷️ **Tag Support** - Tag different Dio instances (e.g., "API", "Auth", "Payment") to identify request origins
- 🔎 **Search & Filter** - Search URLs and filter by HTTP method or tag
- ⏱️ **Request Timing** - Track request duration and timestamps
- ❌ **Error Handling** - Capture and display network errors with full error details

## Screenshots

![Network List](screenshots/network_list.png)
![Network Detail](screenshots/network_detail.png)

## Getting started

### Prerequisites

- Flutter SDK >= 3.3.0
- Dart SDK >= 3.5.4
- [in_app_console](https://pub.dev/packages/in_app_console) package
- [dio](https://pub.dev/packages/dio) package for HTTP requests

### Installation

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  in_app_console: ^2.0.0
  dio: ^5.0.0
  iac_network_inspector_ext: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Setup

1. **Create the extension instance:**

```dart
import 'package:iac_network_inspector_ext/iac_network_inspector_ext.dart';
import 'package:iac_network_inspector_ext/src/core/model/dio_wrapper.dart';

// Create the network inspector extension
final networkInspector = IacNetworkInspectorExt();
```

2. **Register the extension with InAppConsole:**

```dart
import 'package:in_app_console/in_app_console.dart';

void main() {
  // Register the extension
  InAppConsole.instance.registerExtension(networkInspector);

  runApp(MyApp());
}
```

3. **Add your Dio instances with tags:**

```dart
// Create your Dio instances
final apiDio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
final authDio = Dio(BaseOptions(baseUrl: 'https://auth.example.com'));

// Register them with the network inspector
networkInspector.addDio(DioWrapper(dio: apiDio, tag: 'API'));
networkInspector.addDio(DioWrapper(dio: authDio, tag: 'Auth'));

// Now all requests made with these Dio instances will be captured!
await apiDio.get('/users');
await authDio.post('/login', data: {'email': 'user@example.com'});
```

### Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:iac_network_inspector_ext/iac_network_inspector_ext.dart';
import 'package:iac_network_inspector_ext/src/core/model/dio_wrapper.dart';

void main() {
  // Enable the console
  InAppConsole.kEnableConsole = true;

  // Create and register network inspector extension
  final networkInspector = IacNetworkInspectorExt();
  InAppConsole.instance.registerExtension(networkInspector);

  // Setup Dio instances
  final apiDio = Dio(BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
  ));

  // Add Dio to network inspector with a tag
  networkInspector.addDio(DioWrapper(dio: apiDio, tag: 'JSONPlaceholder'));

  runApp(MyApp(dio: apiDio));
}

class MyApp extends StatelessWidget {
  final Dio dio;

  const MyApp({required this.dio, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Network Inspector Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () async {
                  // This request will be captured by the network inspector
                  await dio.get('/users');
                },
                child: Text('Make GET Request'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // This request will also be captured
                  await dio.post('/posts', data: {
                    'title': 'Test Post',
                    'body': 'This is a test',
                    'userId': 1,
                  });
                },
                child: Text('Make POST Request'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Open the in-app console to view captured requests
                  InAppConsole.instance.openConsole(context);
                },
                child: Text('Open Console'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Advanced Features

#### Multiple Dio Instances with Different Tags

```dart
// E-commerce app example with multiple services
final catalogDio = Dio(BaseOptions(baseUrl: 'https://api.shop.com/catalog'));
final checkoutDio = Dio(BaseOptions(baseUrl: 'https://api.shop.com/checkout'));
final authDio = Dio(BaseOptions(baseUrl: 'https://auth.shop.com'));

networkInspector.addDio(DioWrapper(dio: catalogDio, tag: 'Catalog'));
networkInspector.addDio(DioWrapper(dio: checkoutDio, tag: 'Checkout'));
networkInspector.addDio(DioWrapper(dio: authDio, tag: 'Authentication'));

// Now you can easily identify which service made which request
```

#### Accessing Network History Programmatically

```dart
// Get all captured network requests
final history = networkInspector.history;

// Listen to real-time network events
networkInspector.stream.listen((networkData) {
  print('New request captured: ${networkData.url}');
  print('Status: ${networkData.response.statusCode}');
  print('Duration: ${networkData.response.duration}ms');
});

// Clear history
networkInspector.clearHistory();
```

#### Removing Dio Instances

```dart
// When you no longer want to track a Dio instance
final wrapper = DioWrapper(dio: apiDio, tag: 'API');
networkInspector.removeDio(wrapper);
```

## UI Features

### Network List View
- Shows all captured requests in reverse chronological order (most recent first)
- Color-coded method badges (GET=blue, POST=green, PUT=orange, DELETE=red)
- Status code badges with color indicators (green for 2xx, orange for 3xx, red for 4xx/5xx)
- Request duration display
- Tag chips for identifying request sources
- Search bar for filtering by URL
- Dropdown filters for method and tag

### Network Detail View
- **Overview Section**: Method, URL, tag, status code, duration, timestamps
- **Request Section**: Query parameters, headers, and body (formatted JSON)
- **Response Section**: Status, headers, body (formatted JSON), and error details
- **CURL Copy**: Tap the code icon to copy the request as a CURL command

## Production Usage

For production builds, you should disable the console:

```dart
void main() {
  // Disable console in production
  InAppConsole.kEnableConsole = kDebugMode;

  // ... rest of your setup
}
```

## Architecture

The extension follows the **in_app_console** extension architecture:

1. **IacNetworkInterceptorImpl** - Dio interceptor that captures request/response data
2. **IacNetworkInspectorExtImpl** - Extension implementation that aggregates data from interceptors
3. **IacNetworkRS** - Data model containing request and response information
4. **UI Components** - List and detail screens for viewing network data
5. **CurlGenerator** - Utility to convert requests to CURL commands

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Additional Information

- **Repository**: [github.com/mduccc/in_app_console](https://github.com/mduccc/in_app_console)
- **Issues**: [github.com/mduccc/in_app_console/issues](https://github.com/mduccc/in_app_console/issues)
- **Main Package**: [in_app_console](https://pub.dev/packages/in_app_console)

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes in each version.
