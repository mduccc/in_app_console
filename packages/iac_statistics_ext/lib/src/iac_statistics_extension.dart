import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:path_provider/path_provider.dart';

// ─── Data classes ─────────────────────────────────────────────────────────────

class StatsErrorGroup {
  const StatsErrorGroup({
    required this.message,
    required this.count,
    required this.type,
    required this.lastSeen,
  });

  final String message;
  final int count;
  final InAppLoggerType type;
  final DateTime lastSeen;

  StatsErrorGroup increment(DateTime ts) => StatsErrorGroup(
        message: message,
        count: count + 1,
        type: type,
        lastSeen: ts.isAfter(lastSeen) ? ts : lastSeen,
      );
}

class StatsTimeBucket {
  const StatsTimeBucket({
    required this.start,
    required this.infos,
    required this.warnings,
    required this.errors,
  });

  final DateTime start;
  final int infos;
  final int warnings;
  final int errors;

  int get total => infos + warnings + errors;
}

class StatsModuleHealth {
  const StatsModuleHealth({
    required this.label,
    required this.infos,
    required this.warnings,
    required this.errors,
    required this.score,
  });

  final String label;
  final int infos;
  final int warnings;
  final int errors;
  final double score;

  Color get color {
    if (score >= 0.85) return Colors.green;
    if (score >= 0.60) return Colors.orange;
    return Colors.red;
  }
}

// ─── Algorithm selector ───────────────────────────────────────────────────────

enum GroupingAlgorithm {
  /// Groups messages by normalizing hex addresses and numeric IDs, then exact-matching.
  /// Fast, deterministic, works well for structured/templated log messages.
  fingerprint,

  /// Groups messages using TF-IDF vectors + cosine similarity.
  /// Slower but handles natural-language variation and messages that differ by more than IDs.
  tfidf,
}

// ─── Analytics (pure, @visibleForTesting) ─────────────────────────────────────

class LogAnalytics {
  @visibleForTesting
  static String fingerprint(String message) {
    return message
        .toLowerCase()
        .replaceAll(RegExp(r'0x[0-9a-f]+'), '0x?')
        .replaceAll(RegExp(r'\b\d{4,}\b'), '#')
        .trim();
  }

  @visibleForTesting
  static Map<String, StatsErrorGroup> computeErrorGroups(
      List<InAppLoggerData> logs) {
    final map = <String, StatsErrorGroup>{};
    for (final log in logs) {
      if (log.type == InAppLoggerType.info) continue;
      final key = fingerprint(log.message);
      final existing = map[key];
      if (existing != null) {
        map[key] = existing.increment(log.timestamp);
      } else {
        map[key] = StatsErrorGroup(
          message: log.message,
          count: 1,
          type: log.type,
          lastSeen: log.timestamp,
        );
      }
    }
    return map;
  }

  @visibleForTesting
  static List<StatsTimeBucket> buildTimeBuckets(List<InAppLoggerData> logs) {
    if (logs.length < 2) return [];

    final sorted = [...logs]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final span = sorted.last.timestamp.difference(sorted.first.timestamp);

    final Duration bucketSize;
    final int maxBuckets;
    if (span < const Duration(minutes: 5)) {
      bucketSize = const Duration(seconds: 30);
      maxBuckets = 10;
    } else if (span < const Duration(minutes: 30)) {
      bucketSize = const Duration(minutes: 3);
      maxBuckets = 10;
    } else if (span < const Duration(hours: 3)) {
      bucketSize = const Duration(minutes: 20);
      maxBuckets = 9;
    } else if (span < const Duration(hours: 24)) {
      bucketSize = const Duration(hours: 2);
      maxBuckets = 12;
    } else {
      bucketSize = const Duration(days: 1);
      maxBuckets = 14;
    }

    final startMs = sorted.first.timestamp.millisecondsSinceEpoch;
    final bucketMs = bucketSize.inMilliseconds;

    final bucketMap = <int, Map<String, int>>{};
    for (final log in sorted) {
      final idx = (log.timestamp.millisecondsSinceEpoch - startMs) ~/ bucketMs;
      final bucket = bucketMap.putIfAbsent(idx, () => {'i': 0, 'w': 0, 'e': 0});
      switch (log.type) {
        case InAppLoggerType.info:
          bucket['i'] = bucket['i']! + 1;
        case InAppLoggerType.warning:
          bucket['w'] = bucket['w']! + 1;
        case InAppLoggerType.error:
          bucket['e'] = bucket['e']! + 1;
      }
    }

    final indices = bucketMap.keys.toList()..sort();
    final displayIndices = indices.length > maxBuckets
        ? indices.sublist(indices.length - maxBuckets)
        : indices;

    return displayIndices.map((idx) {
      final b = bucketMap[idx]!;
      return StatsTimeBucket(
        start: DateTime.fromMillisecondsSinceEpoch(startMs + idx * bucketMs),
        infos: b['i']!,
        warnings: b['w']!,
        errors: b['e']!,
      );
    }).toList();
  }

