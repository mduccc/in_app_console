import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/logger/in_app_logger_type.dart';

/// Utility class for common InAppConsole operations and styling.
class InAppConsoleUtils {
  /// Get the color associated with a specific logger type.
  static Color getTypeColor(InAppLoggerType type) {
    switch (type) {
      case InAppLoggerType.info:
        return Colors.green;
      case InAppLoggerType.warning:
        return Colors.orange;
      case InAppLoggerType.error:
        return Colors.red;
    }
  }

  /// Get the icon associated with a specific logger type.
  static IconData getTypeIcon(InAppLoggerType type) {
    switch (type) {
      case InAppLoggerType.info:
        return Icons.info;
      case InAppLoggerType.warning:
        return Icons.warning;
      case InAppLoggerType.error:
        return Icons.error;
    }
  }

  /// Get the outlined icon associated with a specific logger type.
  static IconData getTypeOutlineIcon(InAppLoggerType type) {
    switch (type) {
      case InAppLoggerType.info:
        return Icons.info_outline;
      case InAppLoggerType.warning:
        return Icons.warning_outlined;
      case InAppLoggerType.error:
        return Icons.error_outline;
    }
  }

  /// Get the label associated with a specific logger type.
  static String getTypeLabel(InAppLoggerType type) {
    switch (type) {
      case InAppLoggerType.info:
        return 'INFO';
      case InAppLoggerType.warning:
        return 'WARN';
      case InAppLoggerType.error:
        return 'ERROR';
    }
  }

  /// Get the error prefix based on the logger type.
  static String getErrorPrefix(InAppLoggerType type) {
    switch (type) {
      case InAppLoggerType.error:
        return 'Error';
      case InAppLoggerType.warning:
        return 'Warning';
      case InAppLoggerType.info:
        return '';
    }
  }

  /// Copy log data to clipboard with proper formatting.
  static void copyLogToClipboard(BuildContext context, InAppLoggerData log) {
    final buffer = StringBuffer();
    buffer.writeln('[${getTypeLabel(log.type)}] ${log.timestamp}');
    if (log.label != null) {
      buffer.writeln('Label: ${log.label}');
    }
    buffer.writeln(log.message);
    if (log.error != null) {
      buffer.writeln('${getErrorPrefix(log.type)}: ${log.error}');
    }
    if (log.stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(log.stackTrace.toString());
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Log copied to clipboard')),
    );
  }

  /// Format timestamp in HH:mm:ss.SSS format.
  static String formatTimestamp(DateTime timestamp) {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }
}

/// Screen for displaying in app console data.
///
/// Based on the [InAppLoggerData] type, the widget will display the data in a different way.
///
/// [InAppLoggerType.info] will be displayed in a green color.
/// [InAppLoggerType.error] will be displayed in a red color.
/// [InAppLoggerType.warning] will be displayed in a orange color.
///
/// The widget will be scrollable.
///
/// The widget will be updated when the [InAppConsole.stream] emits a new [InAppLoggerData].
///
class InAppConsoleScreen extends StatefulWidget {
  const InAppConsoleScreen({super.key});

  @override
  State<InAppConsoleScreen> createState() => _InAppConsoleScreenState();
}

class _InAppConsoleScreenState extends State<InAppConsoleScreen> {
  final InAppConsole _console = InAppConsole.instance;
  final List<InAppLoggerData> _loggerData = [];
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late StreamSubscription<InAppLoggerData> _streamSubscription;

  // Filter state
  final Set<InAppLoggerType> _visibleTypes = {
    InAppLoggerType.info,
    InAppLoggerType.warning,
    InAppLoggerType.error,
  };

  // Search state
  String _searchQuery = '';
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();

    _loggerData.addAll(_console.history);

