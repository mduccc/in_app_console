import 'dart:math';

import 'package:flutter/material.dart';
import 'package:in_app_console/in_app_console.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InAppLogger _logger = InAppLogger();

  @override
  void initState() {
    super.initState();
    _logger.setLabel('Home Screen');
    InAppConsole.instance.addLogger(_logger);

    Future.delayed(const Duration(seconds: 3), () {
      _logger.logInfo('Random info message ${Random().nextInt(100)}');
      _logger.logError(
          message: 'Random error message ${Random().nextInt(100)}',
          error: Error(),
          stackTrace: StackTrace.current);
      _logger.warning(
          message: 'Random warning message ${Random().nextInt(100)}',
          error: Error(),
          stackTrace: StackTrace.current);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('In App Console Example'),
        ),
        body: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /// Log random messages
              ElevatedButton(
                  onPressed: () {
                    _logger.logInfo(
                        'Random info message ${Random().nextInt(100)}');
                  },
                  child: const Text('Log Info Random Message')),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () {
                    _logger.logError(
                        message:
                            'Random error message ${Random().nextInt(100)}',
                        error: Error(),
                        stackTrace: StackTrace.current);
                  },
                  child: const Text('Log Random Error Message')),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () {
                    _logger.warning(
                        message:
                            'Random warning message ${Random().nextInt(100)}',
                        error: Error(),
                        stackTrace: StackTrace.current);
                  },
                  child: const Text('Log Random Warning Message')),

              /// Open in app logger
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => InAppConsole.instance.openConsole(context),
                child: const Text('Open In App Console'),
              ),
            ],
          ),
        ));
  }
}
