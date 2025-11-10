import 'package:dio/dio.dart';

/// A wrapper class for Dio instances with an associated tag.
///
final class DioWrapper {
  const DioWrapper({required this.dio, required this.tag});

  /// The Dio instance to be wrapped.
  final Dio dio;

  /// A tag to identify the Dio instance.
  final String tag;
}
