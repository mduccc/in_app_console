import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iac_device_info_ext/iac_device_info_ext.dart';
import 'package:iac_export_logs_ext/iac_export_logs_ext.dart';
import 'package:iac_network_inspector_ext/iac_network_inspector_ext.dart';
import 'package:iac_route_tracker_ext/iac_route_tracker_ext.dart';
import 'package:iac_statistics_ext/iac_statistics_ext.dart';
import 'package:in_app_console/in_app_console.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  /// Enable the in app console for debugging purposes.
  InAppConsole.kEnableConsole = true;
  // Initialize micro-frontend modules
  MicroFrontendApp.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Micro-Frontend Console Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        navigatorKey: MicroFrontendApp.navigatorKey,
        navigatorObservers: [MicroFrontendApp.routeTracker],
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          Widget? page;
          switch (uri.path) {
            // Shop flow: /shop → /shop/category?… → /shop/product?…
            case '/shop':
              page = const _DemoScreen(
                title: 'Shop',
                childRoutes: [
                  _ChildRouteConfig(
                    label: 'Browse Category',
                    route: '/shop/category?category=electronics&sort=price_asc',
                  ),
                ],
              );
            case '/shop/category':
              page = const _DemoScreen(
                title: 'Shop Category',
                childRoutes: [
                  _ChildRouteConfig(
                    label: 'View Product',
                    route: '/shop/product?productId=PRD-042',
                    payload: <String, Object>{
                      'name': 'Wireless Headphones',
                      'price': 99.99,
                      'inStock': true,
                    },
                  ),
                ],
              );
            case '/shop/product':
              page = const _DemoScreen(title: 'Product Detail');

            // Profile flow: /profile → /profile/edit → /profile/change-password?…
            case '/profile':
              page = const _DemoScreen(
                title: 'Profile',
                childRoutes: [
                  _ChildRouteConfig(
                    label: 'Edit Profile',
                    route: '/profile/edit',
                    payload: <String, Object>{
                      'userId': 'user_123',
                      'name': 'John Doe',
                      'email': 'john@example.com',
                    },
                  ),
                ],
              );
            case '/profile/edit':
              page = const _DemoScreen(
                title: 'Edit Profile',
                childRoutes: [
                  _ChildRouteConfig(
                    label: 'Change Password',
                    route:
                        '/profile/change-password?userId=user_123&requireOtp=true',
                  ),
                ],
              );
            case '/profile/change-password':
              page = const _DemoScreen(title: 'Change Password');

            // Checkout flow: /checkout → /checkout/payment → /checkout/confirmation?…
            case '/checkout':
              page = const _DemoScreen(
                title: 'Checkout',
                childRoutes: [
                  _ChildRouteConfig(
                    label: 'Proceed to Payment',
                    route: '/checkout/payment',
                    payload: <String, Object>{
                      'cartTotal': 149.98,
                      'itemCount': 3,
                      'currency': 'USD',
                    },
                  ),
                ],
              );
            case '/checkout/payment':
              page = const _DemoScreen(
                title: 'Payment',
                childRoutes: [
                  _ChildRouteConfig(
                    label: 'View Confirmation',
                    route:
                        '/checkout/confirmation?orderId=ORD-2024-789&method=credit_card',
                    payload: <String, Object>{
                      'last4': '4242',
                      'brand': 'Visa',
                    },
                  ),
                ],
              );
            case '/checkout/confirmation':
              page = const _DemoScreen(title: 'Order Confirmation');

            // Settings flow: /settings → /settings/notifications?… → /settings/notifications/schedule
            case '/settings':
              page = const _DemoScreen(
                title: 'Settings',
                childRoutes: [
                  _ChildRouteConfig(
                    label: 'Notifications',
                    route: '/settings/notifications?tab=push&userId=user_123',
                  ),
                ],
              );
            case '/settings/notifications':
              page = const _DemoScreen(
                title: 'Notifications',
                childRoutes: [
                  _ChildRouteConfig(
                    label: 'Edit Schedule',
                    route: '/settings/notifications/schedule',
                    payload: <String, Object>{
                      'quietStart': '22:00',
                      'quietEnd': '08:00',
                      'timezone': 'America/New_York',
                      'enabled': true,
                    },
                  ),
                ],
              );
            case '/settings/notifications/schedule':
              page = const _DemoScreen(title: 'Notification Schedule');
          }
          if (page == null) return null;
          return MaterialPageRoute(
            builder: (_) => page!,
            settings: settings, // preserve name (with query string) + arguments
          );
        },
        home: const HomeScreen(),
        builder: (context, child) => InAppConsoleBubble(
          navigatorKey: MicroFrontendApp.navigatorKey,
          child: child!,
        ),
      );
}

