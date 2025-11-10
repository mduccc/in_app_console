import 'dart:async';

import 'package:dio/dio.dart';
import 'package:iac_network_inspector_ext/src/core/iac_network_interceptor.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_rs.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_request.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_response.dart';

final class IacNetworkInterceptorImpl extends IacNetworkInterceptor {
  final StreamController<IacNetworkRS> _requestController =
      StreamController<IacNetworkRS>.broadcast();

  final Map<RequestOptions, _RequestData> _requestDataMap = {};

  @override
  Stream<IacNetworkRS> get onRequestIntercepted => _requestController.stream;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Store request data with timestamp and tag
    final requestData = _RequestData(
      requestTime: DateTime.now(),
      tag: options.extra['iac_dio_tag'] as String? ?? 'Unknown',
    );
    _requestDataMap[options] = requestData;

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final requestData = _requestDataMap.remove(response.requestOptions);

    if (requestData != null) {
      final networkRequest =
          IacNetworkRequest.fromRequestOptions(response.requestOptions);
      final networkResponse = IacNetworkResponse.fromResponse(
        response,
        requestData.requestTime,
      );

      final networkRS = IacNetworkRS(
        url: response.requestOptions.uri.toString(),
        dioTag: requestData.tag,
        request: networkRequest,
        response: networkResponse,
      );

      _requestController.add(networkRS);
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestData = _requestDataMap.remove(err.requestOptions);

    if (requestData != null) {
      final networkRequest =
          IacNetworkRequest.fromRequestOptions(err.requestOptions);
      final networkResponse = IacNetworkResponse.fromError(
        err,
        requestData.requestTime,
      );

      final networkRS = IacNetworkRS(
        url: err.requestOptions.uri.toString(),
        dioTag: requestData.tag,
        request: networkRequest,
        response: networkResponse,
      );

      _requestController.add(networkRS);
    }

    handler.next(err);
  }

  /// Dispose the interceptor and close the stream
  void dispose() {
    _requestController.close();
    _requestDataMap.clear();
  }
}

/// Internal class to store request metadata
class _RequestData {
  _RequestData({
    required this.requestTime,
    required this.tag,
  });

  final DateTime requestTime;
  final String tag;
}
