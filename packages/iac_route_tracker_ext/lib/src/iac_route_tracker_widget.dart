import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'iac_route_tracker_navigation_observer.dart';

class IacRouteTrackerWidget extends StatefulWidget {
  const IacRouteTrackerWidget({super.key, required this.observer});

  final IacRouteTrackerNavigationObserver observer;

  @override
  State<IacRouteTrackerWidget> createState() => _IacRouteTrackerWidgetState();
}

class _IacRouteTrackerWidgetState extends State<IacRouteTrackerWidget> {
  late List<IacRouteStackEntry> _routeStack;
  late List<IacRouteHistoryEntry> _routeHistory;
  late StreamSubscription<void> _subscription;
  bool _historyCopied = false;
  bool _stackCopied = false;

  @override
  void initState() {
    super.initState();
    _routeStack = widget.observer.routeStack;
    _routeHistory = widget.observer.routeHistory;

    _subscription = widget.observer.routeStackStream.listen((_) {
      if (!mounted) return;
      setState(() {
        _routeStack = widget.observer.routeStack;
        _routeHistory = widget.observer.routeHistory;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _copyStack() async {
    if (_routeStack.isEmpty) return;
    final buffer = StringBuffer();
    for (var i = _routeStack.length - 1; i >= 0; i--) {
      final entry = _routeStack[i];
      final label = i == _routeStack.length - 1 ? ' [TOP]' : '';
      buffer.writeln(
          '[$i]$label  ${entry.routeName.isEmpty ? '(no name)' : entry.routeName}');
      if (entry.payload != null) buffer.writeln('  payload: ${entry.payload}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    setState(() => _stackCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _stackCopied = false);
  }

  Future<void> _copyHistory() async {
    if (_routeHistory.isEmpty) return;
    final buffer = StringBuffer();
    for (final entry in _routeHistory) {
      final t = entry.timestamp;
      final time =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
      final action = entry.isPush ? 'PUSH' : 'POP';
      buffer.writeln(
          '[$time] $action  ${entry.routeName.isEmpty ? '(no name)' : entry.routeName}');
      if (entry.payload != null) buffer.writeln('  payload: ${entry.payload}');
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    setState(() => _historyCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _historyCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SectionHeader(
                      title: 'Current Stack', count: _routeStack.length),
                ),
                if (_routeStack.isNotEmpty)
                  GestureDetector(
                    onTap: _copyStack,
                    child: Icon(
                      _stackCopied ? Icons.check : Icons.copy_outlined,
                      size: 15,
                      color:
                          _stackCopied ? Colors.green[600] : Colors.grey[400],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_routeStack.isEmpty)
              const _EmptyState(message: 'Stack is empty')
            else
              ..._routeStack.reversed.toList().asMap().entries.map(
                    (entry) => _StackEntry(
                      index: _routeStack.length - 1 - entry.key,
                      stackEntry: entry.value,
                      isTop: entry.key == 0,
                    ),
                  ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _SectionHeader(
                      title: 'History', count: _routeHistory.length),
                ),
                if (_routeHistory.isNotEmpty)
                  GestureDetector(
                    onTap: _copyHistory,
                    child: Icon(
                      _historyCopied ? Icons.check : Icons.copy_outlined,
                      size: 15,
                      color:
                          _historyCopied ? Colors.green[600] : Colors.grey[400],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_routeHistory.isEmpty)
              const _EmptyState(message: 'No navigation events yet')
            else
              ..._routeHistory.reversed.toList().map(
                    (entry) => _HistoryEntry(entry: entry),
                  ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.route, color: Colors.black87, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Route Tracker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Navigation routes and deep links',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$title ($count)',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[400],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _StackEntry extends StatelessWidget {
  const _StackEntry({
    required this.index,
    required this.stackEntry,
    required this.isTop,
  });

  final int index;
  final IacRouteStackEntry stackEntry;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    final isNameEmpty = stackEntry.routeName.isEmpty;
    final hasPayload = stackEntry.payload != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isTop ? Colors.black87 : Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isTop ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isNameEmpty ? '(no name)' : stackEntry.routeName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isTop ? FontWeight.w500 : FontWeight.normal,
                    color: isNameEmpty ? Colors.grey[400] : null,
                    fontStyle:
                        isNameEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              if (isTop)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'TOP',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
            ],
          ),
          if (hasPayload)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stackEntry.payload.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({required this.entry});

  final IacRouteHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final isPush = entry.isPush;
    final color = isPush ? Colors.blue[600]! : Colors.red[400]!;
    final icon = isPush ? Icons.arrow_upward : Icons.arrow_downward;
    final label = isPush ? 'PUSH' : 'POP';
    final t = entry.timestamp;
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    final isNameEmpty = entry.routeName.isEmpty;
    final hasPayload = entry.payload != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isNameEmpty ? '(no name)' : entry.routeName,
                  style: TextStyle(
                    fontSize: 13,
                    color: isNameEmpty
                        ? Colors.grey[400]
                        : isPush
                            ? Colors.blue[600]
                            : Colors.red[400],
                    fontStyle:
                        isNameEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
          if (hasPayload)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.payload.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
