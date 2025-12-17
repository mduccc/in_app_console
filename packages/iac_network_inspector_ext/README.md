# Network Inspector Extension for In-App Console

A Flutter plugin that adds network inspection functionality to the [in_app_console](https://pub.dev/packages/in_app_console) package. Inspect HTTP/HTTPS network requests made via Dio directly within your Flutter app UI.

## What does it do?

This extension captures and displays all network requests from your Dio instances, allowing you to view request/response details, headers, timing, and copy requests as CURL commands.

## Screenshots

<img src="https://github.com/mduccc/in_app_console/blob/8edaebd5cc91cff4251ffae9d69bcfb816881e7d/packages/iac_network_inspector_ext/screenshots/preview.png?raw=true" width=35%> <img src="https://github.com/mduccc/in_app_console/blob/8edaebd5cc91cff4251ffae9d69bcfb816881e7d/packages/iac_network_inspector_ext/screenshots/list.png?raw=true" width=35%>

<img src="https://github.com/mduccc/in_app_console/blob/8edaebd5cc91cff4251ffae9d69bcfb816881e7d/packages/iac_network_inspector_ext/screenshots/detail.png?raw=true" width=35%>

## Register the extension

```dart
// Create the network inspector extension
final networkInspector = IacNetworkInspectorExt();

// Register the extension
InAppConsole.instance.registerExtension(networkInspector);

// Add your Dio instances with tags
networkInspector.addDio(DioWrapper(
  dio: yourDioInstance,
  tag: 'Payment API',
));
```
