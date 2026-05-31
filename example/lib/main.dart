import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iac_device_info_ext/iac_device_info_ext.dart';
import 'package:iac_export_logs_ext/iac_export_logs_ext.dart';
import 'package:iac_network_inspector_ext/iac_network_inspector_ext.dart';
import 'package:iac_performance_overlay_ext/iac_performance_overlay_ext.dart';
import 'package:iac_route_tracker_ext/iac_route_tracker_ext.dart';
import 'package:iac_statistics_ext/iac_statistics_ext.dart';
import 'package:in_app_console/in_app_console.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  InAppConsole.kEnableConsole = true;
  MicroFrontendApp.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'In-App Console Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF111111)),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
        ),
        navigatorKey: MicroFrontendApp.navigatorKey,
        navigatorObservers: [MicroFrontendApp.routeTracker],
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          Widget? page;
          switch (uri.path) {
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
            settings: settings,
          );
        },
        home: const HomeScreen(),
        builder: (context, child) => IacPerformanceOverlayWidget(
          service: MicroFrontendApp.performanceOverlay.service,
          overlayVisible: MicroFrontendApp.performanceOverlay.overlayVisible,
          child: InAppConsoleBubble(
            navigatorKey: MicroFrontendApp.navigatorKey,
            child: child!,
          ),
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
  static late IacPerformanceOverlayExtension performanceOverlay;

  static void initialize() {
    routeTracker = IacRouteTrackerNavigationObserver();
    networkInspector = IacNetworkInspectorExt();
    performanceOverlay = IacPerformanceOverlayExtension();

    authModule = AuthModule();
    paymentModule = PaymentModule();
    profileModule = ProfileModule();
    chatModule = ChatModule();

    InAppConsole.instance.addLogger(authModule.logger);
    InAppConsole.instance.addLogger(paymentModule.logger);
    InAppConsole.instance.addLogger(profileModule.logger);
    InAppConsole.instance.addLogger(chatModule.logger);

    networkInspector.addDio(DioWrapper(dio: authModule.dio, tag: 'Auth API'));
    networkInspector
        .addDio(DioWrapper(dio: paymentModule.dio, tag: 'Payment API'));
    networkInspector
        .addDio(DioWrapper(dio: profileModule.dio, tag: 'Profile API'));

    InAppConsole.instance.registerExtension(LogStatisticsExtension());
    InAppConsole.instance.registerExtension(InAppConsoleExportLogsExtension());
    InAppConsole.instance.registerExtension(networkInspector);
    InAppConsole.instance.registerExtension(IacDeviceInfoExtension());
    InAppConsole.instance
        .registerExtension(IacRouteTrackerExtension(observer: routeTracker));
    InAppConsole.instance.registerExtension(performanceOverlay);
  }
}

/// Authentication Module
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
      final response = await dio.get('/users/1');
      logger.logInfo('Session validation successful: ${response.statusCode}');
    } catch (e) {
      logger.logWarning(message: 'Session validation failed: $e');
    }
  }
}

/// Payment Module
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
      if (Random().nextBool()) {
        logger.logError(
          message: 'Payment failed: Gateway timeout',
          error: StateError('Payment gateway not responding'),
          stackTrace: StackTrace.current,
        );
        return false;
      }
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