/// Central application that manages all micro-frontend modules
class MicroFrontendApp {
  static final navigatorKey = GlobalKey<NavigatorState>();
  static late AuthModule authModule;
  static late PaymentModule paymentModule;
  static late ProfileModule profileModule;
  static late ChatModule chatModule;
  static late IacNetworkInspectorExt networkInspector;
  static late IacRouteTrackerNavigationObserver routeTracker;

  static void initialize() {
    // Create route tracker
    routeTracker = IacRouteTrackerNavigationObserver();

    // Create network inspector
    networkInspector = IacNetworkInspectorExt();

    // Initialize all modules with their Dio instances
    authModule = AuthModule();
    paymentModule = PaymentModule();
    profileModule = ProfileModule();
    chatModule = ChatModule();

    // Register all module loggers with the central console
    InAppConsole.instance.addLogger(authModule.logger);
    InAppConsole.instance.addLogger(paymentModule.logger);
    InAppConsole.instance.addLogger(profileModule.logger);
    InAppConsole.instance.addLogger(chatModule.logger);

    // Register Dio instances with network inspector
    networkInspector.addDio(DioWrapper(dio: authModule.dio, tag: 'Auth API'));
    networkInspector
        .addDio(DioWrapper(dio: paymentModule.dio, tag: 'Payment API'));
    networkInspector
        .addDio(DioWrapper(dio: profileModule.dio, tag: 'Profile API'));

    // Register extensions
    InAppConsole.instance.registerExtension(LogStatisticsExtension());
    InAppConsole.instance.registerExtension(InAppConsoleExportLogsExtension());
    InAppConsole.instance.registerExtension(networkInspector);
    InAppConsole.instance.registerExtension(IacDeviceInfoExtension());
    InAppConsole.instance
        .registerExtension(IacRouteTrackerExtension(observer: routeTracker));
  }
}

/// Authentication Module - Handles user login/logout
class AuthModule {
  final InAppLogger logger = InAppLogger()..setLabel('Auth');
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
  bool _isLoggedIn = false;
  String? _currentUser;

  bool get isLoggedIn => _isLoggedIn;
  String? get currentUser => _currentUser;

  Future<bool> login(String username, String password) async {
    logger.logInfo('Login attempt for user: $username');

    try {
      // Make actual API request
      final response = await dio.post(
        '/posts',
        data: {'username': username, 'password': password},
      );

      logger.logInfo('Auth API responded with status: ${response.statusCode}');

      if (username.isNotEmpty && password.length >= 6) {
        _isLoggedIn = true;
        _currentUser = username;
        logger.logInfo('Login successful for user: $username');
        return true;
      } else {
        logger.logError(
          message: 'Login failed for user: $username - Invalid credentials',
          error: ArgumentError('Invalid username or password'),
          stackTrace: StackTrace.current,
        );
        return false;
      }
    } catch (e, stackTrace) {
      logger.logError(
        message: 'Login API call failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  void logout() {
    logger.logInfo('User logout: $_currentUser');
    _isLoggedIn = false;
    _currentUser = null;
  }

  Future<void> validateSession() async {
    logger.logInfo('Validating session...');
    try {
      // Make GET request to validate session
      final response = await dio.get('/users/1');
      logger.logInfo('Session validation successful: ${response.statusCode}');
    } catch (e) {
      logger.logWarning(
        message: 'Session validation failed: $e',
      );
    }
  }
}

/// Payment Module - Handles payment processing
class PaymentModule {
  final InAppLogger logger = InAppLogger()..setLabel('Payment');
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));

