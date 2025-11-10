import 'package:iac_network_inspector_ext/src/core/model/dio_wrapper.dart';

/// An interface for IacNetworkInspectorExt.
/// Definition core functionalities.
///
interface class IacNetworkInspectorExtCore {
  const IacNetworkInspectorExtCore();

  /// Add a Dio instance to be inspected.
  void addDio(DioWrapper dioWrapper) {
    throw UnimplementedError();
  }

  /// Remove a Dio instance from being inspected.
  void removeDio(DioWrapper dioWrapper) {
    throw UnimplementedError();
  }
}
