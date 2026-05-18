import 'dart:convert';

import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_status.dart';

class DispatchOpportunity {
  const DispatchOpportunity({
    required this.orderId,
    required this.startAddress,
    this.plannedStart,
    this.plannedEnd,
    this.distanceKm,
    this.dispatchTimeoutSeconds,
    this.priority,
  });

  final String orderId;
  final String startAddress;
  final DateTime? plannedStart;
  final DateTime? plannedEnd;
  final double? distanceKm;
  final int? dispatchTimeoutSeconds;
  final String? priority;

  Run toRun() {
    final now = DateTime.now();
    return Run(
      id: orderId,
      blindRunnerId: '',
      location: startAddress,
      address: startAddress,
      timeLabel: Run.formatTimeLabel(plannedStart, plannedEnd),
      status: RunStatus.pendingAccept,
      createdAt: plannedStart ?? now,
      updatedAt: now,
      plannedStart: plannedStart,
      plannedEnd: plannedEnd,
      distanceKm: distanceKm,
      dispatchTimeoutSeconds: dispatchTimeoutSeconds,
      dispatchPriority: priority,
      isRealtimeDispatch: true,
    );
  }

  static DispatchOpportunity? tryParse(dynamic message) {
    final json = _coerceMap(message);
    if (json == null || json['type'] != 'NEW_ORDER') {
      return null;
    }
    final orderId = _readString(json['orderId'] ?? json['id']);
    final startAddress = _readString(json['startAddress']);
    if (orderId == null || startAddress == null) {
      return null;
    }
    return DispatchOpportunity(
      orderId: orderId,
      startAddress: startAddress,
      plannedStart: _parseDateTime(json['plannedStart']),
      plannedEnd: _parseDateTime(json['plannedEnd']),
      distanceKm: _readDouble(json['distanceKm']),
      dispatchTimeoutSeconds: _readInt(json['dispatchTimeoutSeconds']),
      priority: _readString(json['priority']),
    );
  }

  static Map<String, dynamic>? _coerceMap(dynamic message) {
    if (message is Map<String, dynamic>) {
      return message;
    }
    if (message is Map) {
      return message.cast<String, dynamic>();
    }
    if (message is! String || message.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return decoded.cast<String, dynamic>();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  static int? _readInt(dynamic value) {
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

  static double? _readDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
