import 'package:aidrun_demo/core/models/order_review.dart';
import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/user_role.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';
import 'package:aidrun_demo/core/network/api_client.dart';

class CreateOrderPayload {
  const CreateOrderPayload({
    required this.startLatitude,
    required this.startLongitude,
    required this.startAddress,
    required this.plannedStartTime,
    required this.plannedEndTime,
    required this.timeLabel,
    this.notes = '',
  });

  final double startLatitude;
  final double startLongitude;
  final String startAddress;
  final DateTime plannedStartTime;
  final DateTime plannedEndTime;
  final String timeLabel;
  final String notes;
}

enum OrderResponseAction { accept, decline }

extension OrderResponseActionX on OrderResponseAction {
  String get backendValue => switch (this) {
    OrderResponseAction.accept => 'ACCEPT',
    OrderResponseAction.decline => 'DECLINE',
  };
}

abstract class OrderRepository {
  Future<Run> createOrder(CreateOrderPayload payload);
  Future<Run> getOrder(String orderId);
  Future<List<Run>> listMyOrders(UserRole role);
  Future<List<Run>> listAvailableOrders();
  Future<void> cancelOrder(String orderId);
  Future<void> respondToOrder(String orderId, OrderResponseAction action);
  Future<void> acceptOrder(String orderId);
  Future<void> markEnRoute(String orderId);
  Future<void> markArrived(String orderId);
  Future<void> finishOrder(String orderId);
  Future<void> createReview(String orderId, int rating, {String comment = ''});
  Future<OrderReview?> getReview(String orderId);
}

class HttpOrderRepository implements OrderRepository {
  HttpOrderRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<Run> createOrder(CreateOrderPayload payload) async {
    final response =
        await _apiClient.post(
              '/api/orders',
              body: {
                'startLatitude': payload.startLatitude,
                'startLongitude': payload.startLongitude,
                'startAddress': payload.startAddress,
                'plannedStartTime': payload.plannedStartTime.toIso8601String(),
                'plannedEndTime': payload.plannedEndTime.toIso8601String(),
              },
            )
            as Map<String, dynamic>;
    return Run(
      id: '${response['id']}',
      blindRunnerId: '',
      location: payload.startAddress,
      address: payload.startAddress,
      timeLabel: payload.timeLabel,
      status:
          RunStatusX.fromBackend(response['status'] as String?) ??
          RunStatus.pendingMatch,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      notes: payload.notes,
      latitude: payload.startLatitude,
      longitude: payload.startLongitude,
      plannedStart: payload.plannedStartTime,
      plannedEnd: payload.plannedEndTime,
    );
  }

  @override
  Future<Run> getOrder(String orderId) async {
    final response =
        await _apiClient.get('/api/orders/$orderId') as Map<String, dynamic>;
    return _parseOrderDetail(response);
  }

