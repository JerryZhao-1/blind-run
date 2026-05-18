import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aidrun_demo/core/models/dispatch_opportunity.dart';
import 'package:aidrun_demo/core/models/realtime_dispatch_connection_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';

class RealtimeDispatchEvent {
  const RealtimeDispatchEvent._({this.status, this.opportunity});

  const RealtimeDispatchEvent.status(RealtimeDispatchConnectionStatus status)
    : this._(status: status);

  const RealtimeDispatchEvent.opportunity(DispatchOpportunity opportunity)
    : this._(opportunity: opportunity);

  final RealtimeDispatchConnectionStatus? status;
  final DispatchOpportunity? opportunity;
}

abstract class RealtimeWebSocket {
  Stream<dynamic> get stream;
  void add(String data);
  Future<void> close();
}

abstract class RealtimeWebSocketConnector {
  Future<RealtimeWebSocket> connect(Uri uri);
}

class DartIoRealtimeWebSocketConnector implements RealtimeWebSocketConnector {
  const DartIoRealtimeWebSocketConnector();

  @override
  Future<RealtimeWebSocket> connect(Uri uri) async {
    final socket = await WebSocket.connect(uri.toString());
    return _DartIoRealtimeWebSocket(socket);
  }
}

class _DartIoRealtimeWebSocket implements RealtimeWebSocket {
  _DartIoRealtimeWebSocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get stream => _socket;

  @override
  void add(String data) => _socket.add(data);

  @override
  Future<void> close() => _socket.close();
}

class RealtimeDispatchService {
  RealtimeDispatchService({
    required String baseUrl,
    required RealtimeWebSocketConnector connector,
    Duration reconnectDelay = const Duration(seconds: 3),
    Duration connectionTimeout = const Duration(seconds: 8),
  }) : _baseUrl = baseUrl,
       _connector = connector,
       _reconnectDelay = reconnectDelay,
       _connectionTimeout = connectionTimeout;

  final String _baseUrl;
  final RealtimeWebSocketConnector _connector;
  final Duration _reconnectDelay;
  final Duration _connectionTimeout;
  final StreamController<RealtimeDispatchEvent> _events =
      StreamController<RealtimeDispatchEvent>.broadcast();

  RealtimeWebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _reconnectTimer;
  UserRole? _activeRole;
  String? _activeToken;
  bool _shouldReconnect = false;

  Stream<RealtimeDispatchEvent> get events => _events.stream;

  RealtimeDispatchConnectionStatus status =
      RealtimeDispatchConnectionStatus.disconnected;

  Future<void> connect({required UserRole role, required String token}) async {
    if (token.trim().isEmpty || role == UserRole.unset) {
      return;
    }
    if (_activeRole == role &&
        _activeToken == token &&
        _shouldReconnect &&
        status != RealtimeDispatchConnectionStatus.disconnected) {
      return;
    }
    _activeRole = role;
    _activeToken = token;
    _shouldReconnect = true;
    _reconnectTimer?.cancel();
    await _open(emitConnecting: true);
  }

  void sendLocationUpdate({
    required double latitude,
    required double longitude,
    required bool isOnline,
  }) {
    if (!status.canSendLocationUpdate) {
      return;
    }
    _socket?.add(
      jsonEncode({
        'type': 'LOCATION_UPDATE',
        'latitude': latitude,
        'longitude': longitude,
        'online': isOnline,
        'isOnline': isOnline,
      }),
    );
  }

  Future<void> stop() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    final socket = _socket;
    _socket = null;
    await socket?.close();
    _setStatus(RealtimeDispatchConnectionStatus.disconnected);
  }

  Future<void> dispose() async {
    await stop();
    await _events.close();
  }

  Future<void> _open({required bool emitConnecting}) async {
    final role = _activeRole;
    final token = _activeToken;
    if (role == null || token == null || !_shouldReconnect) {
      return;
    }
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    final existingSocket = _socket;
    _socket = null;
    await existingSocket?.close();
    _setStatus(
      emitConnecting
          ? RealtimeDispatchConnectionStatus.connecting
          : RealtimeDispatchConnectionStatus.reconnecting,
    );
    try {
      final socket = await _connector
          .connect(_buildUri(role, token))
          .timeout(_connectionTimeout);
      if (!_shouldReconnect) {
        await socket.close();
        return;
      }
      _socket = socket;
      _setStatus(RealtimeDispatchConnectionStatus.connected);
      _socketSubscription = socket.stream.listen(
        _handleMessage,
        onError: (_) => _handleUnexpectedDisconnect(),
        onDone: _handleUnexpectedDisconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _setStatus(RealtimeDispatchConnectionStatus.unavailable);
      _scheduleReconnect();
    }
  }

  Uri _buildUri(UserRole role, String token) {
    final base = Uri.parse(_baseUrl);
    final scheme = switch (base.scheme) {
      'https' => 'wss',
      'http' => 'ws',
      _ => base.scheme,
    };
    final path = switch (role) {
      UserRole.blind => '/ws/blind',
      UserRole.volunteer => '/ws/volunteer',
      UserRole.unset => '/ws/blind',
    };
    return base.replace(
      scheme: scheme,
      path: path,
      queryParameters: {'token': token},
    );
  }

  void _handleMessage(dynamic message) {
    final opportunity = DispatchOpportunity.tryParse(message);
    if (opportunity == null) {
      return;
    }
    _events.add(RealtimeDispatchEvent.opportunity(opportunity));
  }

  void _handleUnexpectedDisconnect() {
    if (!_shouldReconnect) {
      return;
    }
    _setStatus(RealtimeDispatchConnectionStatus.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectTimer?.isActive == true) {
      return;
    }
    _reconnectTimer = Timer(_reconnectDelay, () {
      unawaited(_open(emitConnecting: false));
    });
  }

  void _setStatus(RealtimeDispatchConnectionStatus nextStatus) {
    if (status == nextStatus) {
      return;
    }
    status = nextStatus;
    _events.add(RealtimeDispatchEvent.status(nextStatus));
  }
}
