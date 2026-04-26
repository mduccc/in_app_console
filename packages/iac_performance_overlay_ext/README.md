# Performance Overlay Extension for In-App Console

A Flutter plugin that adds a real-time performance overlay to the [in_app_console](https://pub.dev/packages/in_app_console) package. Monitor FPS, CPU usage, and memory consumption directly on top of your app.

## What does it do?

This extension provides a draggable floating overlay that displays live performance metrics — frames per second, app CPU usage as a percentage of total device capacity, and app memory used versus total device RAM. An ON/OFF toggle in the console panel controls the overlay visibility, and the setting is persisted across app launches via `shared_preferences`.

## Screenshot

## Register the extension

```dart
final performanceExt = IacPerformanceOverlayExtension();

// Register the extension with the console
InAppConsole.instance.registerExtension(performanceExt);

// Wrap your app in MaterialApp.builder to show the overlay
MaterialApp(
  navigatorKey: _navigatorKey,
  builder: (context, child) => IacPerformanceOverlayWidget(
    service: performanceExt.service,
    overlayVisible: performanceExt.overlayVisible,
    child: InAppConsoleBubble(
      navigatorKey: _navigatorKey,
      child: child!,
    ),
  ),
  ...
);
```
