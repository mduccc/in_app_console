import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:iac_network_inspector_ext/iac_network_inspector_ext.dart';
import 'package:iac_network_inspector_ext/src/core/model/dio_wrapper.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_request.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_response.dart';
import 'package:iac_network_inspector_ext/src/core/model/iac_network_rs.dart';
import 'package:iac_network_inspector_ext/src/impl/iac_network_interceptor_impl.dart';
import 'package:iac_network_inspector_ext/src/utils/curl_generator.dart';
import 'package:in_app_console/in_app_console.dart';

void main() {
  group('IacNetworkInspectorExt', () {
    group('GIVEN a new IacNetworkInspectorExt instance', () {
      test('WHEN created THEN should have correct extension properties', () {
        // Arrange & Act
        final extension = IacNetworkInspectorExt();

        // Assert
        expect(extension.id, equals('iac_network_inspector_ext'));
        expect(extension.name, equals('Network Inspector'));
        expect(extension.description,
            equals('An extension to inspect network requests made using Dio.'));
        expect(extension.version, equals('1.0.0'));
        expect(extension.icon, isNotNull);
      });

      test('WHEN created THEN should have empty history', () {
        // Arrange & Act
        final extension = IacNetworkInspectorExt();

        // Assert
        expect(extension.history, isEmpty);
        expect(extension.stream, isNotNull);
      });
    });

    group('WHEN managing Dio instances', () {
      late IacNetworkInspectorExt extension;
      late Dio testDio;

      setUp(() {
        extension = IacNetworkInspectorExt();
        testDio = Dio();
      });

      test('THEN should add Dio instance with tag', () {
        // Arrange
        final wrapper = DioWrapper(dio: testDio, tag: 'TestAPI');
        final initialInterceptorsCount = testDio.interceptors.length;

        // Act
        extension.addDio(wrapper);

        // Assert
        expect(
            testDio.interceptors.length, equals(initialInterceptorsCount + 1));
        expect(testDio.options.extra['iac_dio_tag'], equals('TestAPI'));
      });

      test('THEN should not add same Dio instance twice', () {
        // Arrange
        final wrapper = DioWrapper(dio: testDio, tag: 'TestAPI');
        extension.addDio(wrapper);
        final interceptorsCountAfterFirstAdd = testDio.interceptors.length;

        // Act - Try to add the same Dio instance again
        extension.addDio(wrapper);

        // Assert
        expect(testDio.interceptors.length,
            equals(interceptorsCountAfterFirstAdd));
      });

      test('THEN should add multiple different Dio instances', () {
        // Arrange
        final dio1 = Dio();
        final dio2 = Dio();
        final dio3 = Dio();

        // Act
        extension.addDio(DioWrapper(dio: dio1, tag: 'API1'));
        extension.addDio(DioWrapper(dio: dio2, tag: 'API2'));
        extension.addDio(DioWrapper(dio: dio3, tag: 'API3'));

        // Assert
        expect(dio1.options.extra['iac_dio_tag'], equals('API1'));
        expect(dio2.options.extra['iac_dio_tag'], equals('API2'));
        expect(dio3.options.extra['iac_dio_tag'], equals('API3'));
      });

      test('THEN should remove Dio instance', () {
        // Arrange
        final wrapper = DioWrapper(dio: testDio, tag: 'TestAPI');
        extension.addDio(wrapper);
        final interceptorAdded =
            testDio.interceptors.any((i) => i is IacNetworkInterceptorImpl);
        expect(interceptorAdded, isTrue);

        // Act
        extension.removeDio(wrapper);

        // Assert
        final interceptorRemoved =
            testDio.interceptors.any((i) => i is IacNetworkInterceptorImpl);
        expect(interceptorRemoved, isFalse);
      });

      test('THEN should handle removing non-existent Dio instance gracefully',
          () {
        // Arrange
        final unregisteredWrapper = DioWrapper(dio: Dio(), tag: 'Unregistered');

        // Act & Assert - Should not throw
        expect(() => extension.removeDio(unregisteredWrapper), returnsNormally);
      });

      test('THEN should clear history when clearHistory is called', () async {
        // Arrange
        final dio = Dio();
        final dioAdapter = DioAdapter(dio: dio);
        // Initialize the extension to start listening to interceptor
        extension.onInit(MockExtensionContext());
        extension.addDio(DioWrapper(dio: dio, tag: 'TestAPI'));

        // Mock a successful response
        dioAdapter.onGet(
          'https://api.example.com/test',
          (server) => server.reply(200, {'message': 'success'}),
        );

        // Make a request
        await dio.get('https://api.example.com/test');

        // Wait for event to be processed
        await Future.delayed(const Duration(milliseconds: 100));

        expect(extension.history.isNotEmpty, isTrue);

        // Act
        extension.clearHistory();

        // Assert
        expect(extension.history, isEmpty);
      });
    });

    group('WHEN intercepting network requests', () {
      late IacNetworkInspectorExt extension;
      late Dio dio;
      late DioAdapter dioAdapter;

      setUp(() {
        extension = IacNetworkInspectorExt();
        // Initialize the extension to start listening to interceptor
        extension.onInit(MockExtensionContext());
        dio = Dio();
        dioAdapter = DioAdapter(dio: dio);
        extension.addDio(DioWrapper(dio: dio, tag: 'TestAPI'));
      });

      test('THEN should capture successful GET request', () async {
        // Arrange
        dioAdapter.onGet(
          'https://api.example.com/users',
          (server) => server.reply(200, {'users': []}),
        );

        final streamFuture = extension.stream.first;

        // Act
        await dio.get('https://api.example.com/users');

        // Assert
        final networkData = await streamFuture;
        expect(networkData.request.method, equals('GET'));
        expect(networkData.url, contains('/users'));
        expect(networkData.response.statusCode, equals(200));
        expect(networkData.dioTag, equals('TestAPI'));
      });

      test('THEN should capture successful POST request with body', () async {
        // Arrange
        final requestBody = {'name': 'John Doe', 'email': 'john@example.com'};
        dioAdapter.onPost(
          'https://api.example.com/users',
          (server) => server.reply(201, {'id': 1, 'name': 'John Doe'}),
          data: requestBody,
        );

        final streamFuture = extension.stream.first;

        // Act
        await dio.post('https://api.example.com/users', data: requestBody);

        // Assert
        final networkData = await streamFuture;
        expect(networkData.request.method, equals('POST'));
        expect(networkData.request.body, equals(requestBody));
        expect(networkData.response.statusCode, equals(201));
      });

      test('THEN should capture failed request with error', () async {
        // Arrange
        dioAdapter.onGet(
          'https://api.example.com/error',
          (server) => server.reply(404, {'error': 'Not found'}),
        );

        final streamFuture = extension.stream.first;

        // Act
        try {
          await dio.get('https://api.example.com/error');
        } catch (e) {
          // Expected to throw
        }

        // Assert
        final networkData = await streamFuture;
        expect(networkData.response.statusCode, equals(404));
        expect(networkData.response.hasError, isTrue);
      });

      test('THEN should capture request with query parameters', () async {
        // Arrange
        dioAdapter.onGet(
          'https://api.example.com/search',
          (server) => server.reply(200, {'results': []}),
          queryParameters: {'q': 'test', 'page': '1'},
        );

        final streamFuture = extension.stream.first;

        // Act
        await dio.get(
          'https://api.example.com/search',
          queryParameters: {'q': 'test', 'page': '1'},
        );

        // Assert
        final networkData = await streamFuture;
        expect(networkData.request.queryParameters['q'], equals('test'));
        expect(networkData.request.queryParameters['page'], equals('1'));
      });

      test('THEN should capture request with custom headers', () async {
        // Arrange
        dioAdapter.onGet(
          'https://api.example.com/protected',
          (server) => server.reply(200, {'data': 'secret'}),
          headers: {'Authorization': 'Bearer token123'},
        );

        final streamFuture = extension.stream.first;

        // Act
        await dio.get(
          'https://api.example.com/protected',
          options: Options(headers: {'Authorization': 'Bearer token123'}),
        );

        // Assert
        final networkData = await streamFuture;
        expect(networkData.request.headers['Authorization'],
            equals('Bearer token123'));
      });

      test('THEN should maintain history of all requests', () async {
        // Arrange
        dioAdapter.onGet(
          'https://api.example.com/1',
          (server) => server.reply(200, {'id': 1}),
        );
        dioAdapter.onGet(
          'https://api.example.com/2',
          (server) => server.reply(200, {'id': 2}),
        );
        dioAdapter.onGet(
          'https://api.example.com/3',
          (server) => server.reply(200, {'id': 3}),
        );

        // Act
        await dio.get('https://api.example.com/1');
        await dio.get('https://api.example.com/2');
        await dio.get('https://api.example.com/3');

        // Wait for all events to be processed
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        expect(extension.history.length, equals(3));
        expect(extension.history[0].url, contains('/1'));
        expect(extension.history[1].url, contains('/2'));
        expect(extension.history[2].url, contains('/3'));
      });
    });

    group('WHEN working with multiple tagged Dio instances', () {
      late IacNetworkInspectorExt extension;
      late Dio apiDio;
      late Dio authDio;
      late DioAdapter apiAdapter;
      late DioAdapter authAdapter;

      setUp(() {
        extension = IacNetworkInspectorExt();
        // Initialize the extension to start listening to interceptor
        extension.onInit(MockExtensionContext());
        apiDio = Dio();
        authDio = Dio();
        apiAdapter = DioAdapter(dio: apiDio);
        authAdapter = DioAdapter(dio: authDio);

        extension.addDio(DioWrapper(dio: apiDio, tag: 'API'));
        extension.addDio(DioWrapper(dio: authDio, tag: 'Auth'));
      });

      test('THEN should differentiate requests by tag', () async {
        // Arrange
        apiAdapter.onGet(
          'https://api.example.com/data',
          (server) => server.reply(200, {'data': 'value'}),
        );
        authAdapter.onPost(
          'https://auth.example.com/login',
          (server) => server.reply(200, {'token': 'abc123'}),
        );

        // Act
        await apiDio.get('https://api.example.com/data');
        await authDio.post('https://auth.example.com/login');

        // Wait for events to be processed
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        expect(extension.history.length, equals(2));

        final apiRequest =
            extension.history.firstWhere((r) => r.dioTag == 'API');
        final authRequest =
            extension.history.firstWhere((r) => r.dioTag == 'Auth');

        expect(apiRequest.url, contains('/data'));
        expect(authRequest.url, contains('/login'));
      });
    });
  });

  group('CurlGenerator', () {
    group('GIVEN a network request', () {
      test('WHEN generating CURL THEN should include method and URL', () {
        // Arrange
        final networkData = _createMockNetworkData(
          method: 'GET',
          url: 'https://api.example.com/users',
        );

        // Act
        final curl = CurlGenerator.generate(networkData);

        // Assert
        expect(curl, contains('curl'));
        expect(curl, contains('-X GET'));
        expect(curl, contains('https://api.example.com/users'));
      });

      test('WHEN generating CURL with headers THEN should include headers', () {
        // Arrange
        final networkData = _createMockNetworkData(
          method: 'GET',
          url: 'https://api.example.com/users',
          headers: {
            'Authorization': 'Bearer token',
            'Accept': 'application/json'
          },
        );

        // Act
        final curl = CurlGenerator.generate(networkData);

        // Assert
        expect(curl, contains('-H "Authorization: Bearer token"'));
        expect(curl, contains('-H "Accept: application/json"'));
      });

      test('WHEN generating CURL with body THEN should include data', () {
        // Arrange
        final networkData = _createMockNetworkData(
          method: 'POST',
          url: 'https://api.example.com/users',
          body: {'name': 'John', 'email': 'john@example.com'},
        );

        // Act
        final curl = CurlGenerator.generate(networkData);

        // Assert
        expect(curl, contains('-d'));
        expect(curl, contains('name'));
        expect(curl, contains('John'));
      });
    });
  });
}

// Helper function to create mock network data
IacNetworkRS _createMockNetworkData({
  required String method,
  required String url,
  Map<String, dynamic>? headers,
  dynamic body,
}) {
  return IacNetworkRS(
    url: url,
    dioTag: 'Test',
    request: IacNetworkRequest(
      method: method,
      headers: headers ?? {},
      queryParameters: {},
      body: body,
      sentTime: DateTime.now(),
    ),
    response: IacNetworkResponse(
      statusCode: 200,
      duration: 100,
      receivedTime: DateTime.now(),
    ),
  );
}

// Mock extension context
class MockExtensionContext extends InAppConsoleExtensionContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
