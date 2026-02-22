# Route Tracker Extension for In-App Console

A Flutter plugin that adds navigation tracking to the [in_app_console](https://pub.dev/packages/in_app_console) package. View the live route stack, navigation history, and route payloads directly in your in-app console.

## What does it do?

This extension displays real-time navigation state including the current route stack with payloads and a chronological history of push/pop events with timestamps. It uses Flutter's Navigator 1.0 observer API and only tracks `MaterialPageRoute` transitions.

## Register the observer and extension

```dart
final routeTracker = IacRouteTrackerNavigationObserver();

// Attach the observer to your Navigator
MaterialApp(
  navigatorObservers: [routeTracker],
  ...
);

// Register the extension with the console
InAppConsole.instance.registerExtension(
  IacRouteTrackerExtension(observer: routeTracker),
);
```
