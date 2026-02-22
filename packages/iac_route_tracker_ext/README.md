# Route Tracker Extension for In-App Console

A Flutter plugin that adds navigation tracking to the [in_app_console](https://pub.dev/packages/in_app_console) package. View the live route stack, navigation history, and route payloads directly in your in-app console.

## What does it do?

This extension displays real-time navigation state including the current route stack with payloads and a chronological history of push/pop events with timestamps. It uses Flutter's Navigator 1.0 observer API and only tracks `PageRoute` transitions.

## Screenshot

<img src="https://raw.githubusercontent.com/mduccc/in_app_console/2c6a6c1aff170e0408768bbdea0103dbbb49dd80/packages/iac_route_tracker_ext/screenshot/screenshot.png" width=35%> 

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
