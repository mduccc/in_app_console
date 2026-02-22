import 'package:dio/dio.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_error.dart';

/// Holder for network response data.
///
final class IacNetworkResponse {
  const IacNetworkResponse({
    required this.receivedTime,
    required this.duration,
    this.statusCode,
    this.statusMessage,
    this.headers,
    this.body,
    this.contentType,
    this.error,
  });

  /// Creates a IacNetworkResponse from Dio Response
  factory IacNetworkResponse.fromResponse(
    Response response,
    DateTime requestTime,
  ) {
    return IacNetworkResponse(
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      headers: response.headers.map,
      body: response.data,
      contentType: response.headers.value('content-type'),
      receivedTime: DateTime.now(),
      duration: DateTime.now().difference(requestTime).inMilliseconds,
    );
  }

  /// Creates a IacNetworkResponse from DioException
  factory IacNetworkResponse.fromError(
    DioException error,
    DateTime requestTime,
  ) {
    return IacNetworkResponse(
      statusCode: error.response?.statusCode,
      statusMessage: error.response?.statusMessage,
      headers: error.response?.headers.map,
      body: error.response?.data,
      contentType: error.response?.headers.value('content-type'),
      receivedTime: DateTime.now(),
      duration: DateTime.now().difference(requestTime).inMilliseconds,
      error: IacNetworkError(
        message: error.message ?? 'Unknown error',
        code: error.response?.statusCode,
        error: error.error,
        stackTrace: error.stackTrace,
      ),
    );
  }

  /// HTTP status code (null if request failed before receiving response)
  final int? statusCode;

  /// HTTP status message
  final String? statusMessage;

  /// Response headers
  final Map<String, List<String>>? headers;

  /// Response body
  final dynamic body;

  /// Content type of the response
  final String? contentType;

  /// Timestamp when the response was received
  final DateTime receivedTime;

  /// Duration of the request in milliseconds
  final int duration;

  /// Error information if the request failed
  final IacNetworkError? error;

  /// Check if the response is successful (status code 2xx)
  bool get isSuccess =>
      statusCode != null && statusCode! >= 200 && statusCode! < 300;

  /// Check if the response has an error
  bool get hasError =>
      error != null || (statusCode != null && statusCode! >= 400);
}
