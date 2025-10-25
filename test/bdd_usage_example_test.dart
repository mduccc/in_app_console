import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/console/in_app_console_internal.dart';
import 'package:in_app_console/src/core/logger/in_app_logger_type.dart';
import 'dart:async';

/// Example BDD-style tests demonstrating how to use the InAppConsole package
/// in a real-world microservice architecture scenario.
///
/// This shows the proper BDD structure using GIVEN-WHEN-THEN format.
void main() {
  group('Microservice Logging Scenario', () {
    group('GIVEN a Flutter app with multiple microservices', () {
      late InAppConsoleInternal console;
      late InAppLogger authService;
      late InAppLogger paymentService;
      late InAppLogger userService;

      setUp(() {
        console = InAppConsole.instance as InAppConsoleInternal;
        InAppConsole.kEnableConsole = true;
        console.clearLogs();
        
        // Initialize microservices with their own loggers
        authService = InAppLogger()..setLabel('AUTH');
        paymentService = InAppLogger()..setLabel('PAYMENT');
        userService = InAppLogger()..setLabel('USER');
        
        // Register all services with the console
        console.addLogger(authService);
        console.addLogger(paymentService);
        console.addLogger(userService);
      });

      group('WHEN user performs a complete purchase flow', () {
        test('THEN all microservices should log their activities correctly', () async {
          // Arrange
          final loggedMessages = <InAppLoggerData>[];
          final completer = Completer<void>();
          
          console.stream.listen((data) {
            loggedMessages.add(data);
            if (loggedMessages.length == 8) {
              completer.complete();
            }
          });

          // Act - Simulate complete user purchase flow
          authService.logInfo('User login attempt started');
          authService.logInfo('Credentials validated successfully');
          userService.logInfo('User profile loaded');
          userService.logInfo('User preferences retrieved');
          paymentService.logInfo('Payment method validation started');
          paymentService.logWarning(message: 'Payment gateway latency detected');
          paymentService.logInfo('Payment processed successfully');
          userService.logInfo('Purchase history updated');

          await completer.future;

          // Assert - Verify all services logged correctly
          expect(loggedMessages.length, equals(8));
          expect(console.history.length, equals(8));
          
          // Verify service distribution
          final authLogs = loggedMessages.where((log) => log.label == 'AUTH').toList();
          final userLogs = loggedMessages.where((log) => log.label == 'USER').toList();
          final paymentLogs = loggedMessages.where((log) => log.label == 'PAYMENT').toList();
          
          expect(authLogs.length, equals(2));
          expect(userLogs.length, equals(3));
          expect(paymentLogs.length, equals(3));
          
          // Verify message types
          expect(authLogs.every((log) => log.type == InAppLoggerType.info), isTrue);
          expect(userLogs.every((log) => log.type == InAppLoggerType.info), isTrue);
          expect(paymentLogs.where((log) => log.type == InAppLoggerType.warning).length, equals(1));
          expect(paymentLogs.where((log) => log.type == InAppLoggerType.info).length, equals(2));
        });
      });

      group('WHEN an error occurs during the flow', () {
        test('THEN error should be logged with proper context', () async {
          // Arrange
          final error = StateError('Payment gateway timeout');
          final stackTrace = StackTrace.current;
          final streamFuture = console.stream.first;

          // Act
          paymentService.logError(
            message: 'Payment processing failed',
            error: error,
            stackTrace: stackTrace,
          );

          // Assert
          final loggedData = await streamFuture;
          expect(loggedData.type, equals(InAppLoggerType.error));
          expect(loggedData.label, equals('PAYMENT'));
          expect(loggedData.message, equals('Payment processing failed'));
          expect(loggedData.error, equals(error));
          expect(loggedData.stackTrace, equals(stackTrace));
        });
      });

      group('WHEN a service is temporarily disabled', () {
        test('THEN it should stop logging but allow re-enabling', () async {
          // Arrange
          authService.logInfo('Service active');
          await Future.delayed(const Duration(milliseconds: 50));
          expect(console.history.length, equals(1));

          // Act - Disable service
          console.removeLogger(authService);
          authService.logInfo('This should not appear');
          
          // Re-enable service
          console.addLogger(authService);
          authService.logInfo('Service re-enabled');
          
          await Future.delayed(const Duration(milliseconds: 50));

          // Assert
          expect(console.history.length, equals(2));
          expect(console.history.first.message, equals('Service active'));
          expect(console.history.last.message, equals('Service re-enabled'));
        });
      });
    });
  });

  group('Performance and Scalability', () {
    group('GIVEN multiple concurrent services', () {
      test('WHEN many services log simultaneously THEN all messages should be captured', () async {
        // Arrange
        final InAppConsoleInternal console = InAppConsole.instance as InAppConsoleInternal;
        InAppConsole.kEnableConsole = true;
        console.clearLogs();
        
        final services = List.generate(10, (index) {
          final logger = InAppLogger()..setLabel('SERVICE_$index');
          console.addLogger(logger);
          return logger;
        });
        
        final expectedMessageCount = services.length * 5; // 5 messages per service
        final completer = Completer<void>();
        int receivedCount = 0;
        
        console.stream.listen((data) {
          receivedCount++;
          if (receivedCount == expectedMessageCount) {
            completer.complete();
          }
        });

        // Act - All services log messages simultaneously
        for (int i = 0; i < services.length; i++) {
          final service = services[i];
          for (int j = 0; j < 5; j++) {
            service.logInfo('Message $j from service $i');
          }
        }

        await completer.future;

        // Assert
        expect(console.history.length, equals(expectedMessageCount));
        
        // Verify each service logged the correct number of messages
        for (int i = 0; i < services.length; i++) {
          final serviceLogs = console.history.where((log) => log.label == 'SERVICE_$i').toList();
          expect(serviceLogs.length, equals(5));
        }
      });
    });
  });

  group('Production Mode with kEnableConsole = false', () {
    group('GIVEN a production environment', () {
      late InAppConsoleInternal console;
      late InAppLogger authService;
      late InAppLogger paymentService;
      late InAppLogger userService;

      setUp(() {
        console = InAppConsole.instance as InAppConsoleInternal;
        InAppConsole.kEnableConsole = false; // Production mode
        console.clearLogs();
        
        // Initialize services
        authService = InAppLogger()..setLabel('AUTH');
        paymentService = InAppLogger()..setLabel('PAYMENT');
        userService = InAppLogger()..setLabel('USER');
        
        // Register services
        console.addLogger(authService);
        console.addLogger(paymentService);
        console.addLogger(userService);
      });

      tearDown(() {
        // Reset for other tests
        InAppConsole.kEnableConsole = true;
      });

      group('WHEN services log messages in production', () {
        test('THEN no logs should be captured to save resources', () async {
          // Arrange
          final receivedMessages = <InAppLoggerData>[];
          final subscription = console.stream.listen((data) {
            receivedMessages.add(data);
          });

          // Act - Simulate production logging
          authService.logInfo('User authentication started');
          paymentService.logInfo('Processing payment');
          userService.logInfo('Loading user profile');
          authService.logError(message: 'Authentication failed', error: Exception('Invalid credentials'));
          
          await Future.delayed(const Duration(milliseconds: 100));

          // Assert
          expect(console.history, isEmpty);
          expect(receivedMessages, isEmpty);
          
          // Clean up
          await subscription.cancel();
        });

        test('THEN logger subscriptions still work but messages are filtered', () async {
          // Arrange & Act
          authService.logInfo('Production message 1');
          paymentService.logWarning(message: 'Production warning');
          userService.logError(message: 'Production error', error: Exception('Test'));
          
          await Future.delayed(const Duration(milliseconds: 100));

          // Assert - Loggers are registered but messages are filtered
          expect(console.history, isEmpty);
        });
      });

      group('WHEN switching between development and production modes', () {
        test('THEN should properly handle mode transitions', () async {
          // Arrange - Start in production mode (already set in setUp)
          authService.logInfo('Production message (ignored)');
          await Future.delayed(const Duration(milliseconds: 50));
          expect(console.history, isEmpty);

          // Act - Switch to development mode
          InAppConsole.kEnableConsole = true;
          
          // Need to refresh logger registration
          console.removeLogger(authService);
          console.addLogger(authService);
          
          authService.logInfo('Development message (captured)');
          await Future.delayed(const Duration(milliseconds: 50));

          // Assert
          expect(console.history.length, equals(1));
          expect(console.history.first.message, equals('Development message (captured)'));
        });
      });

      group('WHEN app needs to enable console temporarily for debugging', () {
        test('THEN should be able to enable and see live logs', () async {
          // Arrange - Production mode, no logs captured
          authService.logInfo('Before debug mode');
          paymentService.logInfo('Before debug mode 2');
          await Future.delayed(const Duration(milliseconds: 50));
          expect(console.history, isEmpty);

          // Act - Enable debug mode temporarily
          InAppConsole.kEnableConsole = true;
          
          // Refresh registrations to activate
          console.removeLogger(authService);
          console.removeLogger(paymentService);
          console.addLogger(authService);
          console.addLogger(paymentService);
          
          authService.logInfo('Debug mode enabled');
          paymentService.logError(message: 'Debugging payment issue', error: Exception('Gateway timeout'));
          
          await Future.delayed(const Duration(milliseconds: 50));

          // Assert
          expect(console.history.length, equals(2));
          expect(console.history[0].message, equals('Debug mode enabled'));
          expect(console.history[1].message, equals('Debugging payment issue'));
          
          // Clean up - Back to production
          InAppConsole.kEnableConsole = false;
        });
      });
    });

    group('GIVEN a feature flag system for console control', () {
      test('WHEN feature flag toggles console THEN should respect the flag', () async {
        // Arrange - Simulate feature flag system
        final InAppConsoleInternal console = InAppConsole.instance as InAppConsoleInternal;
        console.clearLogs();
        
        bool isDebugModeEnabled = false; // Feature flag
        InAppConsole.kEnableConsole = isDebugModeEnabled;
        
        final logger = InAppLogger()..setLabel('FEATURE_SERVICE');
        console.addLogger(logger);

        // Act - Try logging with feature disabled
        logger.logInfo('Message with feature disabled');
        await Future.delayed(const Duration(milliseconds: 50));
        expect(console.history, isEmpty);

        // Enable feature flag
        isDebugModeEnabled = true;
        InAppConsole.kEnableConsole = isDebugModeEnabled;
        
        // Refresh logger
        console.removeLogger(logger);
        console.addLogger(logger);
        
        logger.logInfo('Message with feature enabled');
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(console.history.length, equals(1));
        expect(console.history.first.message, equals('Message with feature enabled'));
        
        // Reset
        InAppConsole.kEnableConsole = true;
      });
    });

    group('GIVEN high-frequency logging in production', () {
      test('WHEN kEnableConsole is false THEN should have minimal performance impact', () async {
        // Arrange
        final InAppConsoleInternal console = InAppConsole.instance as InAppConsoleInternal;
        InAppConsole.kEnableConsole = false;
        console.clearLogs();
        
        final highFrequencyService = InAppLogger()..setLabel('HIGH_FREQ');
        console.addLogger(highFrequencyService);

        // Act - Simulate high-frequency logging
        final stopwatch = Stopwatch()..start();
        
        for (int i = 0; i < 10000; i++) {
          highFrequencyService.logInfo('High frequency log $i');
        }
        
        await Future.delayed(const Duration(milliseconds: 100));
        stopwatch.stop();

        // Assert - No memory consumed by history
        expect(console.history, isEmpty);
        
        // Should complete quickly since logs are filtered
        expect(stopwatch.elapsedMilliseconds, lessThan(2000));
        
        // Reset
        InAppConsole.kEnableConsole = true;
      });
    });
  });
}
