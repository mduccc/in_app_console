import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_rs.dart';
import 'package:iac_network_inspector_ext/src/utils/curl_generator.dart';

/// Screen to display detailed information about a network request
class IacNetworkDetailScreen extends StatelessWidget {
  const IacNetworkDetailScreen({
    required this.networkData,
    super.key,
  });

  final IacNetworkRS networkData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            onPressed: () => _copyAsCurl(context),
            tooltip: 'Copy as CURL',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewSection(),
            const SizedBox(height: 24),
            _buildRequestSection(),
            const SizedBox(height: 24),
            _buildResponseSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    final request = networkData.request;
    final response = networkData.response;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoRow('Method', request.method),
            _buildInfoRow('URL', networkData.url),
            _buildInfoRow('Tag', networkData.dioTag),
            if (response.statusCode != null)
              _buildInfoRow('Status', '${response.statusCode}'),
            _buildInfoRow('Duration', '${response.duration}ms'),
            _buildInfoRow('Sent Time', request.sentTime.toString()),
            _buildInfoRow('Received Time', response.receivedTime.toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestSection() {
    final request = networkData.request;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            // Query Parameters
            if (request.queryParameters.isNotEmpty) ...[
              const Text(
                'Query Parameters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildKeyValueList(request.queryParameters),
              const SizedBox(height: 16),
            ],
            // Headers
            const Text(
              'Headers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _buildKeyValueList(request.headers),
            // Body
            if (request.body != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Body',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildJsonView(request.body),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponseSection() {
    final response = networkData.response;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Response',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            // Error if present
            if (response.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      response.error!.message,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Headers
            if (response.headers != null) ...[
              const Text(
                'Headers',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildResponseHeaders(response.headers!),
              const SizedBox(height: 16),
            ],
            // Body
            if (response.body != null) ...[
              const Text(
                'Body',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildJsonView(response.body),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableRegion(
              focusNode: FocusNode(),
              selectionControls: MaterialTextSelectionControls(),
              child: Text(value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueList(Map<String, dynamic> map) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: map.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SelectableRegion(
                    focusNode: FocusNode(),
                    selectionControls: MaterialTextSelectionControls(),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: SelectableRegion(
                    focusNode: FocusNode(),
                    selectionControls: MaterialTextSelectionControls(),
                    child: Text(entry.value.toString()),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResponseHeaders(Map<String, List<String>> headers) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: headers.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SelectableRegion(
                    focusNode: FocusNode(),
                    selectionControls: MaterialTextSelectionControls(),
                    child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: SelectableRegion(
                    focusNode: FocusNode(),
                    selectionControls: MaterialTextSelectionControls(),
                    child: Text(entry.value.join(', ')),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildJsonView(dynamic data) {
    String formatted;
    try {
      if (data is String) {
        // Try to parse as JSON
        try {
          final parsed = jsonDecode(data);
          formatted = const JsonEncoder.withIndent('  ').convert(parsed);
        } catch (_) {
          formatted = data;
        }
      } else {
        formatted = const JsonEncoder.withIndent('  ').convert(data);
      }
    } catch (e) {
      formatted = data.toString();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: MaterialTextSelectionControls(),
        child: Text(
          formatted,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ),
    );
  }

  void _copyAsCurl(BuildContext context) {
    final curlCommand = CurlGenerator.generate(networkData);
    Clipboard.setData(ClipboardData(text: curlCommand));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CURL command copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
