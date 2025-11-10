import 'package:dio/dio.dart';
import 'package:iac_network_inspector_ext/src/core/iac_network_interceptor.dart';

class IacNetworkInterceptorImpl extends IacNetworkInterceptor {
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