  @visibleForTesting
  static List<StatsModuleHealth> computeModuleHealth(
      List<InAppLoggerData> logs) {
    final map = <String, Map<String, int>>{};
    for (final log in logs) {
      final label = log.label ?? 'Unknown';
      final m = map.putIfAbsent(label, () => {'i': 0, 'w': 0, 'e': 0});
      switch (log.type) {
        case InAppLoggerType.info:
          m['i'] = m['i']! + 1;
        case InAppLoggerType.warning:
          m['w'] = m['w']! + 1;
        case InAppLoggerType.error:
          m['e'] = m['e']! + 1;
      }
    }

    final result = map.entries.map((entry) {
      final i = entry.value['i']!;
      final w = entry.value['w']!;
      final e = entry.value['e']!;
      final total = i + w + e;
      final weightedBad = e * 1.0 + w * 0.3;
      final score =
          total == 0 ? 1.0 : (1.0 - weightedBad / total).clamp(0.0, 1.0);
      return StatsModuleHealth(
        label: entry.key,
        infos: i,
        warnings: w,
        errors: e,
        score: score,
      );
    }).toList()
      ..sort((a, b) => a.score.compareTo(b.score));

    return result.take(8).toList();
  }

  // ─── TF-IDF helpers ─────────────────────────────────────────────────────────

  static List<String> _tokenize(String message) {
    return message
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toList();
  }

  /// IDF = log(N / df) for each term across the corpus.
  static Map<String, double> _computeIdf(List<List<String>> documents) {
    final df = <String, int>{};
    for (final doc in documents) {
      for (final term in doc.toSet()) {
        df[term] = (df[term] ?? 0) + 1;
      }
    }
    final n = documents.length.toDouble();
    return df.map((term, count) => MapEntry(term, log(n / count)));
  }

  /// TF-IDF sparse vector for a single document.
  static Map<String, double> _tfIdfVector(
      List<String> tokens, Map<String, double> idf) {
    if (tokens.isEmpty) return {};
    final tf = <String, int>{};
    for (final t in tokens) {
      tf[t] = (tf[t] ?? 0) + 1;
    }
    final len = tokens.length.toDouble();
    return tf.map((t, count) => MapEntry(t, (count / len) * (idf[t] ?? 0)));
  }

  static double _cosine(Map<String, double> a, Map<String, double> b) {
    if (a.isEmpty || b.isEmpty) return 0;
    double dot = 0, magA = 0, magB = 0;
    for (final e in a.entries) {
      dot += e.value * (b[e.key] ?? 0);
      magA += e.value * e.value;
    }
    for (final v in b.values) {
      magB += v * v;
    }
    if (magA == 0 || magB == 0) return 0;
    return dot / (sqrt(magA) * sqrt(magB));
  }

  /// Groups error/warning logs by TF-IDF cosine similarity.
  /// Messages with [similarity] >= [threshold] are merged into the same group.
  /// The group centroid is updated incrementally as new documents are added.
  @visibleForTesting
  static Map<String, StatsErrorGroup> computeErrorGroupsTfIdf(
    List<InAppLoggerData> logs, {
    double threshold = 0.65,
  }) {
    final errorLogs =
        logs.where((l) => l.type != InAppLoggerType.info).toList();
    if (errorLogs.isEmpty) return {};

    final tokenized = errorLogs.map((l) => _tokenize(l.message)).toList();
    final idf = _computeIdf(tokenized);
    final vectors = tokenized.map((t) => _tfIdfVector(t, idf)).toList();

    // Each entry: (representative StatsErrorGroup, running centroid vector)
    final groups = <(StatsErrorGroup, Map<String, double>)>[];

    for (var i = 0; i < errorLogs.length; i++) {
      final logEntry = errorLogs[i];
      final vec = vectors[i];

      double bestSim = 0;
      int bestIdx = -1;
      for (var j = 0; j < groups.length; j++) {
        final sim = _cosine(vec, groups[j].$2);
        if (sim > bestSim) {
          bestSim = sim;
          bestIdx = j;
        }
      }

      if (bestSim >= threshold && bestIdx >= 0) {
        final (group, centroid) = groups[bestIdx];
        final newCount = group.count + 1;

        // Incremental centroid update: running average of all vectors in group
        final newCentroid = Map<String, double>.from(centroid);
        for (final e in vec.entries) {
          newCentroid[e.key] =
              ((newCentroid[e.key] ?? 0) * (newCount - 1) + e.value) / newCount;
        }
        for (final key in centroid.keys) {
          if (!vec.containsKey(key)) {
            newCentroid[key] = centroid[key]! * (newCount - 1) / newCount;
          }
        }
        groups[bestIdx] = (group.increment(logEntry.timestamp), newCentroid);
      } else {
        groups.add((
          StatsErrorGroup(
            message: logEntry.message,
            count: 1,
            type: logEntry.type,
            lastSeen: logEntry.timestamp,
          ),
          Map<String, double>.from(vec),
        ));
      }
    }

    final result = <String, StatsErrorGroup>{};
    for (var i = 0; i < groups.length; i++) {
      result['group_$i'] = groups[i].$1;
    }
    return result;
  }
}

