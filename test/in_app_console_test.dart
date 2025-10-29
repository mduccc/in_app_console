import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/console/in_app_console_internal.dart';
import 'package:in_app_console/src/ui/in_app_console_screen.dart';
import 'dart:async';

void main() {
  group('InAppLoggerData', () {
    group('GIVEN a InAppLoggerData instance', () {
      test(
          'WHEN created with required parameters THEN should have correct values',
          () {
        // Arrange
        final timestamp = DateTime.now();
        const message = 'Test message';
        const type = InAppLoggerType.info;

        // Act
        final loggerData = InAppLoggerData(
          message: message,
          timestamp: timestamp,
          type: type,
        );

        // Assert
        expect(loggerData.message, equals(message));
        expect(loggerData.timestamp, equals(timestamp));
        expect(loggerData.type, equals(type));
        expect(loggerData.label, isNull);
        expect(loggerData.error, isNull);
        expect(loggerData.stackTrace, isNull);
      });

      test('WHEN created with all parameters THEN should have all values set',
          () {
        // Arrange
        final timestamp = DateTime.now();
        const message = 'Test error message';
        const type = InAppLoggerType.error;
        const label = 'TEST_LABEL';
        final error = ArgumentError('Test error');
        final stackTrace = StackTrace.current;

        // Act
        final loggerData = InAppLoggerData(
          message: message,
          timestamp: timestamp,
          type: type,
          label: label,
          error: error,
          stackTrace: stackTrace,
        );

        // Assert
        expect(loggerData.message, equals(message));
        expect(loggerData.timestamp, equals(timestamp));
        expect(loggerData.type, equals(type));
        expect(loggerData.label, equals(label));
        expect(loggerData.error, equals(error));
        expect(loggerData.stackTrace, equals(stackTrace));
      });
    });
  });

  group('InAppLoggerType', () {
    group('GIVEN InAppLoggerType enum', () {
      test('WHEN accessing values THEN should have correct enum values', () {
        // Assert
        expect(InAppLoggerType.values.length, equals(3));
        expect(InAppLoggerType.values, contains(InAppLoggerType.info));
        expect(InAppLoggerType.values, contains(InAppLoggerType.warning));
        expect(InAppLoggerType.values, contains(InAppLoggerType.error));
      });

      test('WHEN comparing enum values THEN should be equal to themselves', () {
        // Assert
        expect(InAppLoggerType.info, equals(InAppLoggerType.info));
        expect(InAppLoggerType.warning, equals(InAppLoggerType.warning));
        expect(InAppLoggerType.error, equals(InAppLoggerType.error));
      });
    });
  });

  group('InAppLogger', () {
    late InAppLogger logger;

    setUp(() {
      InAppConsole.kEnableConsole = true;
      logger = InAppLogger();
    });

    group('GIVEN a new InAppLogger instance', () {
      test('WHEN created THEN should have empty label and active stream', () {
        // Assert
        expect(logger.label, isEmpty);
        expect(logger.stream, isA<Stream<InAppLoggerData>>());
      });

      test('WHEN setLabel is called THEN should update label', () {
        // Arrange
        const testLabel = 'AUTH_SERVICE';

        // Act
        logger.setLabel(testLabel);

        // Assert
        expect(logger.label, equals(testLabel));
      });
    });

    group('WHEN logging info messages', () {
      test('THEN should emit InAppLoggerData with correct type and message',
          () async {
        // Arrange
        const message = 'Info test message';
        final streamFuture = logger.stream.first;

        // Act
        logger.logInfo(message);

        // Assert
        final loggerData = await streamFuture;
        expect(loggerData.message, equals(message));
        expect(loggerData.type, equals(InAppLoggerType.info));
        expect(loggerData.timestamp, isA<DateTime>());
        expect(loggerData.label, isNull);
        expect(loggerData.error, isNull);
        expect(loggerData.stackTrace, isNull);
      });

      test('THEN should emit InAppLoggerData with label when label is set',
          () async {
        // Arrange
        const message = 'Info with label';
        const label = 'TEST_LABEL';
        logger.setLabel(label);
        final streamFuture = logger.stream.first;

        // Act
        logger.logInfo(message);

        // Assert
        final loggerData = await streamFuture;
        expect(loggerData.message, equals(message));
        expect(loggerData.type, equals(InAppLoggerType.info));
        expect(loggerData.label, equals(label));
      });
    });

    group('WHEN logging error messages', () {
      test('THEN should emit InAppLoggerData with error type', () async {
        // Arrange
        const message = 'Error test message';
        final streamFuture = logger.stream.first;

        // Act
        logger.logError(message: message);

        // Assert
        final loggerData = await streamFuture;
        expect(loggerData.message, equals(message));
        expect(loggerData.type, equals(InAppLoggerType.error));
        expect(loggerData.error, isNull);
        expect(loggerData.stackTrace, isNull);
      });

      test(
          'THEN should emit InAppLoggerData with error and stackTrace when provided',
          () async {
        // Arrange
        const message = 'Error with details';
        final error = ArgumentError('Test error');
        final stackTrace = StackTrace.current;
        final streamFuture = logger.stream.first;

        // Act
        logger.logError(
          message: message,
          error: error,
          stackTrace: stackTrace,
        );

        // Assert
        final loggerData = await streamFuture;
        expect(loggerData.message, equals(message));
        expect(loggerData.type, equals(InAppLoggerType.error));
        expect(loggerData.error, equals(error));
        expect(loggerData.stackTrace, equals(stackTrace));
      });
    });

    group('WHEN logging warning messages', () {
      test('THEN should emit InAppLoggerData with warning type', () async {
        // Arrange
        const message = 'Warning test message';
        final streamFuture = logger.stream.first;

        // Act
        logger.logWarning(message: message);

        // Assert
        final loggerData = await streamFuture;
        expect(loggerData.message, equals(message));
        expect(loggerData.type, equals(InAppLoggerType.warning));
        expect(loggerData.error, isNull);
        expect(loggerData.stackTrace, isNull);
      });

      test(
          'THEN should emit InAppLoggerData with error and stackTrace when provided',
          () async {
        // Arrange
        const message = 'Warning with details';
        final error = StateError('Test warning');
        final stackTrace = StackTrace.current;
        final streamFuture = logger.stream.first;

        // Act
        logger.logWarning(
          message: message,
          error: error,
          stackTrace: stackTrace,
        );

        // Assert
        final loggerData = await streamFuture;
        expect(loggerData.message, equals(message));
        expect(loggerData.type, equals(InAppLoggerType.warning));
        expect(loggerData.error, equals(error));
        expect(loggerData.stackTrace, equals(stackTrace));
      });
    });

    group('WHEN logging multiple messages', () {
      test('THEN should emit all messages in order', () async {
        // Arrange
        const messages = ['First message', 'Second message', 'Third message'];
        final receivedMessages = <String>[];
        final completer = Completer<void>();

        // Act
        logger.stream.listen((data) {
          receivedMessages.add(data.message);
          if (receivedMessages.length == messages.length) {
            completer.complete();
          }
        });

        for (final message in messages) {
          logger.logInfo(message);
        }

        await completer.future;

        // Assert
        expect(receivedMessages, equals(messages));
      });
    });
  });

  group('InAppConsole', () {
    late InAppConsoleInternal console;

    setUp(() {
      console = InAppConsole.instance as InAppConsoleInternal;
      InAppConsole.kEnableConsole = true;
      console.clearLogs();
    });

    group('GIVEN InAppConsole singleton', () {
      test('WHEN accessing instance THEN should return same instance', () {
        // Act
        final instance1 = InAppConsole.instance;
        final instance2 = InAppConsole.instance;

        // Assert
        expect(instance1, same(instance2));
      });

      test('WHEN created THEN should have empty history and active stream', () {
        // Assert
        expect(console.history, isEmpty);
        expect(console.stream, isA<Stream<InAppLoggerData>>());
      });
    });

    group('WHEN managing loggers', () {
      test('THEN should add logger and receive its messages', () async {
        // Arrange
        final logger = InAppLogger();
        logger.setLabel('TEST');
        const message = 'Test message from logger';
        final streamFuture = console.stream.first;

        // Act
        console.addLogger(logger);
        logger.logInfo(message);

        // Assert
        final loggerData = await streamFuture;
        expect(loggerData.message, equals(message));
        expect(loggerData.label, equals('TEST'));
        expect(console.history.length, equals(1));
        expect(console.history.first.message, equals(message));
      });

      test('THEN should not add same logger twice', () async {
        // Arrange
        final logger = InAppLogger();
        const message = 'Test message';
        final receivedMessages = <String>[];

        final subscription = console.stream.listen((data) {
          receivedMessages.add(data.message);
        });

        // Act
        console.addLogger(logger);
        console.addLogger(logger); // Try to add again
        logger.logInfo(message);

        // Wait for message to be processed
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(receivedMessages.length, equals(1));
        expect(console.history.length, equals(1));

        // Clean up
        await subscription.cancel();
      });

      test('THEN should remove logger and stop receiving its messages',
          () async {
        // Arrange
        final logger = InAppLogger();
        const message1 = 'Before removal';
        const message2 = 'After removal';

        console.addLogger(logger);
        logger.logInfo(message1);

        // Wait for first message
        await Future.delayed(const Duration(milliseconds: 50));
        expect(console.history.length, equals(1));

        // Act - Remove logger
        console.removeLogger(logger);

        // Try to add the same logger again - this should work now
        console.addLogger(logger);
        logger.logInfo(message2);

        // Wait for second message
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - The logger should be re-addable after removal
        expect(console.history.length, equals(2));
        expect(console.history[0].message, equals(message1));
        expect(console.history[1].message, equals(message2));
      });
    });

    group('WHEN managing history', () {
      test('THEN should clear history when clearHistory is called', () async {
        // Arrange
        final logger = InAppLogger();
        console.addLogger(logger);
        logger.logInfo('Message 1');
        logger.logInfo('Message 2');

        // Wait for messages to be processed
        await Future.delayed(const Duration(milliseconds: 50));
        expect(console.history.length, equals(2));

        // Act
        console.clearLogs();

        // Assert
        expect(console.history, isEmpty);
      });

      test('THEN should maintain history across multiple loggers', () async {
        // Arrange
        final logger1 = InAppLogger();
        final logger2 = InAppLogger();
        logger1.setLabel('LOGGER1');
        logger2.setLabel('LOGGER2');

        console.addLogger(logger1);
        console.addLogger(logger2);

        // Act
        logger1.logInfo('Message from logger 1');
        logger2.logError(message: 'Error from logger 2');

        // Wait for messages to be processed
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(console.history.length, equals(2));
        expect(console.history[0].label, equals('LOGGER1'));
        expect(console.history[1].label, equals('LOGGER2'));
        expect(console.history[0].type, equals(InAppLoggerType.info));
        expect(console.history[1].type, equals(InAppLoggerType.error));
      });
    });
  });

  group('InAppConsoleUtils', () {
    group('GIVEN InAppConsoleUtils', () {
      test('WHEN getTypeColor is called THEN should return correct colors', () {
        // Assert
        expect(InAppConsoleUtils.getTypeColor(InAppLoggerType.info),
            equals(Colors.green));
        expect(InAppConsoleUtils.getTypeColor(InAppLoggerType.warning),
            equals(Colors.orange));
        expect(InAppConsoleUtils.getTypeColor(InAppLoggerType.error),
            equals(Colors.red));
      });

      test('WHEN getTypeIcon is called THEN should return correct icons', () {
        // Assert
        expect(InAppConsoleUtils.getTypeIcon(InAppLoggerType.info),
            equals(Icons.info));
        expect(InAppConsoleUtils.getTypeIcon(InAppLoggerType.warning),
            equals(Icons.warning));
        expect(InAppConsoleUtils.getTypeIcon(InAppLoggerType.error),
            equals(Icons.error));
      });

      test(
          'WHEN getTypeOutlineIcon is called THEN should return correct outline icons',
          () {
        // Assert
        expect(InAppConsoleUtils.getTypeOutlineIcon(InAppLoggerType.info),
            equals(Icons.info_outline));
        expect(InAppConsoleUtils.getTypeOutlineIcon(InAppLoggerType.warning),
            equals(Icons.warning_outlined));
        expect(InAppConsoleUtils.getTypeOutlineIcon(InAppLoggerType.error),
            equals(Icons.error_outline));
      });

      test('WHEN getTypeLabel is called THEN should return correct labels', () {
        // Assert
        expect(InAppConsoleUtils.getTypeLabel(InAppLoggerType.info),
            equals('INFO'));
        expect(InAppConsoleUtils.getTypeLabel(InAppLoggerType.warning),
            equals('WARN'));
        expect(InAppConsoleUtils.getTypeLabel(InAppLoggerType.error),
            equals('ERROR'));
      });

      test('WHEN getErrorPrefix is called THEN should return correct prefixes',
          () {
        // Assert
        expect(
            InAppConsoleUtils.getErrorPrefix(InAppLoggerType.info), equals(''));
        expect(InAppConsoleUtils.getErrorPrefix(InAppLoggerType.warning),
            equals('Warning'));
        expect(InAppConsoleUtils.getErrorPrefix(InAppLoggerType.error),
            equals('Error'));
      });

      test('WHEN formatTimestamp is called THEN should format correctly', () {
        // Arrange
        final timestamp = DateTime(2023, 10, 15, 14, 30, 45, 123);

        // Act
        final formatted = InAppConsoleUtils.formatTimestamp(timestamp);

        // Assert
        expect(formatted, equals('14:30:45.123'));
      });

      test(
          'WHEN formatTimestamp is called with single digits THEN should pad correctly',
          () {
        // Arrange
        final timestamp = DateTime(2023, 1, 1, 9, 5, 3, 7);

        // Act
        final formatted = InAppConsoleUtils.formatTimestamp(timestamp);

        // Assert
        expect(formatted, equals('09:05:03.007'));
      });
    });
  });

  group('Integration Tests', () {
    group('GIVEN a complete logging scenario', () {
      test(
          'WHEN multiple services log messages THEN console should aggregate all logs',
          () async {
        // Arrange
        final InAppConsoleInternal console =
            InAppConsole.instance as InAppConsoleInternal;
        console.clearLogs();

        final authLogger = InAppLogger()..setLabel('AUTH');
        final paymentLogger = InAppLogger()..setLabel('PAYMENT');
        final userLogger = InAppLogger()..setLabel('USER');

        console.addLogger(authLogger);
        console.addLogger(paymentLogger);
        console.addLogger(userLogger);

        final receivedLogs = <InAppLoggerData>[];
        final completer = Completer<void>();

        console.stream.listen((data) {
          receivedLogs.add(data);
          if (receivedLogs.length == 6) {
            completer.complete();
          }
        });

        // Act - Simulate microservice interaction flow
        authLogger.logInfo('Login attempt started');
        userLogger.logInfo('Fetching user profile');
        authLogger.logInfo('Login successful');
        paymentLogger.logInfo('Payment request received');
        paymentLogger.logWarning(message: 'Gateway response slow');
        paymentLogger.logInfo('Payment completed successfully');

        await completer.future;

        // Assert
        expect(receivedLogs.length, equals(6));
        expect(console.history.length, equals(6));

        // Verify we have messages from all services (order might vary)
        final authMessages =
            receivedLogs.where((log) => log.label == 'AUTH').toList();
        final userMessages =
            receivedLogs.where((log) => log.label == 'USER').toList();
        final paymentMessages =
            receivedLogs.where((log) => log.label == 'PAYMENT').toList();

        expect(authMessages.length, equals(2));
        expect(userMessages.length, equals(1));
        expect(paymentMessages.length, equals(3));

        // Verify specific message content
        expect(
            authMessages.any((log) => log.message == 'Login attempt started'),
            isTrue);
        expect(authMessages.any((log) => log.message == 'Login successful'),
            isTrue);
        expect(userMessages.first.message, equals('Fetching user profile'));
        expect(
            paymentMessages
                .any((log) => log.message == 'Payment request received'),
            isTrue);
        expect(
            paymentMessages.any((log) =>
                log.message == 'Gateway response slow' &&
                log.type == InAppLoggerType.warning),
            isTrue);
        expect(
            paymentMessages
                .any((log) => log.message == 'Payment completed successfully'),
            isTrue);
      });

      test('WHEN logger is removed THEN should stop receiving its messages',
          () async {
        // Arrange
        final InAppConsoleInternal console =
            InAppConsole.instance as InAppConsoleInternal;
        console.clearLogs();

        final logger1 = InAppLogger()..setLabel('SERVICE1');
        final logger2 = InAppLogger()..setLabel('SERVICE2');

        console.addLogger(logger1);
        console.addLogger(logger2);

        // Log some initial messages
        logger1.logInfo('Message 1 from service 1');
        logger2.logInfo('Message 1 from service 2');

        await Future.delayed(const Duration(milliseconds: 50));
        expect(console.history.length, equals(2));

        // Act - Remove one logger
        console.removeLogger(logger1);

        // Log more messages - only logger2 should be received
        logger1.logInfo('This should not appear in new logs');
        logger2.logInfo('This should appear');

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Should only have 3 total messages (2 initial + 1 from logger2)
        expect(console.history.length, equals(3));
        expect(console.history.last.label, equals('SERVICE2'));
        expect(console.history.last.message, equals('This should appear'));

        // Verify no new messages from removed logger
        final service1Messages =
            console.history.where((log) => log.label == 'SERVICE1').toList();
        expect(service1Messages.length, equals(1)); // Only the initial message
      });
    });
  });

  group('InAppConsole.kEnableConsole = false', () {
    late InAppConsoleInternal console;

    setUp(() {
      console = InAppConsole.instance as InAppConsoleInternal;
      console.clearLogs();
    });

    tearDown(() {
      // Reset to true for other tests
      InAppConsole.kEnableConsole = true;
    });

    group('GIVEN kEnableConsole is set to false', () {
      test('WHEN logger emits messages THEN should NOT add to history',
          () async {
        // Arrange
        InAppConsole.kEnableConsole = false;
        final logger = InAppLogger();
        console.addLogger(logger);

        // Act
        logger.logInfo('This should not be recorded');
        logger.logError(message: 'This error should not be recorded');
        logger.logWarning(message: 'This warning should not be recorded');

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(console.history, isEmpty);
      });

      test('WHEN logger emits messages THEN should NOT emit to console stream',
          () async {
        // Arrange
        InAppConsole.kEnableConsole = false;
        final logger = InAppLogger();
        console.addLogger(logger);

        final receivedMessages = <InAppLoggerData>[];
        final subscription = console.stream.listen((data) {
          receivedMessages.add(data);
        });

        // Act
        logger.logInfo('Message 1');
        logger.logInfo('Message 2');
        logger.logError(message: 'Error message');

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(receivedMessages, isEmpty);

        // Clean up
        await subscription.cancel();
      });

      test('WHEN multiple loggers emit messages THEN none should be recorded',
          () async {
        // Arrange
        InAppConsole.kEnableConsole = false;

        final logger1 = InAppLogger()..setLabel('SERVICE1');
        final logger2 = InAppLogger()..setLabel('SERVICE2');
        final logger3 = InAppLogger()..setLabel('SERVICE3');

        console.addLogger(logger1);
        console.addLogger(logger2);
        console.addLogger(logger3);

        final receivedMessages = <InAppLoggerData>[];
        final subscription = console.stream.listen((data) {
          receivedMessages.add(data);
        });

        // Act
        logger1.logInfo('Service 1 message');
        logger2.logWarning(message: 'Service 2 warning');
        logger3.logError(message: 'Service 3 error');

        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(console.history, isEmpty);
        expect(receivedMessages, isEmpty);

        // Clean up
        await subscription.cancel();
      });

      testWidgets(
          'WHEN openConsole is called THEN should return immediately without navigation',
          (tester) async {
        // Arrange
        InAppConsole.kEnableConsole = false;

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: Text('Test')),
          ),
        );

        final context = tester.element(find.byType(Scaffold));

        // Act
        final result = console.openConsole(context);

        // Assert - Should complete immediately
        await expectLater(result, completes);

        // Verify no navigation occurred
        await tester.pumpAndSettle();
        expect(find.byType(InAppConsoleScreen), findsNothing);
      });

      test(
          'WHEN kEnableConsole is toggled from false to true THEN should start recording',
          () async {
        // Arrange
        InAppConsole.kEnableConsole = false;
        final logger = InAppLogger()..setLabel('TEST');
        console.addLogger(logger);

        // Act - Log while disabled
        logger.logInfo('Message while disabled');
        await Future.delayed(const Duration(milliseconds: 50));
        expect(console.history, isEmpty);

        // Enable console
        InAppConsole.kEnableConsole = true;

        // Need to re-add logger after enabling to activate the subscription behavior
        console.removeLogger(logger);
        console.addLogger(logger);

        // Log while enabled
        logger.logInfo('Message while enabled');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(console.history.length, equals(1));
        expect(console.history.first.message, equals('Message while enabled'));
      });

      test(
          'WHEN kEnableConsole is toggled from true to false THEN should stop recording',
          () async {
        // Arrange
        InAppConsole.kEnableConsole = true;
        final logger = InAppLogger()..setLabel('TEST');
        console.addLogger(logger);

        // Act - Log while enabled
        logger.logInfo('Message while enabled');
        await Future.delayed(const Duration(milliseconds: 50));
        expect(console.history.length, equals(1));

        // Disable console
        InAppConsole.kEnableConsole = false;

        // Log while disabled
        logger.logInfo('Message while disabled');
        logger.logError(message: 'Error while disabled');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - Should still only have 1 message
        expect(console.history.length, equals(1));
        expect(console.history.first.message, equals('Message while enabled'));
      });

      test(
          'WHEN clearHistory is called with kEnableConsole false THEN should still clear history',
          () async {
        // Arrange - First add some history while enabled
        InAppConsole.kEnableConsole = true;
        final logger = InAppLogger();
        console.addLogger(logger);

        logger.logInfo('Message 1');
        logger.logInfo('Message 2');
        await Future.delayed(const Duration(milliseconds: 50));
        expect(console.history.length, equals(2));

        // Now disable console
        InAppConsole.kEnableConsole = false;

        // Act
        console.clearLogs();

        // Assert
        expect(console.history, isEmpty);
      });

      test(
          'WHEN multiple loggers added with kEnableConsole false THEN loggers should still be registered',
          () async {
        // Arrange
        InAppConsole.kEnableConsole = false;

        final logger1 = InAppLogger()..setLabel('LOGGER1');
        final logger2 = InAppLogger()..setLabel('LOGGER2');

        // Act
        console.addLogger(logger1);
        console.addLogger(logger2);

        // Emit messages (should not be recorded)
        logger1.logInfo('Test 1');
        logger2.logInfo('Test 2');
        await Future.delayed(const Duration(milliseconds: 50));
        expect(console.history, isEmpty);

        // Now enable and emit again
        InAppConsole.kEnableConsole = true;
        logger1.logInfo('Test 3');
        logger2.logInfo('Test 4');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - Should receive the new messages
        expect(console.history.length, equals(2));
        expect(console.history[0].message, equals('Test 3'));
        expect(console.history[1].message, equals('Test 4'));
      });

      test(
          'WHEN removeLogger is called with kEnableConsole false THEN should still remove logger',
          () async {
        // Arrange
        InAppConsole.kEnableConsole = false;
        final logger = InAppLogger()..setLabel('TEST');

        console.addLogger(logger);
        logger.logInfo('Message 1');
        await Future.delayed(const Duration(milliseconds: 50));
        expect(console.history, isEmpty);

        // Act - Remove logger
        console.removeLogger(logger);

        // Enable console and try to re-add
        InAppConsole.kEnableConsole = true;
        console.addLogger(logger);
        logger.logInfo('After re-add');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - Should work normally after re-add
        expect(console.history.length, equals(1));
        expect(console.history.first.message, equals('After re-add'));
      });
    });

    group('GIVEN production environment simulation', () {
      test(
          'WHEN app is in production mode with kEnableConsole false THEN no performance impact from logging',
          () async {
        // Arrange - Simulate production setting
        InAppConsole.kEnableConsole = false;

        final services = List.generate(20, (index) {
          final logger = InAppLogger()..setLabel('SERVICE_$index');
          console.addLogger(logger);
          return logger;
        });

        // Act - Simulate heavy logging in production
        final stopwatch = Stopwatch()..start();

        for (final service in services) {
          for (int i = 0; i < 100; i++) {
            service.logInfo('High frequency message $i');
            service.logError(message: 'Error $i', error: Exception('Test'));
            service.logWarning(message: 'Warning $i');
          }
        }

        await Future.delayed(const Duration(milliseconds: 100));
        stopwatch.stop();

        // Assert - No history accumulated
        expect(console.history, isEmpty);

        // Performance should be good (logging disabled = minimal overhead)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test(
          'WHEN switching from development to production THEN history persists but new logs are blocked',
          () async {
        // Arrange - Development mode
        InAppConsole.kEnableConsole = true;
        final logger = InAppLogger()..setLabel('APP');
        console.addLogger(logger);

        // Log in development
        logger.logInfo('Development log 1');
        logger.logInfo('Development log 2');
        await Future.delayed(const Duration(milliseconds: 50));
        expect(console.history.length, equals(2));

        // Act - Switch to production
        InAppConsole.kEnableConsole = false;

        // Try to log in production
        logger.logInfo('Production log (should not appear)');
        logger.logError(message: 'Production error (should not appear)');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert - Old history persists, new logs blocked
        expect(console.history.length, equals(2));
        expect(console.history[0].message, equals('Development log 1'));
        expect(console.history[1].message, equals('Development log 2'));
      });
    });
  });

  group('InAppConsole Extensions', () {
    late InAppConsoleInternal console;

    setUp(() {
      console = InAppConsole.instance as InAppConsoleInternal;
      InAppConsole.kEnableConsole = true;
      console.clearLogs();

      // Clear any registered extensions
      final extensions = console.getExtensions();
      for (final ext in extensions) {
        console.unregisterExtension(ext);
      }
    });

    tearDown(() {
      // Clean up extensions
      final extensions = console.getExtensions();
      for (final ext in extensions) {
        console.unregisterExtension(ext);
      }
    });

    group('GIVEN an extension', () {
      test(
          'WHEN registering an extension THEN it should be registered successfully',
          () {
        // Arrange
        final extension = TestExtension();

        // Act
        console.registerExtension(extension);

        // Assert
        final extensions = console.getExtensions();
        expect(extensions.length, equals(1));
        expect(extensions.first.id, equals('test_extension'));
        expect(extensions.first.name, equals('Test Extension'));
        expect(extensions.first.version, equals('1.0.0'));
      });

      test('WHEN registering an extension THEN onInit should be called', () {
        // Arrange
        final extension = TestExtension();

        // Act
        console.registerExtension(extension);

        // Assert
        expect(extension.initCalled, isTrue);
        expect(extension.disposeCalled, isFalse);
      });

      test(
          'WHEN registering duplicate extension THEN registration should be skipped',
          () {
        // Arrange
        final extension1 = TestExtension();
        final extension2 = TestExtension(); // Same ID

        // Act
        console.registerExtension(extension1);
        console.registerExtension(extension2);

        // Assert
        final extensions = console.getExtensions();
        expect(extensions.length, equals(1));
        expect(extension1.initCalled, isTrue);
        expect(extension2.initCalled, isFalse); // Should not be initialized
      });

      test(
          'WHEN registering multiple unique extensions THEN all should be registered',
          () {
        // Arrange
        final extension1 = TestExtension();
        final extension2 = AnotherTestExtension();
        final extension3 = ThirdTestExtension();

        // Act
        console.registerExtension(extension1);
        console.registerExtension(extension2);
        console.registerExtension(extension3);

        // Assert
        final extensions = console.getExtensions();
        expect(extensions.length, equals(3));
        expect(extension1.initCalled, isTrue);
        expect(extension2.initCalled, isTrue);
        expect(extension3.initCalled, isTrue);
      });

      test('WHEN unregistering an extension THEN it should be removed', () {
        // Arrange
        final extension = TestExtension();
        console.registerExtension(extension);
        expect(console.getExtensions().length, equals(1));

        // Act
        console.unregisterExtension(extension);

        // Assert
        final extensions = console.getExtensions();
        expect(extensions.length, equals(0));
        expect(extension.disposeCalled, isTrue);
      });

      test('WHEN unregistering non-existent extension THEN should not throw',
          () {
        // Arrange
        final extension = TestExtension();

        // Act & Assert - Should not throw
        expect(() => console.unregisterExtension(extension), returnsNormally);
      });

      test(
          'WHEN unregistering one of multiple extensions THEN only that extension should be removed',
          () {
        // Arrange
        final extension1 = TestExtension();
        final extension2 = AnotherTestExtension();
        final extension3 = ThirdTestExtension();
        console.registerExtension(extension1);
        console.registerExtension(extension2);
        console.registerExtension(extension3);

        // Act
        console.unregisterExtension(extension2);

        // Assert
        final extensions = console.getExtensions();
        expect(extensions.length, equals(2));
        expect(extensions.any((e) => e.id == 'test_extension'), isTrue);
        expect(
            extensions.any((e) => e.id == 'another_test_extension'), isFalse);
        expect(extensions.any((e) => e.id == 'third_test_extension'), isTrue);
        expect(extension2.disposeCalled, isTrue);
      });

      test('WHEN building widget THEN buildWidget should be callable', () {
        // Arrange
        final extension = TestExtension();
        console.registerExtension(extension);

        // Act
        final widget = extension.buildWidget(MockBuildContext());

        // Assert
        expect(widget, isA<Container>());
        expect(extension.buildWidgetCalled, isTrue);
      });

      test(
          'WHEN re-registering unregistered extension THEN should register successfully',
          () {
        // Arrange
        final extension = TestExtension();
        console.registerExtension(extension);
        console.unregisterExtension(extension);
        extension.reset(); // Reset state

        // Act
        console.registerExtension(extension);

        // Assert
        final extensions = console.getExtensions();
        expect(extensions.length, equals(1));
        expect(extension.initCalled, isTrue);
      });

      test(
          'WHEN getting extensions THEN should return list in registration order',
          () {
        // Arrange
        final extension1 = TestExtension();
        final extension2 = AnotherTestExtension();
        final extension3 = ThirdTestExtension();

        // Act
        console.registerExtension(extension1);
        console.registerExtension(extension2);
        console.registerExtension(extension3);

        // Assert
        final extensions = console.getExtensions();
        expect(extensions[0].id, equals('test_extension'));
        expect(extensions[1].id, equals('another_test_extension'));
        expect(extensions[2].id, equals('third_test_extension'));
      });

      test('WHEN extension has description THEN should be accessible', () {
        // Arrange
        final extension = TestExtensionWithDescription();
        console.registerExtension(extension);

        // Assert
        expect(
            extension.description, equals('A test extension with description'));
      });
    });

    group('GIVEN multiple extensions', () {
      test(
          'WHEN all extensions are registered THEN lifecycle methods should be called in order',
          () {
        // Arrange
        final extension1 = TestExtension();
        final extension2 = AnotherTestExtension();
        final extension3 = ThirdTestExtension();

        // Act
        console.registerExtension(extension1);
        console.registerExtension(extension2);
        console.registerExtension(extension3);

        // Assert
        expect(extension1.initCalled, isTrue);
        expect(extension2.initCalled, isTrue);
        expect(extension3.initCalled, isTrue);
        expect(extension1.disposeCalled, isFalse);
        expect(extension2.disposeCalled, isFalse);
        expect(extension3.disposeCalled, isFalse);
      });

      test(
          'WHEN all extensions are unregistered THEN onDispose should be called for all',
          () {
        // Arrange
        final extension1 = TestExtension();
        final extension2 = AnotherTestExtension();
        final extension3 = ThirdTestExtension();
        console.registerExtension(extension1);
        console.registerExtension(extension2);
        console.registerExtension(extension3);

        // Act
        console.unregisterExtension(extension1);
        console.unregisterExtension(extension2);
        console.unregisterExtension(extension3);

        // Assert
        expect(extension1.disposeCalled, isTrue);
        expect(extension2.disposeCalled, isTrue);
        expect(extension3.disposeCalled, isTrue);
      });
    });
  });
}

