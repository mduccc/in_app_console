# Overview
Tracks the app router(deeplink). Keeps current and previous screen deep links

Support navigation 1.0 now.


# Implementation guide

## The IacRouteTrackerNavigationObserver for wrap material app

import 'dart:async';
import 'package:flutter/material.dart';

@LazySingleton(as: KVNavigationObserver)
class IacRouteTrackerNavigationObserver extends RouteObserver<PageRoute<dynamic>> {
  KVNavigationObserverImpl(this._saveLastVisibleScreenUseCase);

  String _currentDeepLink = '';
  String _previousDeepLink = '';
  final stack_data_structure.Stack<Route> _routeStack =
      stack_data_structure.Stack<Route>();
  final StreamController<stack_data_structure.Stack<Route>> _routeStackStream =
      StreamController<stack_data_structure.Stack<Route>>.broadcast();
  final SaveLastVisibleScreenUseCase _saveLastVisibleScreenUseCase;

  @override
  String get currentDeepLink => _currentDeepLink;

  @override
  stack_data_structure.Stack<Route> get routeStack => _routeStack;

  @override
  Stream<stack_data_structure.Stack<Route>> get routeStackStream =>
      _routeStackStream.stream;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    /// We only care about MaterialPageRoute
    /// Ignore triggered by other route types like bottom sheet, dialog, etc.
    if (route is! MaterialPageRoute) {
      return;
    }

    _routeStack.pop();
    _routeStackStream.add(_routeStack);

    _previousDeepLink = _currentDeepLink;
    _currentDeepLink = previousRoute?.settings.name ?? '';

    _saveLastVisibleScreenUseCase
        .call(SaveLastVisibleScreenUseCaseParam(deepLink: _currentDeepLink));

    if (_currentDeepLink.isEmpty) {
      di<KVLogger>().info(
          '[APP_NAVIGATOR_OBSERVER] CURRENT DEEP_LINK is empty. This screen might be pushed directly without deepLink.');
    } else {
      di<KVLogger>().info(
          '[APP_NAVIGATOR_OBSERVER] CURRENT DEEP_LINK: $_currentDeepLink');
    }

    if (_previousDeepLink.isEmpty) {
      di<KVLogger>().info(
          '[APP_NAVIGATOR_OBSERVER] PREVIOUS DEEP_LINK is empty. This screen might be pushed directly without deepLink.');
    } else {
      di<KVLogger>().info(
          '[APP_NAVIGATOR_OBSERVER] PREVIOUS DEEP_LINK: $_previousDeepLink');
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    /// We only care about MaterialPageRoute
    /// Ignore triggered by other route types like bottom sheet, dialog, etc.
    if (route is! MaterialPageRoute) {
      return;
    }

    _routeStack.push(route);
    _routeStackStream.add(_routeStack);

    _previousDeepLink = _currentDeepLink;
    _currentDeepLink = route.settings.name ?? '';

    _saveLastVisibleScreenUseCase
        .call(SaveLastVisibleScreenUseCaseParam(deepLink: _currentDeepLink));

    if (_currentDeepLink.isEmpty) {
      di<KVLogger>().info(
          '[APP_NAVIGATOR_OBSERVER] CURRENT DEEP_LINK is empty. Maybe screen has been pushed directly without deepLink.');
    } else {
      di<KVLogger>().info(
          '[APP_NAVIGATOR_OBSERVER] CURRENT DEEP_LINK: $_currentDeepLink');
    }

    if (_previousDeepLink.isEmpty) {
      di<KVLogger>().info(
          '[APP_NAVIGATOR_OBSERVER] PREVIOUS DEEP_LINK is empty. This screen might be pushed directly without deepLink.');
    } else {
      di<KVLogger>().info(
          '[APP_NAVIGATOR_OBSERVER] PREVIOUS DEEP_LINK: $_previousDeepLink');
    }
  }
}