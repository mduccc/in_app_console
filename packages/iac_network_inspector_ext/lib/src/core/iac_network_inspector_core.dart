import 'package:dio/dio.dart';

/// An interface for IacNetworkInspectorExt.
/// Definition core functionalities.
///
interface class IacNetworkInspectorExtCore {
  const IacNetworkInspectorExtCore();

  /// Add a Dio instance to be inspected.
  void addDio(Dio dio) {
    throw UnimplementedError();
  }

  /// Remove a Dio instance from being inspected.
  void removeDio(Dio dio) {
    throw UnimplementedError();
  }
}
