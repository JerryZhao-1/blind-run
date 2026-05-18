import 'package:aidrun_demo/core/models/api_failure.dart';
import 'package:aidrun_demo/core/models/auth_session.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/network/api_client.dart';
import 'package:aidrun_demo/core/repositories/order_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'test_doubles.dart';

void main() {
  test('api client extracts message from backend error payload', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com',
      httpClient: MockClient(
        (_) async => http.Response(
          '{"success":false,"code":409,"message":"您有进行中的订单，请完成后再下单"}',
          409,
          headers: {'content-type': 'application/json'},
        ),
      ),
      sessionStore: FakeAuthSessionStore(
        const AuthSession(token: 'token', userId: 1, role: UserRole.blind),
      ),
    );

    expect(
      () => client.post('/api/orders', body: const {}),
      throwsA(
        isA<ApiFailure>().having(
          (error) => error.message,
          'message',
          '您有进行中的订单，请完成后再下单',
        ),
      ),
    );
  });

  test('api client normalizes 401 into login-expired message', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com',
      httpClient: MockClient((_) async => http.Response('', 401)),
      sessionStore: FakeAuthSessionStore(
        const AuthSession(token: 'token', userId: 1, role: UserRole.blind),
      ),
    );

    expect(
      () => client.get('/api/auth/me'),
      throwsA(
        isA<ApiFailure>().having(
          (error) => error.message,
          'message',
          '登录已失效，请重新登录',
        ),
      ),
    );
  });

  test('api client preserves backend 403 permission message', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com',
      httpClient: MockClient(
        (_) async => http.Response(
          '{"success":false,"code":403,"message":"无权访问"}',
          403,
          headers: {'content-type': 'application/json'},
        ),
      ),
      sessionStore: FakeAuthSessionStore(
        const AuthSession(token: 'token', userId: 1, role: UserRole.volunteer),
      ),
    );

    expect(
      () => client.get('/api/volunteer/profile'),
      throwsA(
        isA<ApiFailure>()
            .having((error) => error.isForbidden, 'isForbidden', isTrue)
            .having((error) => error.message, 'message', '无权访问'),
      ),
    );
  });

  test('order repository posts serial dispatch respond action', () async {
    late http.Request capturedRequest;
    late String capturedBody;
    final client = ApiClient(
      baseUrl: 'http://example.com',
      httpClient: MockClient((request) async {
        capturedRequest = request;
        capturedBody = request.body;
        return http.Response('{}', 200);
      }),
      sessionStore: FakeAuthSessionStore(
        const AuthSession(
          token: 'role-token',
          userId: 2,
          role: UserRole.volunteer,
        ),
      ),
    );
    final repository = HttpOrderRepository(client);

    await repository.respondToOrder('123', OrderResponseAction.accept);

    expect(capturedRequest.method, 'POST');
    expect(capturedRequest.url.path, '/api/orders/123/respond');
    expect(capturedRequest.headers['authorization'], 'Bearer role-token');
    expect(capturedBody, '{"action":"ACCEPT"}');
  });
}