// ─── Extension ────────────────────────────────────────────────────────────────

class LogStatisticsExtension extends InAppConsoleExtension {
  static const _kStorageFile = 'iac_stats_logs.jsonl';
  static const _kMaxEntries = 500;

  final _controller = StreamController<void>.broadcast();
  final _logs = <InAppLoggerData>[];
  StreamSubscription<InAppLoggerData>? _subscription;

  @override
  String get id => 'iac_statistics_ext';

  @override
  String get name => 'Log Statistics';

  @override
  String get version => '2.1.1';

  @override
  String get description => 'View log statistics and analytics';

  @override
  Widget get icon => const Icon(Icons.analytics_outlined, color: Colors.black);

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    _loadAndSubscribe(extensionContext);
  }

  Future<void> _loadAndSubscribe(
      InAppConsoleExtensionContext extensionContext) async {
    final persisted = await _loadFromFile();
    _logs.addAll(persisted);

    // Persist history logs that were not yet in the file (happened before
    // this extension was registered in the current session).
    final history = extensionContext.history;
    _logs.addAll(history);
    await _appendBatchToFile(history);

    _controller.add(null);

    _subscription = extensionContext.stream.listen((log) {
      _logs.add(log);
      _controller.add(null);
      _appendToFile(log).ignore();
      if (_logs.length > _kMaxEntries) _trimFile().ignore();
    });
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_kStorageFile');
  }

  Future<List<InAppLoggerData>> _loadFromFile() async {
    try {
      final file = await _getFile();
      if (!file.existsSync()) return [];
      final lines = await file.readAsLines();
      final result = <InAppLoggerData>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          result.add(InAppLoggerData(
            message: map['msg'] as String,
            timestamp: DateTime.fromMillisecondsSinceEpoch(map['ts'] as int),
            type: _typeFromString(map['typ'] as String),
            label: map['lbl'] as String?,
          ));
        } catch (_) {
          // skip malformed lines
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> _appendToFile(InAppLoggerData log) async {
    try {
      final file = await _getFile();
      final line = jsonEncode({
        'msg': log.message,
        'ts': log.timestamp.millisecondsSinceEpoch,
        'typ': log.type.name,
        'lbl': log.label,
      });
      await file.writeAsString('$line\n', mode: FileMode.append);
    } catch (_) {}
  }

  Future<void> _appendBatchToFile(List<InAppLoggerData> logs) async {
    if (logs.isEmpty) return;
    try {
      final file = await _getFile();
      final lines = logs
          .map((log) => jsonEncode({
                'msg': log.message,
                'ts': log.timestamp.millisecondsSinceEpoch,
                'typ': log.type.name,
                'lbl': log.label,
              }))
          .join('\n');
      await file.writeAsString('$lines\n', mode: FileMode.append);
    } catch (_) {}
  }

  Future<void> _trimFile() async {
    try {
      final file = await _getFile();
      if (!file.existsSync()) return;
      final lines =
          (await file.readAsLines()).where((l) => l.trim().isNotEmpty).toList();
      if (lines.length <= _kMaxEntries) return;
      final trimmed = lines.sublist(lines.length - _kMaxEntries);
      await file.writeAsString('${trimmed.join('\n')}\n');
      if (_logs.length > _kMaxEntries) {
        _logs.removeRange(0, _logs.length - _kMaxEntries);
      }
    } catch (_) {}
  }

  Future<void> clearHistory() async {
    _logs.clear();
    try {
      final file = await _getFile();
      if (file.existsSync()) await file.delete();
    } catch (_) {}
    _controller.add(null);
  }

  static InAppLoggerType _typeFromString(String s) {
    return switch (s) {
      'error' => InAppLoggerType.error,
      'warning' => InAppLoggerType.warning,
      _ => InAppLoggerType.info,
    };
  }

  @override
  void onDispose() {
    _subscription?.cancel();
    _controller.close();
  }

  @override
  Widget buildWidget(BuildContext context) {
    return _StatisticsPanel(
      stream: _controller.stream,
      logs: _logs,
      onClear: clearHistory,
    );
  }
}

// ─── Panel ────────────────────────────────────────────────────────────────────

// ignore: use_key_in_widget_constructors
class _StatisticsPanel extends StatefulWidget {
  const _StatisticsPanel({
    required this.stream,
    required this.logs,
    required this.onClear,
  });

  final Stream<void> stream;
  final List<InAppLoggerData> logs;
  final Future<void> Function() onClear;

  @override
  State<_StatisticsPanel> createState() => _StatisticsPanelState();
}

class _StatisticsPanelState extends State<_StatisticsPanel> {
  StreamSubscription<void>? _sub;
  GroupingAlgorithm _groupingAlgorithm = GroupingAlgorithm.tfidf;

  void _toggleAlgorithm() {
    setState(() {
      _groupingAlgorithm = _groupingAlgorithm == GroupingAlgorithm.fingerprint
          ? GroupingAlgorithm.tfidf
          : GroupingAlgorithm.fingerprint;
    });
  }

  @override
  void initState() {
    super.initState();
    _sub = widget.stream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logs = widget.logs;
    final total = logs.length;
    final info = logs.where((l) => l.type == InAppLoggerType.info).length;
    final warn = logs.where((l) => l.type == InAppLoggerType.warning).length;
    final err = logs.where((l) => l.type == InAppLoggerType.error).length;

    final errorGroups = _groupingAlgorithm == GroupingAlgorithm.tfidf
        ? LogAnalytics.computeErrorGroupsTfIdf(logs)
        : LogAnalytics.computeErrorGroups(logs);
    final topErrors = (errorGroups.values.toList()
          ..sort((a, b) => b.count.compareTo(a.count)))
        .take(10)
        .toList();

    final buckets = LogAnalytics.buildTimeBuckets(logs);
    final moduleHealth = LogAnalytics.computeModuleHealth(logs);

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
            _Header(onClear: widget.onClear),
            const Divider(height: 24),
            _SummaryRow(total: total, info: info, warning: warn, error: err),
            if (buckets.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _SectionTitle('Log Timeline'),
              const SizedBox(height: 8),
              _TimelineChart(buckets: buckets),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                const _SectionTitle('Top Repeated Issues'),
                const Spacer(),
                _AlgorithmToggle(
                  algorithm: _groupingAlgorithm,
                  onToggle: _toggleAlgorithm,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (topErrors.isNotEmpty)
              _TopRepeatedErrors(groups: topErrors)
            else
              Text(
                'No repeated errors or warnings yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            if (moduleHealth.isNotEmpty) ...[
              const SizedBox(height: 20),
              const _SectionTitle('Module Health'),
              const SizedBox(height: 8),
              _ModuleHealthList(modules: moduleHealth),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

// ignore: use_key_in_widget_constructors
class _Header extends StatelessWidget {
  const _Header({required this.onClear});

  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.analytics, color: Colors.blue, size: 28),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Statistics',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Real-time analytics across sessions',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: 'Clear history',
          onPressed: onClear,
        ),
      ],
    );
  }
}

// ─── Section title ────────────────────────────────────────────────────────────

// ignore: use_key_in_widget_constructors
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey[700],
      ),
    );
  }
}

