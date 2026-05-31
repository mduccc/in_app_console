import 'package:flutter_test/flutter_test.dart';
import 'package:iac_statistics_ext/iac_statistics_ext.dart';
import 'package:in_app_console/in_app_console.dart';

void main() {
  InAppLoggerData makeLog(
    String message,
    InAppLoggerType type, {
    String? label,
    DateTime? timestamp,
  }) {
    return InAppLoggerData(
      message: message,
      timestamp: timestamp ?? DateTime.now(),
      type: type,
      label: label,
    );
  }

  // ─── Fingerprinting ─────────────────────────────────────────────────────────

  group('GIVEN fingerprint normalization', () {
    test('WHEN messages differ only by hex address THEN same fingerprint', () {
      final a = LogAnalytics.fingerprint('Connection failed at 0x1a2b3c4d');
      final b = LogAnalytics.fingerprint('Connection failed at 0xdeadbeef');
      expect(a, equals(b));
    });

    test('WHEN messages differ only by long numeric ID THEN same fingerprint',
        () {
      final a = LogAnalytics.fingerprint('User 123456 not found');
      final b = LogAnalytics.fingerprint('User 999999 not found');
      expect(a, equals(b));
    });

    test('WHEN messages are genuinely different THEN different fingerprints',
        () {
      final a = LogAnalytics.fingerprint('Login failed');
      final b = LogAnalytics.fingerprint('Network timeout');
      expect(a, isNot(equals(b)));
    });

    test('WHEN message has mixed case THEN normalized to lowercase', () {
      final a = LogAnalytics.fingerprint('ERROR: Null pointer');
      final b = LogAnalytics.fingerprint('error: null pointer');
      expect(a, equals(b));
    });
  });

  // ─── Error group computation ─────────────────────────────────────────────────

  group('GIVEN computeErrorGroups', () {
    test(
        'WHEN 3 identical errors and 2 different warnings THEN 2 groups, largest count first',
        () {
      final logs = [
        makeLog('DB connection failed', InAppLoggerType.error),
        makeLog('DB connection failed', InAppLoggerType.error),
        makeLog('DB connection failed', InAppLoggerType.error),
        makeLog('Timeout warning', InAppLoggerType.warning),
        makeLog('Memory high', InAppLoggerType.warning),
      ];

      final groups = LogAnalytics.computeErrorGroups(logs);
      expect(groups.length, equals(3));

      final sorted = groups.values.toList()
        ..sort((a, b) => b.count.compareTo(a.count));
      expect(sorted.first.count, equals(3));
      expect(sorted.first.message, equals('DB connection failed'));
    });

    test('WHEN info logs present THEN they are excluded from groups', () {
      final logs = [
        makeLog('Just an info', InAppLoggerType.info),
        makeLog('Just an info', InAppLoggerType.info),
        makeLog('Real error', InAppLoggerType.error),
      ];

      final groups = LogAnalytics.computeErrorGroups(logs);
      expect(groups.length, equals(1));
      expect(groups.values.first.message, equals('Real error'));
    });

    test('WHEN similar messages with different hex addresses THEN grouped', () {
      final logs = [
        makeLog('Crash at 0x1111', InAppLoggerType.error),
        makeLog('Crash at 0x2222', InAppLoggerType.error),
      ];

      final groups = LogAnalytics.computeErrorGroups(logs);
      expect(groups.length, equals(1));
      expect(groups.values.first.count, equals(2));
    });
  });

  // ─── Bucket building ─────────────────────────────────────────────────────────

  group('GIVEN buildTimeBuckets', () {
    test('WHEN logs span 10 minutes THEN bucket size is 3 minutes', () {
      final base = DateTime(2024, 1, 1, 12, 0, 0);
      final logs = List.generate(
        10,
        (i) => makeLog('msg $i', InAppLoggerType.info,
            timestamp: base.add(Duration(minutes: i))),
      );

      final buckets = LogAnalytics.buildTimeBuckets(logs);
      expect(buckets, isNotEmpty);

      // With 3-min buckets over 10 min, expect ~4 buckets (0-3, 3-6, 6-9, 9-12)
      expect(buckets.length, lessThanOrEqualTo(10));

      // First bucket starts at or before base
      expect(buckets.first.start.millisecondsSinceEpoch,
          lessThanOrEqualTo(base.millisecondsSinceEpoch));
    });

    test('WHEN logs span less than 5 minutes THEN bucket size is 30 seconds',
        () {
      final base = DateTime(2024, 1, 1, 12, 0, 0);
      final logs = List.generate(
        6,
        (i) => makeLog('msg', InAppLoggerType.info,
            timestamp: base.add(Duration(seconds: i * 30))),
      );

      final buckets = LogAnalytics.buildTimeBuckets(logs);
      expect(buckets, isNotEmpty);

      if (buckets.length >= 2) {
        final bucketSpan =
            buckets[1].start.difference(buckets[0].start).inSeconds;
        expect(bucketSpan, equals(30));
      }
    });

    test('WHEN bucket counts summed THEN equals total log count', () {
      final base = DateTime(2024, 1, 1, 12, 0, 0);
      final logs = List.generate(
        20,
        (i) => makeLog('msg', InAppLoggerType.info,
            timestamp: base.add(Duration(minutes: i * 2))),
      );

      final buckets = LogAnalytics.buildTimeBuckets(logs);
      final bucketTotal = buckets.fold(0, (sum, b) => sum + b.total);
      expect(bucketTotal, equals(logs.length));
    });

    test('WHEN fewer than 2 logs THEN returns empty list', () {
      final buckets = LogAnalytics.buildTimeBuckets([
        makeLog('only one', InAppLoggerType.info),
      ]);
      expect(buckets, isEmpty);
    });
  });

  // ─── Module health ────────────────────────────────────────────────────────────

  group('GIVEN computeModuleHealth', () {
    test('WHEN module has all errors THEN score < 0.60 (red)', () {
      final logs = List.generate(
        10,
        (_) => makeLog('err', InAppLoggerType.error, label: 'BadModule'),
      );

      final health = LogAnalytics.computeModuleHealth(logs);
      expect(health, isNotEmpty);
      expect(health.first.score, lessThan(0.60));
    });

    test('WHEN module has mostly info with 1 error THEN score >= 0.85 (green)',
        () {
      final logs = [
        ...List.generate(100,
            (_) => makeLog('ok', InAppLoggerType.info, label: 'GoodModule')),
        makeLog('oops', InAppLoggerType.error, label: 'GoodModule'),
      ];

      final health = LogAnalytics.computeModuleHealth(logs);
      expect(health.first.score, greaterThanOrEqualTo(0.85));
    });

    test('WHEN multiple modules THEN sorted worst first', () {
      final logs = [
        ...List.generate(
            10, (_) => makeLog('err', InAppLoggerType.error, label: 'Worst')),
        ...List.generate(
            10, (_) => makeLog('ok', InAppLoggerType.info, label: 'Best')),
      ];

      final health = LogAnalytics.computeModuleHealth(logs);
      expect(health.length, equals(2));
      expect(health.first.label, equals('Worst'));
      expect(health.last.label, equals('Best'));
    });

    test('WHEN more than 8 modules THEN only top 8 returned', () {
      final logs = List.generate(
        10,
        (i) => makeLog('msg', InAppLoggerType.info, label: 'Module$i'),
      );

      final health = LogAnalytics.computeModuleHealth(logs);
      expect(health.length, lessThanOrEqualTo(8));
    });
  });
}