// Test extension classes
class TestExtension extends InAppConsoleExtension {
  bool initCalled = false;
  bool disposeCalled = false;
  bool buildWidgetCalled = false;

  @override
  String get id => 'test_extension';

  @override
  String get name => 'Test Extension';

  @override
  String get version => '1.0.0';

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    initCalled = true;
  }

  @override
  void onDispose() {
    disposeCalled = true;
  }

  @override
  Widget buildWidget(BuildContext context) {
    buildWidgetCalled = true;
    return Container();
  }

  void reset() {
    initCalled = false;
    disposeCalled = false;
    buildWidgetCalled = false;
  }
}

class AnotherTestExtension extends InAppConsoleExtension {
  bool initCalled = false;
  bool disposeCalled = false;

  @override
  String get id => 'another_test_extension';

  @override
  String get name => 'Another Test Extension';

  @override
  String get version => '2.0.0';

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    initCalled = true;
  }

  @override
  void onDispose() {
    disposeCalled = true;
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Container();
  }
}

class ThirdTestExtension extends InAppConsoleExtension {
  bool initCalled = false;
  bool disposeCalled = false;

  @override
  String get id => 'third_test_extension';

  @override
  String get name => 'Third Test Extension';

  @override
  String get version => '3.0.0';

  @override
  void onInit(InAppConsoleExtensionContext extensionContext) {
    initCalled = true;
  }

  @override
  void onDispose() {
    disposeCalled = true;
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Container();
  }
}

class TestExtensionWithDescription extends InAppConsoleExtension {
  @override
  String get id => 'test_extension_with_description';

  @override
  String get name => 'Test Extension With Description';

  @override
  String get version => '1.0.0';

  @override
  String get description => 'A test extension with description';

  @override
  Widget buildWidget(BuildContext context) {
    return Container();
  }
}

class MockBuildContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