// ─── Summary row ──────────────────────────────────────────────────────────────

// ignore: use_key_in_widget_constructors
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.total,
    required this.info,
    required this.warning,
    required this.error,
  });

  final int total;
  final int info;
  final int warning;
  final int error;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(total, 'Total', Colors.blue),
        _StatChip(info, 'Info', Colors.green),
        _StatChip(warning, 'Warn', Colors.orange),
        _StatChip(error, 'Errors', Colors.red),
      ],
    );
  }
}

// ignore: use_key_in_widget_constructors
class _StatChip extends StatelessWidget {
  const _StatChip(this.value, this.label, this.color);

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// ─── Top repeated errors ──────────────────────────────────────────────────────

// ignore: use_key_in_widget_constructors
class _TopRepeatedErrors extends StatelessWidget {
  const _TopRepeatedErrors({required this.groups});

  final List<StatsErrorGroup> groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: groups.map((g) {
        final color =
            g.type == InAppLoggerType.error ? Colors.red : Colors.orange;
        final icon =
            g.type == InAppLoggerType.error ? Icons.error : Icons.warning;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  g.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '×${g.count}',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Timeline chart ───────────────────────────────────────────────────────────

// ignore: use_key_in_widget_constructors
class _TimelineChart extends StatelessWidget {
  const _TimelineChart({required this.buckets});

  final List<StatsTimeBucket> buckets;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: CustomPaint(
        painter: _TimelinePainter(buckets: buckets),
        size: Size.infinite,
      ),
    );
  }
}

class _TimelinePainter extends CustomPainter {
  const _TimelinePainter({required this.buckets});

