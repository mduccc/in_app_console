import 'package:dio/dio.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_rs.dart';

/// An abstract class for IacNetworkInterceptor.
/// [IacNetworkInterceptor] should be attached to Dio instances to intercept network requests.
///
abstract class IacNetworkInterceptor extends InterceptorsWrapper {
  /// A stream that emits [DioNetworkRS] whenever a network request is intercepted.
  Stream<IacNetworkRS> get onRequestIntercepted;
}
