import 'package:aidrun_demo/core/models/run.dart';
import 'package:aidrun_demo/core/models/run_rating.dart';
import 'package:aidrun_demo/core/models/run_status.dart';
import 'package:aidrun_demo/core/models/volunteer_profile.dart';

abstract class RunRepository {
  List<Run> loadRuns();
  List<Run> createBlindRun({
    required String blindRunnerId,
    required String location,
    required String address,
    required double latitude,
    required double longitude,
    required String timeLabel,
    String notes,
  });
  List<Run> acceptRun({
    required String runId,
    required VolunteerProfile volunteer,
  });
  List<Run> updateRunStatus({
    required String runId,
    required RunStatus status,
  });
  List<Run> cancelRun(String runId);
  List<Run> rateRun({
    required String runId,
    required RunRating rating,
  });
}

class LocalRunRepository implements RunRepository {
  LocalRunRepository() : _runs = _buildSeedRuns();

  List<Run> _runs;
  int _counter = 100;

  @override
  List<Run> loadRuns() => List.unmodifiable(_runs);

  @override
  List<Run> createBlindRun({
    required String blindRunnerId,
    required String location,
    required String address,
    required double latitude,
    required double longitude,
    required String timeLabel,
    String notes = '',
  }) {
    final now = DateTime.now();
    _runs = [
      Run(
        id: 'run-${_counter++}',
        blindRunnerId: blindRunnerId,
        location: location,
        address: address,
        timeLabel: timeLabel,
        notes: notes,
        status: RunStatus.pending,
        createdAt: now,
        updatedAt: now,
        latitude: latitude,
        longitude: longitude,
      ),
      ..._runs,
    ];
    return loadRuns();
  }

  @override
  List<Run> acceptRun({
    required String runId,
    required VolunteerProfile volunteer,
  }) {
    _runs = _runs
        .map(
          (run) => run.id == runId
              ? run.copyWith(
                  status: RunStatus.accepted,
                  volunteer: volunteer,
                  updatedAt: DateTime.now(),
                )
              : run,
        )
        .toList(growable: false);
    return loadRuns();
  }

  @override
  List<Run> updateRunStatus({
    required String runId,
    required RunStatus status,
  }) {
    _runs = _runs
        .map(
          (run) => run.id == runId
              ? run.copyWith(
                  status: status,
                  updatedAt: DateTime.now(),
                  distanceKm: status == RunStatus.completed ? 3.2 : run.distanceKm,
                  durationMinutes:
                      status == RunStatus.completed ? 34 : run.durationMinutes,
                )
              : run,
        )
        .toList(growable: false);
    return loadRuns();
  }

  @override
  List<Run> cancelRun(String runId) {
    return updateRunStatus(runId: runId, status: RunStatus.cancelled);
  }

  @override
  List<Run> rateRun({
    required String runId,
    required RunRating rating,
  }) {
    _runs = _runs
        .map(
          (run) => run.id == runId
              ? run.copyWith(blindRating: rating, updatedAt: DateTime.now())
              : run,
        )
        .toList(growable: false);
    return loadRuns();
  }

  static List<Run> _buildSeedRuns() {
    final now = DateTime.now();
    return [
      Run(
        id: 'mock-1',
        blindRunnerId: 'community-blind-1',
        location: '奥林匹克森林公园南园',
        address: '北京市朝阳区科荟路33号',
        timeLabel: '今天 18:00',
        notes: '第一次跑，希望配速慢一点',
        status: RunStatus.pending,
        createdAt: now.subtract(const Duration(hours: 3)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        latitude: 40.0150,
        longitude: 116.3900,
      ),
      Run(
        id: 'mock-2',
        blindRunnerId: 'community-blind-2',
        location: '朝阳公园东门',
        address: '北京市朝阳区朝阳公园路1号',
        timeLabel: '明天 07:30',
        notes: '带导盲犬',
        status: RunStatus.pending,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
        latitude: 39.9435,
        longitude: 116.4830,
      ),
      Run(
        id: 'mock-3',
        blindRunnerId: 'community-blind-3',
        location: '天坛公园北门',
        address: '北京市东城区天坛东里甲1号',
        timeLabel: '今天 19:00',
        notes: '',
        status: RunStatus.pending,
        createdAt: now.subtract(const Duration(hours: 9)),
        updatedAt: now.subtract(const Duration(hours: 9)),
        latitude: 39.8837,
        longitude: 116.4128,
      ),
      Run(
        id: 'history-1',
        blindRunnerId: 'community-blind-9',
        location: '小区跑道',
        address: '社区内部健身步道',
        timeLabel: '上周六 07:00',
        status: RunStatus.completed,
        volunteer: const VolunteerProfile(
          id: 'demo-volunteer-id',
          name: '爱心志愿者',
          rating: 4.98,
          phone: '13800138000',
          avatarSeed: 'volunteer-main',
        ),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
        latitude: 39.91,
        longitude: 116.41,
        distanceKm: 5.4,
        durationMinutes: 48,
      ),
    ];
  }
}
