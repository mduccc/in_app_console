import 'dart:convert';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_rs.dart';

/// Utility class to generate CURL commands from network requests
class CurlGenerator {
  /// Generates a CURL command from [IacNetworkRS]
  static String generate(IacNetworkRS networkData) {
    final buffer = StringBuffer('curl');

    // Add HTTP method
    buffer.write(" -X ${networkData.request.method}");

    // Add URL (wrap in quotes if it contains special characters)
    buffer.write(' "${networkData.url}"');

    // Add headers
    networkData.request.headers.forEach((key, value) {
      // Skip certain headers that curl adds automatically
      if (!_shouldSkipHeader(key)) {
        buffer.write(' -H "$key: $value"');
      }
    });

    // Add request body if present
    final body = networkData.request.body;
    if (body != null) {
      final bodyString = _formatBody(body);
      if (bodyString.isNotEmpty) {
        // Escape quotes in body
        final escapedBody = bodyString.replaceAll('"', '\\"');
        buffer.write(' -d "$escapedBody"');
      }
    }

    return buffer.toString();
  }

  /// Headers that should be skipped when generating CURL
  static bool _shouldSkipHeader(String header) {
    final lowerHeader = header.toLowerCase();
    return lowerHeader == 'content-length' ||
        lowerHeader == 'host' ||
        lowerHeader == 'connection';
  }

  /// Format request body for CURL command
  static String _formatBody(dynamic body) {
    if (body == null) return '';

    if (body is String) {
      return body;
    }

    if (body is Map || body is List) {
      try {
        return jsonEncode(body);
      } catch (e) {
        return body.toString();
      }
    }

    return body.toString();
  }
}
