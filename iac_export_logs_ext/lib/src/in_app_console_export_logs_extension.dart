import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:path_provider/path_provider.dart';
import '../iac_export_logs_ext_platform_interface.dart';

enum _ExportState { idle, loading, success, error }

Future<Directory?> _getExportDirectory() async {
  if (Platform.isAndroid) {
    // For Android, use external storage directory (Downloads)
    return await getExternalStorageDirectory();
  } else if (Platform.isIOS) {
    // For iOS, use temporary directory (will be shared via share sheet)
    return await getTemporaryDirectory();
  } else {
    // For desktop platforms
    return await getDownloadsDirectory();
  }
}

Future<bool> _shareFileViaMethodChannel(String filePath) async {
  try {
    final result = await IacExportLogsExtPlatform.instance.shareFile(
      filePath: filePath,
    );
    return result;
  } catch (e) {
    debugPrint('Error sharing file via method channel: $e');
    return false;
  }
}

class InAppConsoleExportLogsExtension extends InAppConsoleExtension {
  late final InAppConsoleExtensionContext _extensionContext;

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    _extensionContext = extensionContext;
    super.onInit(extensionContext);
  }

  @override
  Widget buildWidget(BuildContext context) {
    return _ExportLogsWidget(
      extensionContext: _extensionContext,
    );
  }

  @override
  String get id => 'iac_export_logs_ext';

  @override
  String get name => 'Export Logs';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'Extension to export log history to a file';
}

class _ExportLogsWidget extends StatefulWidget {
  const _ExportLogsWidget({
    required this.extensionContext,
  });

  final InAppConsoleExtensionContext extensionContext;

  @override
  State<_ExportLogsWidget> createState() => _ExportLogsWidgetState();
}

class _ExportLogsWidgetState extends State<_ExportLogsWidget> {
  _ExportState _state = _ExportState.idle;
  String? _exportedFilePath;
  String? _errorMessage;

  Future<void> _handleExport() async {
    setState(() {
      _state = _ExportState.loading;
      _exportedFilePath = null;
      _errorMessage = null;
    });

    final history = widget.extensionContext.history;

    if (history.isEmpty) {
      setState(() {
        _state = _ExportState.error;
        _errorMessage = 'No logs to export';
      });
      return;
    }

    try {
      // Get export directory
      final directory = await _getExportDirectory();

      if (directory == null) {
        setState(() {
          _state = _ExportState.error;
          _errorMessage = 'Could not access storage';
        });
        return;
      }

      // Generate filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'logs_$timestamp.txt';
      final file = File('${directory.path}/$fileName');

      // Format logs as text
      final buffer = StringBuffer();
      buffer.writeln('In-App Console Logs Export');
      buffer.writeln('Generated: ${DateTime.now()}');
      buffer.writeln('Total Logs: ${history.length}');
      buffer.writeln('${'=' * 80}\n');

      for (var log in history) {
        buffer.writeln(
            '${log.timestamp} [${log.type.name.toUpperCase()}]${log.label != null ? ' [${log.label}]' : ''}');
        buffer.writeln('Message: ${log.message}');

        if (log.error != null) {
          buffer.writeln('Error: ${log.error}');
        }

        if (log.stackTrace != null) {
          buffer.writeln('Stack Trace:\n${log.stackTrace}');
        }

        buffer.writeln('-' * 80);
      }

      // Write to file first
      final writtenFile = await file.writeAsString(buffer.toString());

      bool isExportSuccessful = false;

      // For iOS, share the file via method channel with LinkPresentation
      if (Platform.isIOS) {
        isExportSuccessful = await _shareFileViaMethodChannel(writtenFile.path);
      } else {
        // For Android and other platforms, just check if file exists
        isExportSuccessful = await writtenFile.exists();
      }

      if (!mounted) {
        return;
      }

      if (isExportSuccessful) {
        setState(() {
          _state = _ExportState.success;
          _exportedFilePath = file.path;
        });
        return;
      }

      setState(() {
        _state = _ExportState.error;
        _errorMessage = 'Export failed';
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _ExportState.error;
          _errorMessage = 'Export failed: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.download, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export Logs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Export log history to downloads folder',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // State-based content
            if (_state == _ExportState.loading)
              _buildLoadingWidget()
            else if (_state == _ExportState.success)
              _buildSuccessWidget()
            else if (_state == _ExportState.error)
              _buildErrorWidget()
            else
              _buildIdleWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleWidget() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _handleExport,
        icon: const Icon(Icons.file_download),
        label: const Text('Export to File'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Exporting logs...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessWidget() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Export Successful!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              if (_exportedFilePath != null)
                Text(
                  'Saved to:\n$_exportedFilePath',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() => _state = _ExportState.idle);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Export Again'),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 48,
              ),
              const SizedBox(height: 12),
              const Text(
                'Export Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleExport,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}
