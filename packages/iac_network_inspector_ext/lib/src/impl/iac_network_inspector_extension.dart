import 'package:dio/src/dio.dart';
import 'package:flutter/material.dart';
import 'package:iac_network_inspector_ext/src/core/iac_network_inspector_core.dart';
import 'package:iac_network_inspector_ext/src/core/iac_network_interceptor.dart';
import 'package:iac_network_inspector_ext/src/external/iac_network_inspector_ext.dart';
import 'package:in_app_console/in_app_console.dart';

class IacNetworkInspectorExtImpl
    implements
        InAppConsoleExtension,
        IacNetworkInspectorExt,
        IacNetworkInspectorExtCore {
  IacNetworkInspectorExtImpl(this._interceptor);

  final Map<int, Dio> _dioInstancesByHashcode = {};
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
    _dioInstancesByHashcode.clear();
  }

  @override
  void addDio(Dio dio) {
    if (_dioInstancesByHashcode.containsKey(dio.hashCode)) {
      return;
    }
    dio.interceptors.add(_interceptor);
    _dioInstancesByHashcode[dio.hashCode] = dio;
  }

  @override
  void removeDio(Dio dio) {
    if (_dioInstancesByHashcode.containsKey(dio.hashCode)) {
      dio.interceptors.remove(_interceptor);
      _dioInstancesByHashcode.remove(dio.hashCode);
    }
  }
}
