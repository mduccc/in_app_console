import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/console/in_app_console_internal.dart';
import 'package:in_app_console/src/ui/in_app_console_extensions_screen.dart';

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
  final InAppConsoleInternal _console =
      InAppConsole.instance as InAppConsoleInternal;
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
  final Set<String> _selectedLabels = {};

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
      .where((data) =>
          _selectedLabels.isEmpty || _selectedLabels.contains(data.label))
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
      _console.clearLogs();
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

  void _toggleLabelFilter(String label) {
    setState(() {
      if (_selectedLabels.contains(label)) {
        _selectedLabels.remove(label);
      } else {
        _selectedLabels.add(label);
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

  void _navigateToExtensions() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InAppConsoleExtensionsScreen(),
      ),
    );
  }

  int get _activeFilterCount =>
      (InAppLoggerType.values.length - _visibleTypes.length) +
      _selectedLabels.length;

  void _resetFilters() {
    _visibleTypes
      ..clear()
      ..addAll(InAppLoggerType.values);
    _selectedLabels.clear();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (_, setSheetState) {
          final labels = _console.labels;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Text(
                      'Filter logs',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (_activeFilterCount > 0)
                      GestureDetector(
                        onTap: () {
                          setState(_resetFilters);
                          setSheetState(() {});
                        },
                        child: Text(
                          'Reset',
                          style:
                              TextStyle(fontSize: 14, color: Colors.blue[600]),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'TYPE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[400],
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: InAppLoggerType.values.map((type) {
                    final selected = _visibleTypes.contains(type);
                    final color = InAppConsoleUtils.getTypeColor(type);
                    return FilterChip(
                      showCheckmark: false,
                      label: Text(
                        InAppConsoleUtils.getTypeLabel(type),
                        style: TextStyle(
                          fontSize: 13,
                          color: selected ? color : Colors.grey[600],
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) {
                        _toggleFilter(type);
                        setSheetState(() {});
                      },
                      selectedColor: color.withValues(alpha: 0.1),
                      backgroundColor: Colors.grey[50],
                      side: BorderSide(
                        color: selected
                            ? color.withValues(alpha: 0.4)
                            : Colors.grey[200]!,
                      ),
                      avatar: Icon(
                        InAppConsoleUtils.getTypeIcon(type),
                        size: 15,
                        color: selected ? color : Colors.grey[400],
                      ),
                    );
                  }).toList(),
                ),
                if (labels.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'LABEL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[400],
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: labels.map((label) {
                      final selected = _selectedLabels.contains(label);
                      return FilterChip(
                        showCheckmark: false,
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                selected ? Colors.blue[700] : Colors.grey[600],
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) {
                          _toggleLabelFilter(label);
                          setSheetState(() {});
                        },
                        selectedColor: Colors.blue.withValues(alpha: 0.08),
                        backgroundColor: Colors.grey[50],
                        side: BorderSide(
                          color: selected
                              ? Colors.blue.withValues(alpha: 0.35)
                              : Colors.grey[200]!,
                        ),
                        avatar: Icon(
                          Icons.label_outline,
                          size: 15,
                          color: selected ? Colors.blue[600] : Colors.grey[400],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredData = _filteredData;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'In App Console',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey[200]),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.extension_outlined),
            onPressed: _navigateToExtensions,
            tooltip: 'Extensions',
          ),
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.search_off : Icons.search,
            ),
            onPressed: _toggleSearch,
            tooltip: 'Search logs',
          ),
          Badge(
            isLabelVisible: _activeFilterCount > 0,
            label: Text('$_activeFilterCount'),
            alignment: const AlignmentDirectional(1.0, -0.6),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterSheet,
              tooltip: 'Filter logs',
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search logs...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey[400], size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: Colors.grey[400], size: 18),
                          onPressed: _clearSearch,
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: Colors.grey[400]!, width: 1.5),
                  ),
                ),
              ),
            ),
          if (_isSearchVisible)
            Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          // Logs list
          Expanded(
            child: filteredData.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No logs match your search'
                              : 'No logs yet',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
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
        padding: const EdgeInsets.fromLTRB(0, 10, 8, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            left: BorderSide(color: typeColor, width: 3),
            bottom: BorderSide(color: Colors.grey[100]!, width: 1),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          InAppConsoleUtils.getTypeLabel(log.type),
                          style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (log.label != null) ...[
                        const SizedBox(width: 6),
                        _buildHighlightedText(
                          log.label!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        InAppConsoleUtils.formatTimestamp(log.timestamp),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildHighlightedText(
                    log.message,
                    style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey[850] ?? Colors.black87),
                    maxLines: 3,
                  ),
                  if (log.error != null) ...[
                    const SizedBox(height: 3),
                    _buildHighlightedText(
                      '${InAppConsoleUtils.getErrorPrefix(log.type)}: ${log.error}',
                      style: TextStyle(
                        fontSize: 12,
                        color: typeColor.withValues(alpha: 0.75),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            GestureDetector(
              onTap: onCopy,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Icon(Icons.copy_outlined,
                    size: 15, color: Colors.grey[350]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen for displaying detailed information about a single log entry.
class InAppConsoleDetailScreen extends StatefulWidget {
  final InAppLoggerData log;

  const InAppConsoleDetailScreen({
    super.key,
    required this.log,
  });

  @override
  State<InAppConsoleDetailScreen> createState() =>
      _InAppConsoleDetailScreenState();
}

class _InAppConsoleDetailScreenState extends State<InAppConsoleDetailScreen> {
  bool _copied = false;

  Future<void> _copyLogToClipboard() async {
    final buffer = StringBuffer();
    final log = widget.log;
    buffer.writeln(
        '[${InAppConsoleUtils.getTypeLabel(log.type)}] ${log.timestamp}');
    if (log.label != null) buffer.writeln('Label: ${log.label}');
    buffer.writeln(log.message);
    if (log.error != null) {
      buffer.writeln(
          '${InAppConsoleUtils.getErrorPrefix(log.type)}: ${log.error}');
    }
    if (log.stackTrace != null) {
      buffer.writeln('Stack Trace:');
      buffer.writeln(log.stackTrace.toString());
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Widget _buildDetailSection(String title, String content,
      {Color? titleColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: titleColor ?? Colors.grey[500],
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
                fontFamily: 'monospace', fontSize: 13, color: Colors.grey[800]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = InAppConsoleUtils.getTypeColor(widget.log.type);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: typeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${InAppConsoleUtils.getTypeLabel(widget.log.type)} Details',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
            ),
          ],
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Colors.grey[200]),
        ),
        actions: [
          IconButton(
            icon: Icon(_copied ? Icons.check : Icons.copy_outlined,
                color: _copied ? Colors.green[600] : null),
            onPressed: _copyLogToClipboard,
            tooltip: 'Copy log',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailSection('TIMESTAMP', widget.log.timestamp.toString()),
            if (widget.log.label != null) ...[
              const SizedBox(height: 16),
              _buildDetailSection('LABEL', widget.log.label!),
            ],
            const SizedBox(height: 16),
            _buildDetailSection('MESSAGE', widget.log.message),
            if (widget.log.error != null) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                  InAppConsoleUtils.getErrorPrefix(widget.log.type)
                      .toUpperCase(),
                  widget.log.error.toString(),
                  titleColor: typeColor),
            ],
            if (widget.log.stackTrace != null) ...[
              const SizedBox(height: 16),
              _buildDetailSection(
                  'STACK TRACE', widget.log.stackTrace.toString()),
            ],
          ],
        ),
      ),
    );
  }
}
