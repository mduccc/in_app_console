import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/logger/in_app_logger_type.dart';
import 'package:in_app_console/src/ui/in_app_console_screen.dart';
import 'dart:async';

void main() {
  group('InAppLoggerData', () {
    group('GIVEN a InAppLoggerData instance', () {
      test('WHEN created with required parameters THEN should have correct values', () {
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

      test('WHEN created with all parameters THEN should have all values set', () {
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
      test('THEN should emit InAppLoggerData with correct type and message', () async {
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

      test('THEN should emit InAppLoggerData with label when label is set', () async {
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

      test('THEN should emit InAppLoggerData with error and stackTrace when provided', () async {
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

      test('THEN should emit InAppLoggerData with error and stackTrace when provided', () async {
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
    late InAppConsole console;

    setUp(() {
      console = InAppConsole.instance;
      console.clearHistory();
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

      test('THEN should remove logger and stop receiving its messages', () async {
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
        console.clearHistory();

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
        expect(InAppConsoleUtils.getTypeColor(InAppLoggerType.info), equals(Colors.green));
        expect(InAppConsoleUtils.getTypeColor(InAppLoggerType.warning), equals(Colors.orange));
        expect(InAppConsoleUtils.getTypeColor(InAppLoggerType.error), equals(Colors.red));
      });

      test('WHEN getTypeIcon is called THEN should return correct icons', () {
        // Assert
        expect(InAppConsoleUtils.getTypeIcon(InAppLoggerType.info), equals(Icons.info));
        expect(InAppConsoleUtils.getTypeIcon(InAppLoggerType.warning), equals(Icons.warning));
        expect(InAppConsoleUtils.getTypeIcon(InAppLoggerType.error), equals(Icons.error));
      });

      test('WHEN getTypeOutlineIcon is called THEN should return correct outline icons', () {
        // Assert
        expect(InAppConsoleUtils.getTypeOutlineIcon(InAppLoggerType.info), equals(Icons.info_outline));
        expect(InAppConsoleUtils.getTypeOutlineIcon(InAppLoggerType.warning), equals(Icons.warning_outlined));
        expect(InAppConsoleUtils.getTypeOutlineIcon(InAppLoggerType.error), equals(Icons.error_outline));
      });

      test('WHEN getTypeLabel is called THEN should return correct labels', () {
        // Assert
        expect(InAppConsoleUtils.getTypeLabel(InAppLoggerType.info), equals('INFO'));
        expect(InAppConsoleUtils.getTypeLabel(InAppLoggerType.warning), equals('WARN'));
        expect(InAppConsoleUtils.getTypeLabel(InAppLoggerType.error), equals('ERROR'));
      });

      test('WHEN getErrorPrefix is called THEN should return correct prefixes', () {
        // Assert
        expect(InAppConsoleUtils.getErrorPrefix(InAppLoggerType.info), equals(''));
        expect(InAppConsoleUtils.getErrorPrefix(InAppLoggerType.warning), equals('Warning'));
        expect(InAppConsoleUtils.getErrorPrefix(InAppLoggerType.error), equals('Error'));
      });

      test('WHEN formatTimestamp is called THEN should format correctly', () {
        // Arrange
        final timestamp = DateTime(2023, 10, 15, 14, 30, 45, 123);

        // Act
        final formatted = InAppConsoleUtils.formatTimestamp(timestamp);

        // Assert
        expect(formatted, equals('14:30:45.123'));
      });

      test('WHEN formatTimestamp is called with single digits THEN should pad correctly', () {
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
      test('WHEN multiple services log messages THEN console should aggregate all logs', () async {
        // Arrange
        final console = InAppConsole.instance;
        console.clearHistory();
        
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
        final authMessages = receivedLogs.where((log) => log.label == 'AUTH').toList();
        final userMessages = receivedLogs.where((log) => log.label == 'USER').toList();
        final paymentMessages = receivedLogs.where((log) => log.label == 'PAYMENT').toList();
        
        expect(authMessages.length, equals(2));
        expect(userMessages.length, equals(1));
        expect(paymentMessages.length, equals(3));
        
        // Verify specific message content
        expect(authMessages.any((log) => log.message == 'Login attempt started'), isTrue);
        expect(authMessages.any((log) => log.message == 'Login successful'), isTrue);
        expect(userMessages.first.message, equals('Fetching user profile'));
        expect(paymentMessages.any((log) => log.message == 'Payment request received'), isTrue);
        expect(paymentMessages.any((log) => log.message == 'Gateway response slow' && log.type == InAppLoggerType.warning), isTrue);
        expect(paymentMessages.any((log) => log.message == 'Payment completed successfully'), isTrue);
      });

      test('WHEN logger is removed THEN should stop receiving its messages', () async {
        // Arrange
        final console = InAppConsole.instance;
        console.clearHistory();
        
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
        final service1Messages = console.history.where((log) => log.label == 'SERVICE1').toList();
        expect(service1Messages.length, equals(1)); // Only the initial message
      });
    });
  });
}
