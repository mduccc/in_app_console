import 'package:dio/dio.dart';

/// Holder for network request data.
///
final class IacNetworkRequest {
  const IacNetworkRequest({
    required this.method,
    required this.headers,
    required this.queryParameters,
    required this.sentTime,
    this.body,
    this.contentType,
  });

  /// Creates a IacNetworkRequest from Dio RequestOptions
  factory IacNetworkRequest.fromRequestOptions(RequestOptions options) {
    return IacNetworkRequest(
      method: options.method,
      headers: Map<String, dynamic>.from(options.headers),
      queryParameters: Map<String, dynamic>.from(options.queryParameters),
      body: _formatRequestBody(options.data),
      contentType: options.contentType?.toString(),
      sentTime: DateTime.now(),
    );
  }

  /// The HTTP method (GET, POST, PUT, DELETE, etc.)
  final String method;

  /// Request headers
  final Map<String, dynamic> headers;

  /// Query parameters
  final Map<String, dynamic> queryParameters;

  /// Request body (can be Map, String, List, FormData, etc.)
  final dynamic body;

  /// Content type of the request
  final String? contentType;

  /// Timestamp when the request was sent
  final DateTime sentTime;

  /// Helper to format request body for display
  static dynamic _formatRequestBody(dynamic data) {
    if (data == null) return null;
    if (data is FormData) {
      return 'FormData(${data.fields.length} fields, ${data.files.length} files)';
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return List.from(data);
    return data.toString();
  }
}
