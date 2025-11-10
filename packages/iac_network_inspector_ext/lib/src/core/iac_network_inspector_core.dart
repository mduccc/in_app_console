import 'package:iac_network_inspector_ext/src/core/model/dio_wrapper.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_rs.dart';

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

  /// Get the stream of network requests and responses.
  Stream<IacNetworkRS> get stream {
    throw UnimplementedError();
  }

  /// Get the history of all network requests and responses.
  List<IacNetworkRS> get history {
    throw UnimplementedError();
  }

  /// Clear the history of network requests and responses.
  void clearHistory() {
    throw UnimplementedError();
  }
}