/// Profile Module
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
      final response = await dio.put('/users/1', data: data);
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
      for (int i = 1; i <= 5; i++) {
        await dio.post('/photos',
            data: {'progress': i * 20, 'chunk': i, 'total': 5});
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

/// Chat Module
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

// ---------------------------------------------------------------------------
// Home Screen
// ---------------------------------------------------------------------------

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
      if (mounted) setState(() => _isLoading = true);
    });
    try {
      await MicroFrontendApp.authModule.login('john_doe', 'password123');
      MicroFrontendApp.profileModule.fetchProfile('john_doe');
      await MicroFrontendApp.profileModule
          .updateProfile({'name': 'John Doe', 'email': 'john@example.com'});
      await MicroFrontendApp.paymentModule.processPayment(29.99, 'Credit Card');
      await MicroFrontendApp.chatModule.sendMessage('Hello there!', 'support');
      await MicroFrontendApp.profileModule.uploadProfileImage();
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isLoading = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: const Text(
          'In-App Console',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: () => InAppConsole.instance.openConsole(context),
              icon: const Icon(Icons.terminal_rounded, size: 15),
              label: const Text('Console'),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF111111),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildRunDemoButton(),
            const SizedBox(height: 32),
            _buildSectionLabel('Modules'),
            const SizedBox(height: 12),
            _buildModuleCard(
              'Auth',
              Icons.shield_outlined,
              const Color(0xFF4A7CF6),
              [
                _ActionItem(
                    'Login',
                    () => MicroFrontendApp.authModule
                        .login('testuser', 'pass123')),
                _ActionItem('Logout', MicroFrontendApp.authModule.logout),
              ],
            ),
            _buildModuleCard(
              'Payment',
              Icons.credit_card_outlined,
              const Color(0xFF27AE60),
              [
                _ActionItem(
                  'Process Payment',
                  () => MicroFrontendApp.paymentModule.processPayment(
                    Random().nextDouble() * 100 + 10,
                    ['Credit Card', 'PayPal', 'Apple Pay'][Random().nextInt(3)],
                  ),
                ),
                _ActionItem(
                  'Validate',
                  () => MicroFrontendApp.paymentModule
                      .validatePaymentMethod('Credit Card'),
                ),
              ],
            ),
            _buildModuleCard(
              'Profile',
              Icons.person_outline_rounded,
              const Color(0xFFE67E22),
              [
                _ActionItem(
                  'Update Profile',
                  () => MicroFrontendApp.profileModule.updateProfile({
                    'name': 'User ${Random().nextInt(100)}',
                    'age': Random().nextInt(50) + 18,
                  }),
                ),
                _ActionItem(
                  'Upload Image',
                  MicroFrontendApp.profileModule.uploadProfileImage,
                ),
              ],
            ),
            _buildModuleCard(
              'Chat',
              Icons.chat_bubble_outline_rounded,
              const Color(0xFF8E44AD),
              [
                _ActionItem(
                  'Send Message',
                  () => MicroFrontendApp.chatModule.sendMessage(
                      'Hello from user ${Random().nextInt(100)}!', 'support'),
                ),
                _ActionItem(
                  'Reconnect',
                  MicroFrontendApp.chatModule.connectToChat,
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionLabel('Network Inspector'),
            const SizedBox(height: 12),
            _buildModuleCard(
              'HTTP Requests',
              Icons.network_check_rounded,
              const Color(0xFF16A085),
              [
                _ActionItem('GET', _makeGetRequest),
                _ActionItem('POST', _makePostRequest),
                _ActionItem('PUT', _makePutRequest),
                _ActionItem('DELETE', _makeDeleteRequest),
                _ActionItem('PATCH', _makePatchRequest),
                _ActionItem('HEAD', _makeHeadRequest),
                _ActionItem('OPTIONS', _makeOptionsRequest),
                _ActionItem('Error', _makeErrorRequest, isDestructive: true),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionLabel('Route Tracker'),
            const SizedBox(height: 12),
            _buildModuleCard(
              'Navigation',
              Icons.route_rounded,
              const Color(0xFF5C35CC),
              [
                _ActionItem(
                    'Shop', () => Navigator.pushNamed(context, '/shop')),
                _ActionItem(
                    'Profile', () => Navigator.pushNamed(context, '/profile')),
                _ActionItem('Checkout',
                    () => Navigator.pushNamed(context, '/checkout')),
                _ActionItem('Settings',
                    () => Navigator.pushNamed(context, '/settings')),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionLabel('Localization Test'),
            const SizedBox(height: 12),
            _buildModuleCard(
              'Kiểm thử tiếng Việt',
              Icons.translate_rounded,
              const Color(0xFF1565C0),
              [
                _ActionItem('Info', _logVietnameseInfo),
                _ActionItem('Warning', _logVietnameseWarning),
                _ActionItem('Error', _logVietnameseError),
                _ActionItem('All Levels', _logAllVietnamese),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRunDemoButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _simulateUserJourney,
      child: AnimatedOpacity(
        opacity: _isLoading ? 0.65 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _isLoading
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoading ? 'Running demo...' : 'Run User Journey',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Text(
                      'Auth → profile → payment → chat flow',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white30, size: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9E9E9E),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildModuleCard(
      String title, IconData icon, Color color, List<_ActionItem> actions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF0F0F0), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: actions.map(_buildActionChip).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(_ActionItem action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: action.isDestructive
              ? const Color(0xFFFFF5F5)
              : const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: action.isDestructive
                ? const Color(0xFFFFCDD2)
                : const Color(0xFFEAEAEA),
          ),
        ),
        child: Text(
          action.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: action.isDestructive
                ? const Color(0xFFE53935)
                : const Color(0xFF444444),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Network Inspector methods
  // ---------------------------------------------------------------------------

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
          const SnackBar(
              content: Text('GET request sent — check Network Inspector')),
        );
      }
    } catch (_) {}
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
          const SnackBar(
              content: Text('POST request sent — check Network Inspector')),
        );
      }
    } catch (_) {}
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
          const SnackBar(
              content: Text('PUT request sent — check Network Inspector')),
        );
      }
    } catch (_) {}
  }

  Future<void> _makeDeleteRequest() async {
    try {
      await MicroFrontendApp.authModule.dio
          .delete('/posts/${Random().nextInt(100) + 1}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('DELETE request sent — check Network Inspector')),
        );
      }
    } catch (_) {}
  }

  Future<void> _makeErrorRequest() async {
    try {
      await MicroFrontendApp.authModule.dio
          .get('/this-endpoint-does-not-exist-404');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Error request sent — check Network Inspector for details'),
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
          const SnackBar(
              content: Text('PATCH request sent — check Network Inspector')),
        );
      }
    } catch (_) {}
  }

  Future<void> _makeHeadRequest() async {
    try {
      await MicroFrontendApp.authModule.dio
          .head('/users/${Random().nextInt(10) + 1}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('HEAD request sent — check Network Inspector')),
        );
      }
    } catch (_) {}
  }

  Future<void> _makeOptionsRequest() async {
    try {
      await MicroFrontendApp.paymentModule.dio.request(
        '/posts',
        options: Options(method: 'OPTIONS'),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('OPTIONS request sent — check Network Inspector')),
        );
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // Vietnamese log methods
  // ---------------------------------------------------------------------------

  void _logVietnameseInfo() {
    MicroFrontendApp.chatModule.logger.logInfo(
      'Xin chào! Đây là tin nhắn thông tin bằng tiếng Việt. Ứng dụng đang hoạt động bình thường.',
    );
    MicroFrontendApp.profileModule.logger.logInfo(
      'Người dùng: Nguyễn Văn An - Email: nguyen.van.an@example.com - Địa chỉ: Hà Nội, Việt Nam',
    );
  }

  void _logVietnameseWarning() {
    MicroFrontendApp.authModule.logger.logWarning(
      message:
          'Cảnh báo: Phiên đăng nhập sắp hết hạn. Vui lòng đăng nhập lại để tiếp tục sử dụng.',
    );
    MicroFrontendApp.paymentModule.logger.logWarning(
      message:
          'Thanh toán chậm hơn bình thường. Số tiền: 1.250.000 ₫ - Phương thức: Thẻ tín dụng Vietcombank.',
    );
  }

  void _logVietnameseError() {
    MicroFrontendApp.profileModule.logger.logError(
      message:
          'Lỗi: Không thể tải hồ sơ người dùng. Tên: Trần Thị Bích - Mã lỗi: ERR_PROFILE_404',
      error: Exception(
          'Không tìm thấy tài nguyên. Đặc biệt: àáâãèéêìíòóôõùúýăđơư'),
      stackTrace: StackTrace.current,
    );
  }

  void _logAllVietnamese() {
    MicroFrontendApp.chatModule.logger.logInfo(
      'Kết nối thành công đến máy chủ chat tại TP. Hồ Chí Minh.',
    );
    MicroFrontendApp.authModule.logger.logWarning(
      message: 'Phát hiện đăng nhập từ thiết bị lạ: iPhone 15 Pro - Đà Nẵng.',
    );
    MicroFrontendApp.paymentModule.logger.logError(
      message: 'Giao dịch thất bại: Số dư không đủ để thanh toán 500.000 ₫',
      error: StateError('Lỗi cổng thanh toán: VNPAY không phản hồi'),
      stackTrace: StackTrace.current,
    );
    MicroFrontendApp.profileModule.logger.logInfo(
      'Cập nhật thông tin: Họ tên "Lê Thị Hương", SĐT "0901234567", Quận Bình Thạnh.',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Action item model for module cards
// ---------------------------------------------------------------------------

class _ActionItem {
  const _ActionItem(this.label, this.onTap, {this.isDestructive = false});
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
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
    final queryParams = uri.queryParameters;
    final payload =
        ModalRoute.of(context)?.settings.arguments as Map<String, Object>? ??
            {};

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF111111),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF111111)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF0F0F0), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFF0F0F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    routeName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                      fontFamily: 'monospace',
                    ),
                  ),
                  if (queryParams.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'QUERY PARAMS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A7CF6),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...queryParams.entries.map(
                      (e) => Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  ],
                  if (payload.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'PAYLOAD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27AE60),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...payload.entries.map(
                      (e) => Text(
                        '${e.key}: ${e.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'monospace',
                          color: Color(0xFF555555),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...childRoutes.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    r.route,
                    arguments: r.payload.isEmpty ? null : r.payload,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(r.label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5F5F5),
                foregroundColor: const Color(0xFF444444),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                textStyle:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
