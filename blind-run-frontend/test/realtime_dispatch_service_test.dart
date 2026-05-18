import 'dart:convert';

import 'package:aidrun_demo/core/models/dispatch_opportunity.dart';
import 'package:aidrun_demo/core/models/realtime_dispatch_connection_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/services/realtime_dispatch_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_doubles.dart';

void main() {
  test(
    'connects volunteer websocket with role-scoped path and token',
    () async {
      final connector = FakeRealtimeWebSocketConnector();
      final service = RealtimeDispatchService(
        baseUrl: 'http://example.com',
        connector: connector,
      );
      addTearDown(service.dispose);

      await service.connect(role: UserRole.volunteer, token: 'role-token');

      expect(connector.connectUris.single.path, '/ws/volunteer');
      expect(connector.connectUris.single.scheme, 'ws');
      expect(
        connector.connectUris.single.queryParameters['token'],
        'role-token',
      );
      expect(service.status, RealtimeDispatchConnectionStatus.connected);
    },
  );

  test('reuses active websocket for same role and token', () async {
    final connector = FakeRealtimeWebSocketConnector();
    final service = RealtimeDispatchService(
      baseUrl: 'http://example.com',
      connector: connector,
    );
    addTearDown(service.dispose);

    await service.connect(role: UserRole.volunteer, token: 'role-token');
    await service.connect(role: UserRole.volunteer, token: 'role-token');

    expect(connector.connectUris, hasLength(1));
    expect(connector.sockets.single.closed, isFalse);
  });

  test('connects blind websocket with role-scoped path', () async {
    final connector = FakeRealtimeWebSocketConnector();
    final service = RealtimeDispatchService(
      baseUrl: 'https://example.com/api',
      connector: connector,
    );
    addTearDown(service.dispose);

    await service.connect(role: UserRole.blind, token: 'blind-token');

    expect(connector.connectUris.single.path, '/ws/blind');
    expect(connector.connectUris.single.scheme, 'wss');
    expect(
      connector.connectUris.single.queryParameters['token'],
      'blind-token',
    );
  });

  test('parses NEW_ORDER and ignores unknown websocket messages', () async {
    final connector = FakeRealtimeWebSocketConnector();
    final service = RealtimeDispatchService(
      baseUrl: 'http://example.com',
      connector: connector,
    );
    addTearDown(service.dispose);
    final opportunities = <DispatchOpportunity>[];
    final subscription = service.events.listen((event) {
      final opportunity = event.opportunity;
      if (opportunity != null) {
        opportunities.add(opportunity);
      }
    });
    addTearDown(subscription.cancel);

    await service.connect(role: UserRole.volunteer, token: 'role-token');
    connector.sockets.single.emit('{"type":"PING"}');
    connector.sockets.single.emit(
      jsonEncode({
        'type': 'NEW_ORDER',
        'orderId': 123,
        'startAddress': '朝阳公园南门',
        'distanceKm': 2.5,
        'plannedStart': '2026-04-20T14:00:00',
        'plannedEnd': '2026-04-20T15:00:00',
        'dispatchTimeoutSeconds': 30,
        'priority': 'HIGH',
      }),
    );
    await Future<void>.delayed(Duration.zero);

    expect(opportunities, hasLength(1));
    expect(opportunities.single.orderId, '123');
    expect(opportunities.single.startAddress, '朝阳公园南门');
    expect(opportunities.single.distanceKm, 2.5);
    expect(opportunities.single.dispatchTimeoutSeconds, 30);
    expect(opportunities.single.priority, 'HIGH');
  });

  test('sends location updates only while websocket is connected', () async {
    final connector = FakeRealtimeWebSocketConnector();
    final service = RealtimeDispatchService(
      baseUrl: 'http://example.com',
      connector: connector,
    );
    addTearDown(service.dispose);

    service.sendLocationUpdate(
      latitude: 39.9,
      longitude: 116.4,
      isOnline: true,
    );
    await service.connect(role: UserRole.volunteer, token: 'role-token');
    service.sendLocationUpdate(
      latitude: 39.9,
      longitude: 116.4,
      isOnline: true,
    );

    expect(connector.sockets.single.sentMessages, hasLength(1));
    final message =
        jsonDecode(connector.sockets.single.sentMessages.single)
            as Map<String, dynamic>;
    expect(message['type'], 'LOCATION_UPDATE');
    expect(message['latitude'], 39.9);
    expect(message['longitude'], 116.4);
    expect(message['online'], isTrue);
  });

  test('reports unavailable and stops reconnecting after shutdown', () async {
    final connector = FakeRealtimeWebSocketConnector(failConnect: true);
    final service = RealtimeDispatchService(
      baseUrl: 'http://example.com',
      connector: connector,
      reconnectDelay: const Duration(milliseconds: 10),
    );
    addTearDown(service.dispose);

    await service.connect(role: UserRole.volunteer, token: 'role-token');
    expect(service.status, RealtimeDispatchConnectionStatus.unavailable);

    await service.stop();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(service.status, RealtimeDispatchConnectionStatus.disconnected);
    expect(connector.connectUris, hasLength(1));
  });
}