    // Auto-scroll to bottom when screen first opens (after build completes)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _streamSubscription = _console.stream.listen((data) {
        setState(() {
          _loggerData.add(data);
        });
      });
      _jumpToBottom();
    });
  }

  void _jumpToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(
        _scrollController.position.maxScrollExtent,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _streamSubscription.cancel();
    super.dispose();
  }

  List<InAppLoggerData> get _filteredData => _loggerData
      .where((data) => _visibleTypes.contains(data.type))
      .where((data) => _matchesSearch(data))
      .toList();

  bool _matchesSearch(InAppLoggerData data) {
    if (_searchQuery.isEmpty) return true;

    final query = _searchQuery.toLowerCase();
    return data.message.toLowerCase().contains(query) ||
        data.label?.toLowerCase().contains(query) == true ||
        data.error?.toString().toLowerCase().contains(query) == true ||
        data.stackTrace?.toString().toLowerCase().contains(query) == true;
  }

  void _clearLogs() {
    setState(() {
      _console.clearHistory();
      _loggerData.clear();
    });
  }

  void _toggleFilter(InAppLoggerType type) {
    setState(() {
      if (_visibleTypes.contains(type)) {
        _visibleTypes.remove(type);
      } else {
        _visibleTypes.add(type);
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (!_isSearchVisible) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _copyLogToClipboard(InAppLoggerData log) {
    InAppConsoleUtils.copyLogToClipboard(context, log);
  }

  void _showLogDetails(InAppLoggerData log) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InAppConsoleDetailScreen(log: log),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _filteredData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('In App Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _toggleSearch,
            tooltip: 'Search logs',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_outlined),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          if (_isSearchVisible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search logs...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _clearSearch,
                                tooltip: 'Clear search',
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleSearch,
                    tooltip: 'Close search',
                  ),
                ],
              ),
            ),
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Filters: ',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...InAppLoggerType.values.map((type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                                showCheckmark: false,
                                label: Text(
                                  InAppConsoleUtils.getTypeLabel(type),
                                  style: TextStyle(
                                    color: _visibleTypes.contains(type)
                                        ? InAppConsoleUtils.getTypeColor(type)
                                        : null,
                                    fontWeight: _visibleTypes.contains(type)
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                selected: _visibleTypes.contains(type),
                                onSelected: (_) => _toggleFilter(type),
                                selectedColor:
                                    InAppConsoleUtils.getTypeColor(type)
                                        .withOpacity(0.3),
                                avatar: Icon(
                                  InAppConsoleUtils.getTypeIcon(type),
                                  size: 16,
                                  color: _visibleTypes.contains(type)
                                      ? InAppConsoleUtils.getTypeColor(type)
                                      : Colors.grey,
                                )),
                          )),
                    ],
                  ),
                ))
              ],
            ),
          ),
          const Divider(height: 1),
          // Logs list
          Expanded(
            child: filteredData.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? 'No logs match your search'
                          : 'No logs available',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        final log = filteredData[index];
                        return _LogItem(
                          log: log,
                          searchQuery: _searchQuery,
                          onTap: () => _showLogDetails(log),
                          onCopy: () => _copyLogToClipboard(log),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final InAppLoggerData log;
  final String searchQuery;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _LogItem({
    required this.log,
    required this.searchQuery,
    required this.onTap,
    required this.onCopy,
  });

  Widget _buildHighlightedText(String text,
      {required TextStyle style, int? maxLines}) {
    if (searchQuery.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: maxLines != null ? TextOverflow.ellipsis : null,
      );
    }

    final query = searchQuery.toLowerCase();
    final textLower = text.toLowerCase();
    final spans = <TextSpan>[];

    int start = 0;
    int index = textLower.indexOf(query, start);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: style,
        ));
      }

      // Add highlighted match
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: style.copyWith(
          backgroundColor: Colors.yellow[300],
          //fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
      index = textLower.indexOf(query, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: style,
      ));
    }

    return Text.rich(
      TextSpan(children: spans, style: style),
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.visible,
      
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = InAppConsoleUtils.getTypeColor(log.type);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: typeColor, width: 4),
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              InAppConsoleUtils.getTypeOutlineIcon(log.type),
              color: typeColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          InAppConsoleUtils.getTypeLabel(log.type),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        InAppConsoleUtils.formatTimestamp(log.timestamp),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (log.label != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!, width: 1),
                      ),
                      child: _buildHighlightedText(
                        log.label!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ],
                  _buildHighlightedText(
                    log.message,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 3,
                  ),
                  if (log.error != null) ...[
                    const SizedBox(height: 4),
                    _buildHighlightedText(
                      '${InAppConsoleUtils.getErrorPrefix(log.type)}: ${log.error}',
                      style: TextStyle(
                        fontSize: 12,
                        color: InAppConsoleUtils.getTypeColor(log.type)
                            .withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              onPressed: onCopy,
              tooltip: 'Copy log',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen for displaying detailed information about a single log entry.
class InAppConsoleDetailScreen extends StatelessWidget {
  final InAppLoggerData log;

  const InAppConsoleDetailScreen({
    super.key,
    required this.log,
  });

  void _copyLogToClipboard(BuildContext context) {
    InAppConsoleUtils.copyLogToClipboard(context, log);
  }

  Widget _buildDetailSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: SelectableText(
            content,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${InAppConsoleUtils.getTypeLabel(log.type)} Details'),
        backgroundColor: InAppConsoleUtils.getTypeColor(log.type),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () => _copyLogToClipboard(context),
            tooltip: 'Copy log',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailSection('Timestamp', log.timestamp.toString()),
            if (log.label != null) ...[
              const SizedBox(height: 16),
              _buildDetailSection('Label', log.label!),
            ],
            const SizedBox(height: 16),
            _buildDetailSection('Message', log.message),
            if (log.error != null) ...[
              const SizedBox(height: 16),
              _buildDetailSection(InAppConsoleUtils.getErrorPrefix(log.type),
                  log.error.toString()),
            ],
            if (log.stackTrace != null) ...[
              const SizedBox(height: 16),
              _buildDetailSection('Stack Trace', log.stackTrace.toString()),
            ],
          ],
        ),
      ),
    );
  }
}
