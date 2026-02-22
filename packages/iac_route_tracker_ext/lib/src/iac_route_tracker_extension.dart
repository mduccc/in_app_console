import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';

import 'iac_route_tracker_navigation_observer.dart';
import 'iac_route_tracker_widget.dart';

/// An [InAppConsoleExtension] that displays the current navigation state,
/// including the current and previous deep link and the full route stack.
///
/// Pass the same [IacRouteTrackerNavigationObserver] instance to both
/// [MaterialApp.navigatorObservers] and to this extension so they share state.
///
/// Example:
/// ```dart
/// final routeTracker = IacRouteTrackerNavigationObserver();
///
/// // In your app widget:
/// MaterialApp(
///   navigatorObservers: [routeTracker],
///   ...
/// );
///
/// // When setting up the console:
/// InAppConsole.instance.registerExtension(
///   IacRouteTrackerExtension(observer: routeTracker),
/// );
/// ```
class IacRouteTrackerExtension extends InAppConsoleExtension {
  IacRouteTrackerExtension({required this.observer});

  final IacRouteTrackerNavigationObserver observer;

  @override
  String get id => 'iac_route_tracker_ext';

  @override
  String get name => 'Route Tracker';

  @override
  String get version => '2.0.1';

  @override
  String get description => 'Track app navigation routes and deep links';

  @override
  Widget get icon => const Icon(Icons.route, color: Colors.black);

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {}

  @override
  void onDispose() {}

  @override
  Widget buildWidget(BuildContext context) {
    return IacRouteTrackerWidget(observer: observer);
  }
}
