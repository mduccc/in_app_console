import 'dart:async';

import 'package:flutter/material.dart';

/// A [RouteObserver] that tracks the current and previous deep link (route name)
/// as the user navigates through the app using Flutter Navigator 1.0.
///
/// Only [MaterialPageRoute] transitions are tracked; dialogs, bottom sheets, and
/// other non-page route types are ignored.
///
/// Usage:
/// ```dart
/// final routeTracker = IacRouteTrackerNavigationObserver();
///
/// MaterialApp(
///   navigatorObservers: [routeTracker],
///   ...
/// );
/// ```
class IacRouteTrackerNavigationObserver
    extends RouteObserver<PageRoute<dynamic>> {
  String _currentDeepLink = '';
  String _previousDeepLink = '';
  final List<String> _deepLinkStack = [];
  final StreamController<List<String>> _routeStackController =
      StreamController<List<String>>.broadcast();

  /// The name (deep link) of the currently visible route, or an empty string
  /// if the current route has no name.
  String get currentDeepLink => _currentDeepLink;

  /// The name (deep link) of the previously visible route, or an empty string
  /// if there was no previous named route.
  String get previousDeepLink => _previousDeepLink;

  /// An unmodifiable snapshot of the deep link stack (bottom to top).
  List<String> get routeStack => List.unmodifiable(_deepLinkStack);

  /// A broadcast stream that emits the updated deep link stack on every push/pop.
  Stream<List<String>> get routeStackStream => _routeStackController.stream;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    if (route is! PageRoute) return;

    _deepLinkStack.add(route.settings.name ?? '');
    _previousDeepLink = _currentDeepLink;
    _currentDeepLink = route.settings.name ?? '';
    debugPrint(
      '[RouteTracker] didPush: $_currentDeepLink (previous: $_previousDeepLink)',
    );

    _routeStackController.add(List.unmodifiable(_deepLinkStack));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    if (route is! PageRoute) return;

    if (_deepLinkStack.isNotEmpty) _deepLinkStack.removeLast();
    _previousDeepLink = _currentDeepLink;
    _currentDeepLink = previousRoute?.settings.name ?? '';
    debugPrint(
      '[RouteTracker] didPop: $_currentDeepLink (previous: $_previousDeepLink)',
    );

    _routeStackController.add(List.unmodifiable(_deepLinkStack));
  }
}
