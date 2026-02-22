import 'dart:async';

import 'package:flutter/material.dart';

/// A single entry in the live route stack.
class IacRouteStackEntry {
  final String routeName;

  /// Optional arguments passed to the route via [RouteSettings.arguments].
  final Object? payload;

  const IacRouteStackEntry({required this.routeName, this.payload});
}

/// A single navigation event recorded in the route history.
class IacRouteHistoryEntry {
  final String routeName;

  /// `true` if the route was pushed, `false` if it was popped.
  final bool isPush;
  final DateTime timestamp;

  /// Optional arguments passed to the route via [RouteSettings.arguments].
  final Object? payload;

  const IacRouteHistoryEntry({
    required this.routeName,
    required this.isPush,
    required this.timestamp,
    this.payload,
  });
}

/// A [RouteObserver] that tracks navigation history and the live route stack
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
  final List<IacRouteStackEntry> _deepLinkStack = [];
  final List<IacRouteHistoryEntry> _routeHistory = [];
  final StreamController<List<IacRouteStackEntry>> _routeStackController =
      StreamController<List<IacRouteStackEntry>>.broadcast();

  /// An unmodifiable snapshot of the route stack (bottom to top).
  List<IacRouteStackEntry> get routeStack => List.unmodifiable(_deepLinkStack);

  /// An unmodifiable chronological list of all navigation events (oldest first).
  List<IacRouteHistoryEntry> get routeHistory =>
      List.unmodifiable(_routeHistory);

  /// A broadcast stream that emits the updated route stack on every push/pop.
  Stream<List<IacRouteStackEntry>> get routeStackStream =>
      _routeStackController.stream;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    if (route is! PageRoute || (route.settings.name ?? '').trim().isEmpty) {
      return;
    }

    final name = route.settings.name ?? '';
    final payload = route.settings.arguments;
    _deepLinkStack.add(IacRouteStackEntry(routeName: name, payload: payload));
    _routeHistory.add(
      IacRouteHistoryEntry(
        routeName: name,
        isPush: true,
        timestamp: DateTime.now(),
        payload: payload,
      ),
    );
    debugPrint('[RouteTracker] didPush: $name');

    _routeStackController.add(List.unmodifiable(_deepLinkStack));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    if (route is! PageRoute || (route.settings.name ?? '').trim().isEmpty) {
      return;
    }

    final name = route.settings.name ?? '';
    if (_deepLinkStack.isNotEmpty) _deepLinkStack.removeLast();
    _routeHistory.add(
      IacRouteHistoryEntry(
        routeName: name,
        isPush: false,
        timestamp: DateTime.now(),
        payload: route.settings.arguments,
      ),
    );
    debugPrint('[RouteTracker] didPop: $name');

    _routeStackController.add(List.unmodifiable(_deepLinkStack));
  }
}
