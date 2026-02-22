import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iac_network_inspector_ext/src/core/iac_network_inspector_workflow.dart';
import 'package:iac_network_inspector_ext/src/core/iac_network_interceptor.dart';
import 'package:iac_network_inspector_ext/src/core/model/dio_wrapper.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_rs.dart';
import 'package:iac_network_inspector_ext/src/external/iac_network_inspector_ext.dart';
import 'package:iac_network_inspector_ext/src/impl/iac_network_interceptor_impl.dart';
import 'package:iac_network_inspector_ext/src/ui/iac_network_inspector_screen.dart';
import 'package:in_app_console/in_app_console.dart';

final class IacNetworkInspectorExtImpl
    implements
        InAppConsoleExtension,
        IacNetworkInspectorExt,
        IacNetworkInspectorExtWorkflow {
  IacNetworkInspectorExtImpl(this._interceptor);

  final Map<int, DioWrapper> _dioInstancesByHashCode = {};
  final IacNetworkInterceptor _interceptor;
  final StreamController<IacNetworkRS> _streamController =
      StreamController<IacNetworkRS>.broadcast();
  final List<IacNetworkRS> _history = [];
  StreamSubscription<IacNetworkRS>? _interceptorSubscription;

  @override
  String get id => 'iac_network_inspector_ext';

  @override
  String get name => 'Network Inspector';

  @override
  String get description =>
      'An extension to inspect network requests made using Dio.';

  @override
  String get version => '2.0.0';

  @override
  Widget get icon => const Icon(Icons.network_check);

  @override
  Stream<IacNetworkRS> get stream => _streamController.stream;

  @override
  List<IacNetworkRS> get history => List.unmodifiable(_history);

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    // Subscribe to interceptor stream and aggregate all network calls
    _interceptorSubscription = _interceptor.onRequestIntercepted.listen((data) {
      _history.add(data);
      _streamController.add(data);
    });
  }

  @override
  Widget buildWidget(BuildContext context) {
    return StreamBuilder<IacNetworkRS>(
      stream: stream,
      builder: (context, snapshot) {
        return ListTile(
          leading: const Icon(Icons.network_check),
          title: const Text('Network Inspector'),
          subtitle: Text('${_history.length} requests captured'),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => IacNetworkInspectorScreen(
                  extension: this as IacNetworkInspectorExt,
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void onDispose() {
    // Remove interceptors from all Dio instances
    for (final wrapper in _dioInstancesByHashCode.values) {
      wrapper.dio.interceptors.remove(_interceptor);
    }
    _dioInstancesByHashCode.clear();

    // Dispose interceptor
    if (_interceptor is IacNetworkInterceptorImpl) {
      (_interceptor).dispose();
    }

    // Cancel subscription and close stream
    _interceptorSubscription?.cancel();
    _streamController.close();

    // Clear history
    _history.clear();
  }

  @override
  void addDio(DioWrapper dioWrapper) {
    if (_dioInstancesByHashCode.containsKey(dioWrapper.dio.hashCode)) {
      return;
    }

    // Add tag to Dio extra options for tracking
    dioWrapper.dio.options.extra['iac_dio_tag'] = dioWrapper.tag;

    // Add interceptor to Dio
    dioWrapper.dio.interceptors.add(_interceptor);

    // Store the wrapper (use dio.hashCode for consistent tracking)
    _dioInstancesByHashCode[dioWrapper.dio.hashCode] = dioWrapper;
  }

  @override
  void removeDio(DioWrapper dioWrapper) {
    if (_dioInstancesByHashCode.containsKey(dioWrapper.dio.hashCode)) {
      dioWrapper.dio.interceptors.remove(_interceptor);
      _dioInstancesByHashCode.remove(dioWrapper.dio.hashCode);
    }
  }

  @override
  void clearHistory() {
    _history.clear();
  }
}
