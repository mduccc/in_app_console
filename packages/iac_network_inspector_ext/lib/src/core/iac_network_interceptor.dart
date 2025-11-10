import 'package:dio/dio.dart';

/// An abstract class for IacNetworkInterceptor.
/// [IacNetworkInterceptor] should be attached to Dio instances to intercept network requests.
///
abstract class IacNetworkInterceptor extends InterceptorsWrapper {}