  @override
  Future<List<Run>> listMyOrders(UserRole role) async {
    final response =
        await _apiClient.get(
              '/api/orders/mine',
              queryParameters: {
                'role': role.backendValue,
                'page': '0',
                'size': '20',
              },
            )
            as Map<String, dynamic>;
    final content = response['content'];
    if (content is! List) {
      return const [];
    }
    return content
        .whereType<Map>()
        .map(
          (item) => _parseOrderDetail(
            item.cast<String, dynamic>(),
            volunteerOwnershipConfirmed: role == UserRole.volunteer,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<Run>> listAvailableOrders() async {
    final response = await _apiClient.get('/api/orders/available');
    final items = _coerceList(response);
    if (items == null) {
      return const [];
    }
    return items
        .whereType<Map>()
        .map((item) => _parseAvailableOrder(item.cast<String, dynamic>()))
        .toList(growable: false);
  }

  @override
  Future<void> cancelOrder(String orderId) async {
    await _apiClient.post('/api/orders/$orderId/cancel');
  }

  @override
  Future<void> respondToOrder(
    String orderId,
    OrderResponseAction action,
  ) async {
    await _apiClient.post(
      '/api/orders/$orderId/respond',
      body: {'action': action.backendValue},
    );
  }

  @override
  Future<void> acceptOrder(String orderId) async {
    await _apiClient.post('/api/orders/$orderId/accept');
  }

  @override
  Future<void> markEnRoute(String orderId) async {
    await _apiClient.post('/api/orders/$orderId/en-route');
  }

  @override
  Future<void> markArrived(String orderId) async {
    await _apiClient.post('/api/orders/$orderId/arrived');
  }

  @override
  Future<void> finishOrder(String orderId) async {
    await _apiClient.post('/api/orders/$orderId/finish');
  }

  @override
  Future<void> createReview(
    String orderId,
    int rating, {
    String comment = '',
  }) async {
    await _apiClient.post(
      '/api/orders/$orderId/review',
      body: {'rating': rating, 'comment': comment},
    );
  }

  @override
  Future<OrderReview?> getReview(String orderId) async {
    final response = await _apiClient.get('/api/orders/$orderId/reviews');
    if (response is! Map<String, dynamic>) {
      return null;
    }
    final data = response['data'];
    if (data is! Map) {
      return null;
    }
    final json = data.cast<String, dynamic>();
    return OrderReview(
      orderId: _readInt(json['orderId']) ?? int.tryParse(orderId) ?? 0,
      rating: _readInt(json['rating']) ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Run _parseOrderDetail(
    Map<String, dynamic> json, {
    bool volunteerOwnershipConfirmed = false,
  }) {
    final plannedStart = _parseDateTime(json['plannedStart']);
    final plannedEnd = _parseDateTime(json['plannedEnd']);
    final volunteerPhone = json['volunteerPhone'] as String?;
    final blindUserPhone = json['blindUserPhone'] as String?;
    return Run(
      id: '${json['orderId'] ?? json['id'] ?? ''}',
      blindRunnerId: '',
      location: json['startAddress'] as String? ?? '',
      address: json['startAddress'] as String? ?? '',
      timeLabel: Run.formatTimeLabel(plannedStart, plannedEnd),
      status:
          RunStatusX.fromBackend(json['status'] as String?) ??
          RunStatus.pendingMatch,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt:
          _parseDateTime(json['updatedAt']) ??
          _parseDateTime(json['acceptedAt']) ??
          _parseDateTime(json['createdAt']) ??
          DateTime.now(),
      notes: json['notes'] as String? ?? '',
      plannedStart: plannedStart,
      plannedEnd: plannedEnd,
      latitude: _readDouble(json['startLatitude']),
      longitude: _readDouble(json['startLongitude']),
      volunteerPhone: volunteerPhone,
      blindUserPhone: blindUserPhone,
      volunteerOwnershipConfirmed: volunteerOwnershipConfirmed,
      volunteer: volunteerPhone == null || volunteerPhone.isEmpty
          ? null
          : VolunteerProfile(
              id: '',
              name: '志愿者',
              verificationStatus: '',
              availableTimeSlots: const [],
              phone: volunteerPhone,
            ),
    );
  }

  Run _parseAvailableOrder(Map<String, dynamic> json) {
    final plannedStart = _parseDateTime(json['plannedStart']);
    final plannedEnd = _parseDateTime(json['plannedEnd']);
    return Run(
      id: '${json['orderId'] ?? json['id'] ?? ''}',
      blindRunnerId: '',
      location: json['startAddress'] as String? ?? '',
      address: json['startAddress'] as String? ?? '',
      timeLabel: Run.formatTimeLabel(plannedStart, plannedEnd),
      status: RunStatus.pendingAccept,
      createdAt: plannedStart ?? DateTime.now(),
      updatedAt: plannedStart ?? DateTime.now(),
      plannedStart: plannedStart,
      plannedEnd: plannedEnd,
      distanceKm: _readDouble(json['distanceKm']),
      blindUserPhone: json['blindUserPhone'] as String?,
      latitude: _readDouble(json['startLatitude']),
      longitude: _readDouble(json['startLongitude']),
    );
  }

  List<dynamic>? _coerceList(dynamic response) {
    if (response is List) {
      return response;
    }
    if (response is! Map<String, dynamic>) {
      return null;
    }
    final data = response['data'];
    if (data is List) {
      return data;
    }
    final content = response['content'];
    if (content is List) {
      return content;
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

  double? _readDouble(dynamic value) {
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

  DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
