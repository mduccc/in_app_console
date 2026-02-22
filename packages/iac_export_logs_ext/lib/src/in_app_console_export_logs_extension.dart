import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

enum _SaveState { idle, error }

enum _ShareState { idle, error }

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
  String get version => '2.0.0';

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
  _SaveState _saveState = _SaveState.idle;
  _ShareState _shareState = _ShareState.idle;
  String? _saveErrorMessage;
  String? _shareErrorMessage;

  String _formatLogs() {
    final history = widget.extensionContext.history;
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

    return buffer.toString();
  }

  Future<void> _handleSave() async {
    setState(() {
      _saveErrorMessage = null;
    });

    final history = widget.extensionContext.history;

    if (history.isEmpty) {
      setState(() {
        _saveState = _SaveState.error;
        _saveErrorMessage = 'No logs to export';
      });
      return;
    }

    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'logs_$timestamp.txt';

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(_formatLogs());

      final params = SaveFileDialogParams(sourceFilePath: tempFile.path);
      final savedFilePath = await FlutterFileDialog.saveFile(params: params);
      await tempFile.delete();

      if (!mounted) return;

      if (savedFilePath == null) {
        setState(() => _saveState = _SaveState.idle);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saveState = _SaveState.error;
          _saveErrorMessage = 'Export failed: $e';
        });
      }
    }
  }

  Future<void> _handleShare() async {
    setState(() {
      _shareErrorMessage = null;
      _shareState = _ShareState.idle;
    });

    final history = widget.extensionContext.history;

    if (history.isEmpty) {
      setState(() {
        _shareState = _ShareState.error;
        _shareErrorMessage = 'No logs to share';
      });
      return;
    }

    try {
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'logs_$timestamp.txt';

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsString(_formatLogs());

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(tempFile.path)],
        ),
      );

      await tempFile.delete();
    } catch (e) {
      if (mounted) {
        setState(() {
          _shareState = _ShareState.error;
          _shareErrorMessage = 'Share failed: $e';
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
                        'Save logs to a file via native dialog',
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

            // Save state-based content
            if (_saveState == _SaveState.error)
              _buildSaveErrorWidget()
            else
              _buildIdleWidget(),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleWidget() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _handleSave,
            icon: const Icon(Icons.save_alt),
            label: const Text('Save as file'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _handleShare,
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
            ),
          ),
        ),
        if (_shareState == _ShareState.error && _shareErrorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            _shareErrorMessage!,
            style: TextStyle(fontSize: 12, color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildSaveErrorWidget() {
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
              if (_saveErrorMessage != null)
                Text(
                  _saveErrorMessage!,
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
            onPressed: _handleSave,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}
