import 'package:dio/src/dio.dart';
import 'package:flutter/material.dart';
import 'package:iac_network_inspector_ext/src/core/iac_network_inspector_core.dart';
import 'package:iac_network_inspector_ext/src/core/iac_network_interceptor.dart';
import 'package:iac_network_inspector_ext/src/core/model/dio_wrapper.dart';
import 'package:iac_network_inspector_ext/src/external/iac_network_inspector_ext.dart';
import 'package:in_app_console/in_app_console.dart';

final class IacNetworkInspectorExtImpl
    implements
        InAppConsoleExtension,
        IacNetworkInspectorExt,
        IacNetworkInspectorExtCore {
  IacNetworkInspectorExtImpl(this._interceptor);

  final Map<int, DioWrapper> _dioInstancesByHashCode = {};
  final IacNetworkInterceptor _interceptor;

  @override
  String get id => 'iac_network_inspector_ext';

  @override
  String get name => 'Network Inspector';

  @override
  String get description =>
      'An extension to inspect network requests made using Dio.';

  @override
  String get version => '1.0.0';

  @override
  Widget get icon => Icon(Icons.network_check);

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {}

  @override
  Widget buildWidget(BuildContext context) {
    // TODO: implement buildWidget
    throw UnimplementedError();
  }

  @override
  void onDispose() {
    _dioInstancesByHashCode.clear();
  }

  @override
  void addDio(DioWrapper dioWrapper) {
    if (_dioInstancesByHashCode.containsKey(dioWrapper.hashCode)) {
      return;
    }
    dioWrapper.dio.interceptors.add(_interceptor);
    _dioInstancesByHashCode[dioWrapper.hashCode] = dioWrapper;
  }

  @override
  void removeDio(DioWrapper dioWrapper) {
    if (_dioInstancesByHashCode.containsKey(dioWrapper.hashCode)) {
      dioWrapper.dio.interceptors.remove(_interceptor);
      _dioInstancesByHashCode.remove(dioWrapper.hashCode);
    }
  }
}