  Future<bool> processPayment(double amount, String method) async {
    logger.logInfo(
        'Processing payment: \$${amount.toStringAsFixed(2)} via $method');

    try {
      // Make payment API request
      final response = await dio.post(
        '/posts',
        data: {
          'amount': amount,
          'method': method,
          'currency': 'USD',
          'timestamp': DateTime.now().toIso8601String(),
        },
        queryParameters: {'simulate_delay': Random().nextInt(3) + 1},
      );

      logger.logInfo('Payment API responded: ${response.statusCode}');

      // Simulate random payment failures
      if (Random().nextBool()) {
        logger.logError(
          message: 'Payment failed: Gateway timeout',
          error: StateError('Payment gateway not responding'),
          stackTrace: StackTrace.current,
        );
        return false;
      }

      // Simulate slow payment warnings
      if (Random().nextBool()) {
        logger.logWarning(
            message:
                'Payment processing slower than usual (${Random().nextInt(3) + 2}s)');
      }

      logger.logInfo('Payment successful: \$${amount.toStringAsFixed(2)}');
      return true;
    } catch (e, stackTrace) {
      logger.logError(
        message: 'Payment API call failed',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> validatePaymentMethod(String method) async {
    logger.logInfo('Validating payment method: $method');
    try {
      // Make validation request
      await dio.get('/posts/${Random().nextInt(100) + 1}');
      logger.logInfo('Payment method validated: $method');
    } catch (e, stackTrace) {
      logger.logError(
        message: 'Payment method validation failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Profile Module - Handles user profile management
class ProfileModule {
  final InAppLogger logger = InAppLogger()..setLabel('Profile');
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'https://jsonplaceholder.typicode.com',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
  ));
  final Map<String, dynamic> _profileData = {};

  Future<void> updateProfile(Map<String, dynamic> data) async {
    logger.logInfo('Updating profile data: ${data.keys.join(', ')}');

    try {
      // Make PUT request to update profile
      final response = await dio.put(
        '/users/1',
        data: data,
      );

      logger.logInfo('Profile update API responded: ${response.statusCode}');
      _profileData.addAll(data);
      logger.logInfo('Profile updated successfully');
    } catch (e, stackTrace) {
      logger.logError(
        message: 'Profile update failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> uploadProfileImage() async {
    logger.logInfo('Starting profile image upload');

    try {
      // Simulate multiple API calls for upload progress
      for (int i = 1; i <= 5; i++) {
        await dio.post(
          '/photos',
          data: {
            'progress': i * 20,
            'chunk': i,
            'total': 5,
          },
        );
        logger.logInfo('Upload progress: ${i * 20}%');
      }

      logger.logInfo('Profile image uploaded successfully');
    } catch (e, stackTrace) {
      logger.logError(
        message: 'Image upload failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> fetchProfile(String userId) async {
    logger.logInfo('Fetching profile for user: $userId');
    try {
      if (userId.isEmpty) {
        logger.logError(
          message: 'Cannot fetch profile: Invalid user ID',
          error: ArgumentError('User ID is required'),
          stackTrace: StackTrace.current,
        );
        return;
      }

      // Make GET request to fetch profile
      final response = await dio.get('/users/$userId');
      logger.logInfo('Profile fetched: ${response.statusCode}');
    } catch (e, stackTrace) {
      logger.logError(
        message: 'Profile fetch failed',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// Chat Module - Handles messaging functionality
class ChatModule {
  final InAppLogger logger = InAppLogger()..setLabel('Chat');
  final List<String> _messages = [];

  Future<void> sendMessage(String message, String recipient) async {
    logger.logInfo('Sending message to $recipient');

    await Future.delayed(const Duration(milliseconds: 400));

    if (message.trim().isEmpty) {
      logger.logError(
        message: 'Cannot send empty message',
        error: ArgumentError('Message content is required'),
        stackTrace: StackTrace.current,
      );
      return;
    }

    _messages.add(message);
    logger.logInfo('Message sent successfully to $recipient');
  }

  void connectToChat() {
    logger.logInfo('Connecting to chat server');
    // Simulate connection issues occasionally
    if (Random().nextInt(10) < 2) {
      logger.logWarning(message: 'Chat connection unstable - retrying...');
    } else {
      logger.logInfo('Connected to chat server successfully');
    }
  }

  void receiveMessage(String from, String message) {
    logger.logInfo('Received message from $from');
    _messages.add('$from: $message');
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Simulate app startup logs
    _simulateAppStartup();
  }

  void _simulateAppStartup() {
    Timer(const Duration(milliseconds: 500), () {
      MicroFrontendApp.authModule.validateSession();
      MicroFrontendApp.chatModule.connectToChat();
    });
  }

  Future<void> _simulateUserJourney() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _isLoading = true);
      }
    });

    try {
      // 1. Login
      await MicroFrontendApp.authModule.login('john_doe', 'password123');

      // 2. Fetch profile
      MicroFrontendApp.profileModule.fetchProfile('john_doe');

      // 3. Update profile
      await MicroFrontendApp.profileModule
          .updateProfile({'name': 'John Doe', 'email': 'john@example.com'});

      // 4. Process payment
      await MicroFrontendApp.paymentModule.processPayment(29.99, 'Credit Card');

      // 5. Send chat message
      await MicroFrontendApp.chatModule.sendMessage('Hello there!', 'support');

      // 6. Upload profile image
      await MicroFrontendApp.profileModule.uploadProfileImage();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Micro-Frontend Console Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => InAppConsole.instance.openConsole(context),
            tooltip: 'Open Console',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.architecture, size: 48, color: Colors.blue),
                    SizedBox(height: 8),
                    Text(
                      'Micro-Frontend Architecture Demo',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This demo shows how multiple modules (Auth, Payment, Profile, Chat) log to a central console',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Demo Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _simulateUserJourney,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: Text(
                  _isLoading ? 'Running Demo...' : 'Run Complete User Journey'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            const SizedBox(height: 24),

            // Module Actions
            const Text(
              'Individual Module Actions:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Auth Module
            _buildModuleCard(
              'Authentication Module',
              Icons.security,
              Colors.blue,
              [
                ElevatedButton(
                  onPressed: () =>
                      MicroFrontendApp.authModule.login('testuser', 'pass123'),
                  child: const Text('Simulate Login'),
                ),
                ElevatedButton(
                  onPressed: () => MicroFrontendApp.authModule.logout(),
                  child: const Text('Simulate Logout'),
                ),
              ],
            ),

            // Payment Module
            _buildModuleCard(
              'Payment Module',
              Icons.payment,
              Colors.green,
              [
                ElevatedButton(
                  onPressed: () => MicroFrontendApp.paymentModule
                      .processPayment(
                          Random().nextDouble() * 100 + 10,
                          [
                            'Credit Card',
                            'PayPal',
                            'Apple Pay'
                          ][Random().nextInt(3)]),
                  child: const Text('Process Payment'),
                ),
                ElevatedButton(
                  onPressed: () => MicroFrontendApp.paymentModule
                      .validatePaymentMethod('Credit Card'),
                  child: const Text('Validate Payment'),
                ),
              ],
            ),

            // Profile Module
            _buildModuleCard(
              'Profile Module',
              Icons.person,
              Colors.orange,
              [
                ElevatedButton(
                  onPressed: () =>
                      MicroFrontendApp.profileModule.updateProfile({
                    'name': 'User ${Random().nextInt(100)}',
                    'age': Random().nextInt(50) + 18,
                  }),
                  child: const Text('Update Profile'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      MicroFrontendApp.profileModule.uploadProfileImage(),
                  child: const Text('Upload Image'),
                ),
              ],
            ),

            // Chat Module
            _buildModuleCard(
              'Chat Module',
              Icons.chat,
              Colors.purple,
              [
                ElevatedButton(
                  onPressed: () => MicroFrontendApp.chatModule.sendMessage(
                      'Hello from user ${Random().nextInt(100)}!', 'support'),
                  child: const Text('Send Message'),
                ),
                ElevatedButton(
                  onPressed: () => MicroFrontendApp.chatModule.connectToChat(),
                  child: const Text('Reconnect Chat'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Network Inspector Demo Section
            const Text(
              'Network Inspector Demo:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildModuleCard(
              'HTTP Request Testing',
              Icons.network_check,
              Colors.teal,
              [
                ElevatedButton(
                  onPressed: _makeGetRequest,
                  child: const Text('GET Request'),
                ),
                ElevatedButton(
                  onPressed: _makePostRequest,
                  child: const Text('POST Request'),
                ),
                ElevatedButton(
                  onPressed: _makePutRequest,
                  child: const Text('PUT Request'),
                ),
                ElevatedButton(
                  onPressed: _makeDeleteRequest,
                  child: const Text('DELETE Request'),
                ),
                ElevatedButton(
                  onPressed: _makePatchRequest,
                  child: const Text('PATCH Request'),
                ),
                ElevatedButton(
                  onPressed: _makeHeadRequest,
                  child: const Text('HEAD Request'),
                ),
                ElevatedButton(
                  onPressed: _makeOptionsRequest,
                  child: const Text('OPTIONS Request'),
                ),
                ElevatedButton(
                  onPressed: _makeErrorRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                  ),
                  child: const Text('Simulate Error'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Route Tracker Demo Section
            const Text(
              'Route Tracker Demo:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildModuleCard(
              'Navigation',
              Icons.route,
              Colors.deepPurple,
              [
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/shop'),
                  child: const Text('Go to Shop'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/profile'),
                  child: const Text('Go to Profile'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/checkout'),
                  child: const Text('Go to Checkout'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                  child: const Text('Go to Settings'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Console Button
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Icon(Icons.bug_report, size: 32, color: Colors.red),
                    const SizedBox(height: 8),
                    const Text(
                      'View Unified Console',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'See logs from all modules in one place',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () =>
                          InAppConsole.instance.openConsole(context),
                      icon: const Icon(Icons.visibility),
                      label: const Text('Open In-App Console'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleCard(
      String title, IconData icon, Color color, List<Widget> actions) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions,
            ),
          ],
        ),
      ),
    );
  }

  // Network Inspector Demo Methods
  Future<void> _makeGetRequest() async {
    try {
      await MicroFrontendApp.authModule.dio.get(
        '/users/${Random().nextInt(10) + 1}',
        queryParameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'page': Random().nextInt(5) + 1,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GET request sent - Check Network Inspector!')),
        );
      }
    } catch (e) {
      // Error will be captured by network inspector
    }
  }

  Future<void> _makePostRequest() async {
    try {
      await MicroFrontendApp.paymentModule.dio.post(
        '/posts',
        data: {
          'title': 'Test Post #${Random().nextInt(1000)}',
          'body': 'This is a test post created from the example app',
          'userId': Random().nextInt(10) + 1,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('POST request sent - Check Network Inspector!')),
        );
      }
    } catch (e) {
      // Error will be captured by network inspector
    }
  }

  Future<void> _makePutRequest() async {
    try {
      await MicroFrontendApp.profileModule.dio.put(
        '/users/1',
        data: {
          'name': 'Updated User',
          'email': 'updated@example.com',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PUT request sent - Check Network Inspector!')),
        );
      }
    } catch (e) {
      // Error will be captured by network inspector
    }
  }

  Future<void> _makeDeleteRequest() async {
    try {
      await MicroFrontendApp.authModule.dio.delete(
        '/posts/${Random().nextInt(100) + 1}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('DELETE request sent - Check Network Inspector!')),
        );
      }
    } catch (e) {
      // Error will be captured by network inspector
    }
  }

  Future<void> _makeErrorRequest() async {
    try {
      await MicroFrontendApp.authModule.dio.get(
        '/this-endpoint-does-not-exist-404',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error request sent - Check Network Inspector for details!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _makePatchRequest() async {
    try {
      await MicroFrontendApp.profileModule.dio.patch(
        '/posts/${Random().nextInt(100) + 1}',
        data: {
          'title': 'Patched Title #${Random().nextInt(1000)}',
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PATCH request sent - Check Network Inspector!')),
        );
      }
    } catch (e) {
      // Error will be captured by network inspector
    }
  }

  Future<void> _makeHeadRequest() async {
    try {
      await MicroFrontendApp.authModule.dio.head(
        '/users/${Random().nextInt(10) + 1}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('HEAD request sent - Check Network Inspector!')),
        );
      }
    } catch (e) {
      // Error will be captured by network inspector
    }
  }

  Future<void> _makeOptionsRequest() async {
    try {
      await MicroFrontendApp.paymentModule.dio.request(
        '/posts',
        options: Options(method: 'OPTIONS'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OPTIONS request sent - Check Network Inspector!')),
        );
      }
    } catch (e) {
      // Error will be captured by network inspector
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Route Tracker demo screens
// ---------------------------------------------------------------------------

class _ChildRouteConfig {
  const _ChildRouteConfig({
    required this.label,
    required this.route,
    this.payload = const <String, Object>{},
  });

  final String label;
  // Full route string including query params, e.g. '/profile/change-password?userId=user_123&requireOtp=true'
  final String route;
  final Map<String, Object> payload;
}

class _DemoScreen extends StatelessWidget {
  const _DemoScreen({
    required this.title,
    this.childRoutes = const [],
  });

  final String title;
  final List<_ChildRouteConfig> childRoutes;

  @override
  Widget build(BuildContext context) {
    final routeName = ModalRoute.of(context)?.settings.name ?? '';
    final uri = Uri.parse(routeName);
    final queryParams = uri.queryParameters; // parsed from the route URL
    final payload =
        ModalRoute.of(context)?.settings.arguments as Map<String, Object>? ??
            {};

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Route info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      routeName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (queryParams.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Query Params',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue)),
                      const SizedBox(height: 4),
                      ...queryParams.entries.map(
                        (e) => Text(
                          '  ${e.key}: ${e.value}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                    if (payload.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Text('Payload',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green)),
                      const SizedBox(height: 4),
                      ...payload.entries.map(
                        (e) => Text(
                          '  ${e.key}: ${e.value}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Child navigation buttons
            ...childRoutes.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    r.route,
                    arguments: r.payload.isEmpty ? null : r.payload,
                  ),
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(r.label),
                ),
              ),
            ),
            if (childRoutes.isNotEmpty) const SizedBox(height: 4),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200),
            ),
          ],
        ),
      ),
    );
  }
}
