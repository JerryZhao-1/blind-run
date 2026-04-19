import 'dart:async';
import 'dart:convert';

import 'package:aidrun_demo/core/models/api_failure.dart';
import 'package:aidrun_demo/core/repositories/auth_session_store.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.httpClient,
    required this.sessionStore,
  });

  final String baseUrl;
  final http.Client httpClient;
  final AuthSessionStore sessionStore;

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    return _request('GET', path, queryParameters: queryParameters);
  }

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      'POST',
      path,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      'PUT',
      path,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<dynamic> delete(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) {
    return _request(
      'DELETE',
      path,
      queryParameters: queryParameters,
      body: body,
    );
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    final session = sessionStore.readSession();
    if (session != null) {
      headers['Authorization'] = 'Bearer ${session.token}';
    }
    String? encodedBody;
    if (body != null) {
      headers['Content-Type'] = 'application/json';
      encodedBody = jsonEncode(body);
    }

    late final http.Response response;
    try {
      response = await _send(method, uri, headers, encodedBody).timeout(
        const Duration(seconds: 12),
      );
    } on TimeoutException {
      throw const ApiFailure(message: '请求超时，请稍后重试');
    } on http.ClientException catch (error) {
      throw ApiFailure(message: '网络请求失败: ${error.message}');
    }

    return _handleResponse(response);
  }

  Future<http.Response> _send(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) {
    return switch (method) {
      'GET' => httpClient.get(uri, headers: headers),
      'POST' => httpClient.post(uri, headers: headers, body: body),
      'PUT' => httpClient.put(uri, headers: headers, body: body),
      'DELETE' => httpClient.delete(uri, headers: headers, body: body),
      _ => throw UnsupportedError('Unsupported method: $method'),
    };
  }

  dynamic _handleResponse(http.Response response) {
    final rawBody = utf8.decode(response.bodyBytes);
    final parsedBody = _tryDecodeJson(rawBody);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (rawBody.trim().isEmpty) {
        return null;
      }
      return parsedBody ?? rawBody;
    }

    final message = _extractMessage(parsedBody) ??
        (response.statusCode == 401 ? '登录已失效，请重新登录' : '请求失败，请稍后重试');
    final businessCode = parsedBody is Map<String, dynamic>
        ? _readInt(parsedBody['code'])
        : null;
    throw ApiFailure(
      message: message,
      httpStatus: response.statusCode,
      businessCode: businessCode,
      rawBody: rawBody,
    );
  }

  dynamic _tryDecodeJson(String rawBody) {
    if (rawBody.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(rawBody);
    } catch (_) {
      return null;
    }
  }

  String? _extractMessage(dynamic parsedBody) {
    if (parsedBody is! Map<String, dynamic>) {
      return null;
    }
    final message = parsedBody['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
    final error = parsedBody['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error;
    }
    return null;
  }

  int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