  final List<StatsTimeBucket> buckets;

  static const _chartH = 80.0;
  static const _barGap = 2.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) return;

    final gridPaint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 1;

    for (final pct in [0.25, 0.5, 1.0]) {
      final y = _chartH * (1 - pct);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final maxCount = buckets.map((b) => b.total).reduce(max);
    if (maxCount == 0) return;

    final n = buckets.length;
    final barWidth = size.width / n;

    for (var i = 0; i < n; i++) {
      final bucket = buckets[i];
      final x = i * barWidth;

      double yBottom = _chartH;

      final infoH = (bucket.infos / maxCount) * _chartH;
      final warnH = (bucket.warnings / maxCount) * _chartH;
      final errH = (bucket.errors / maxCount) * _chartH;

      if (infoH > 0) {
        canvas.drawRect(
          Rect.fromLTWH(
              x + _barGap / 2, yBottom - infoH, barWidth - _barGap, infoH),
          Paint()..color = Colors.blue.withValues(alpha: 0.7),
        );
        yBottom -= infoH;
      }
      if (warnH > 0) {
        canvas.drawRect(
          Rect.fromLTWH(
              x + _barGap / 2, yBottom - warnH, barWidth - _barGap, warnH),
          Paint()..color = Colors.orange.withValues(alpha: 0.85),
        );
        yBottom -= warnH;
      }
      if (errH > 0) {
        canvas.drawRect(
          Rect.fromLTWH(
              x + _barGap / 2, yBottom - errH, barWidth - _barGap, errH),
          Paint()..color = Colors.red.withValues(alpha: 0.85),
        );
      }

      // Only draw labels for first, last, and when few enough bars
      if (i == 0 || i == n - 1 || n <= 8) {
        final label = _formatTime(bucket.start);
        final tp = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(fontSize: 9, color: Colors.grey[600]),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(
            (x + barWidth / 2 - tp.width / 2).clamp(0, size.width - tp.width),
            _chartH + 4,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dt) {
    final span = buckets.last.start.difference(buckets.first.start);
    if (span.inDays >= 1) return '${dt.month}/${dt.day}';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  bool shouldRepaint(_TimelinePainter old) => old.buckets != buckets;
}

// ─── Module health list ───────────────────────────────────────────────────────

// ignore: use_key_in_widget_constructors
class _ModuleHealthList extends StatelessWidget {
  const _ModuleHealthList({required this.modules});

  final List<StatsModuleHealth> modules;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: modules.map((m) {
        final pct = (m.score * 100).round();
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: m.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  m.label,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'E:${m.errors} W:${m.warnings} I:${m.infos}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(width: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: m.color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─── Algorithm segmented control ─────────────────────────────────────────────

// ignore: use_key_in_widget_constructors
class _AlgorithmToggle extends StatelessWidget {
  const _AlgorithmToggle({
    required this.algorithm,
    required this.onToggle,
  });

  final GroupingAlgorithm algorithm;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            label: 'TF-IDF',
            active: algorithm == GroupingAlgorithm.tfidf,
            onTap: algorithm == GroupingAlgorithm.tfidf ? null : onToggle,
            isLeft: true,
          ),
          _Segment(
            label: 'Pattern',
            active: algorithm == GroupingAlgorithm.fingerprint,
            onTap: algorithm == GroupingAlgorithm.fingerprint ? null : onToggle,
            isLeft: false,
          ),
        ],
      ),
    );
  }
}

// ignore: use_key_in_widget_constructors
class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
    required this.isLeft,
  });

  final String label;
  final bool active;
  final VoidCallback? onTap;
  final bool isLeft;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(7) : Radius.zero,
            right: isLeft ? Radius.zero : const Radius.circular(7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }
}
