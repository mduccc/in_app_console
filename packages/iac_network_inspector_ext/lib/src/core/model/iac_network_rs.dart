import 'package:iac_network_inspector_ext/src/core/model/iac_network_request.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_response.dart';

/// Holder for network request and response data specific to Dio.
///
final class IacNetworkRS {
  const IacNetworkRS({
    required this.url,
    required this.dioTag,
    required this.request,
    required this.response,
  });

  /// The request URL.
  final String url;

  /// The tag associated with the Dio instance.
  final String dioTag;

  /// The network request data.
  final IacNetworkRequest request;

  /// The network response data.
  final IacNetworkResponse response;
}
