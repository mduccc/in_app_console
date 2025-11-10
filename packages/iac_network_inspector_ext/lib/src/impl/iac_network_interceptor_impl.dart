import 'dart:async';

import 'package:dio/dio.dart';
import 'package:iac_network_inspector_ext/src/core/iac_network_interceptor.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_rs.dart';

final class IacNetworkInterceptorImpl extends IacNetworkInterceptor {
  final StreamController<IacNetworkRS> _requestController =
      StreamController<IacNetworkRS>.broadcast();

  @override
  Stream<IacNetworkRS> get onRequestIntercepted => _requestController.stream;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // You can add custom logic before the request is sent
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // You can add custom logic when a response is received
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    // You can add custom logic when an error occurs
    handler.next(err);
  }
}
