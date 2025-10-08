import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_console/in_app_console.dart';
import 'package:in_app_console/src/core/logger/in_app_logger_type.dart';
import 'dart:async';

/// Example BDD-style tests demonstrating how to use the InAppConsole package
/// in a real-world microservice architecture scenario.
///
/// This shows the proper BDD structure using GIVEN-WHEN-THEN format.
void main() {
  group('Microservice Logging Scenario', () {
    group('GIVEN a Flutter app with multiple microservices', () {
      late InAppConsole console;
      late InAppLogger authService;
      late InAppLogger paymentService;
      late InAppLogger userService;

      setUp(() {
        console = InAppConsole.instance;
        console.clearHistory();
        
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
        final console = InAppConsole.instance;
        console.clearHistory();
        
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
}
