import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iac_route_tracker_ext/iac_route_tracker_ext.dart';

void main() {
  group('GIVEN an IacRouteTrackerNavigationObserver', () {
    late IacRouteTrackerNavigationObserver observer;

    setUp(() {
      observer = IacRouteTrackerNavigationObserver();
    });

    tearDown(() {
      observer.dispose();
    });

    test('WHEN created THEN deep links are empty and stack is empty', () {
      expect(observer.currentDeepLink, '');
      expect(observer.previousDeepLink, '');
      expect(observer.routeStack, isEmpty);
    });

    test(
        'WHEN a MaterialPageRoute is pushed THEN currentDeepLink is updated and route is added to stack',
        () async {
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/home'),
        builder: (_) => const SizedBox(),
      );

      final stackEvents = <List<String>>[];
      final subscription = observer.routeStackStream.listen(stackEvents.add);

      observer.didPush(route, null);

      await Future.delayed(Duration.zero);

      expect(observer.currentDeepLink, '/home');
      expect(observer.previousDeepLink, '');
      expect(observer.routeStack, hasLength(1));
      expect(stackEvents, hasLength(1));

      await subscription.cancel();
    });

    test(
        'WHEN a non-MaterialPageRoute is pushed THEN state is unchanged',
        () async {
      final nonPageRoute = _TestNonPageRoute(
        settings: const RouteSettings(name: '/dialog'),
      );

      final stackEvents = <List<String>>[];
      final subscription = observer.routeStackStream.listen(stackEvents.add);

      observer.didPush(nonPageRoute, null);

      await Future.delayed(Duration.zero);

      expect(observer.currentDeepLink, '');
      expect(observer.routeStack, isEmpty);
      expect(stackEvents, isEmpty);

      await subscription.cancel();
    });

    test(
        'WHEN two routes are pushed THEN previousDeepLink reflects the prior route',
        () {
      final home = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/home'),
        builder: (_) => const SizedBox(),
      );
      final detail = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/detail'),
        builder: (_) => const SizedBox(),
      );

      observer.didPush(home, null);
      observer.didPush(detail, home);

      expect(observer.currentDeepLink, '/detail');
      expect(observer.previousDeepLink, '/home');
      expect(observer.routeStack, hasLength(2));
    });

    test(
        'WHEN a route is popped THEN currentDeepLink reverts to the previous route',
        () {
      final home = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/home'),
        builder: (_) => const SizedBox(),
      );
      final detail = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/detail'),
        builder: (_) => const SizedBox(),
      );

      observer.didPush(home, null);
      observer.didPush(detail, home);

      expect(observer.routeStack, hasLength(2));

      observer.didPop(detail, home);

      expect(observer.currentDeepLink, '/home');
      expect(observer.previousDeepLink, '/detail');
      expect(observer.routeStack, hasLength(1));
    });

    test(
        'WHEN a route with no name is pushed THEN currentDeepLink is empty string',
        () {
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(),
        builder: (_) => const SizedBox(),
      );

      observer.didPush(route, null);

      expect(observer.currentDeepLink, '');
    });

    test('WHEN routeStack is accessed THEN it is unmodifiable', () {
      final route = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/home'),
        builder: (_) => const SizedBox(),
      );
      observer.didPush(route, null);

      expect(
        () => observer.routeStack.add('/test'),
        throwsUnsupportedError,
      );
    });
  });
}

/// A non-PageRoute used to verify the observer ignores non-page routes.
class _TestNonPageRoute extends Fake implements Route<void> {
  _TestNonPageRoute({RouteSettings? settings})
      : _settings = settings ?? const RouteSettings();

  final RouteSettings _settings;

  @override
  RouteSettings get settings => _settings;
}
