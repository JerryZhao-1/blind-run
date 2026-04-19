enum RunStatus {
  pendingMatch,
  pendingAccept,
  inProgress,
  driverEnRoute,
  driverArrived,
  completed,
  cancelled,
  rematching,
  noVolunteer,
}

extension RunStatusX on RunStatus {
  static RunStatus? fromBackend(String? value) {
    return switch (value?.toUpperCase()) {
      'PENDING_MATCH' => RunStatus.pendingMatch,
      'PENDING_ACCEPT' => RunStatus.pendingAccept,
      'IN_PROGRESS' => RunStatus.inProgress,
      'DRIVER_EN_ROUTE' => RunStatus.driverEnRoute,
      'DRIVER_ARRIVED' => RunStatus.driverArrived,
      'COMPLETED' => RunStatus.completed,
      'CANCELLED' => RunStatus.cancelled,
      'REMATCHING' => RunStatus.rematching,
      'NO_VOLUNTEER' => RunStatus.noVolunteer,
      _ => null,
    };
  }

  String get backendValue => switch (this) {
        RunStatus.pendingMatch => 'PENDING_MATCH',
        RunStatus.pendingAccept => 'PENDING_ACCEPT',
        RunStatus.inProgress => 'IN_PROGRESS',
        RunStatus.driverEnRoute => 'DRIVER_EN_ROUTE',
        RunStatus.driverArrived => 'DRIVER_ARRIVED',
        RunStatus.completed => 'COMPLETED',
        RunStatus.cancelled => 'CANCELLED',
        RunStatus.rematching => 'REMATCHING',
        RunStatus.noVolunteer => 'NO_VOLUNTEER',
      };

  String get blindLabel => switch (this) {
        RunStatus.pendingMatch => '正在匹配志愿者',
        RunStatus.pendingAccept => '等待志愿者确认',
        RunStatus.inProgress => '志愿者已接单',
        RunStatus.driverEnRoute => '志愿者正在赶来',
        RunStatus.driverArrived => '志愿者已到达',
        RunStatus.completed => '行程已结束',
        RunStatus.cancelled => '行程已取消',
        RunStatus.rematching => '正在重新匹配',
        RunStatus.noVolunteer => '暂无志愿者响应',
      };

  String get volunteerLabel => switch (this) {
        RunStatus.pendingMatch => '匹配中',
        RunStatus.pendingAccept => '待接单',
        RunStatus.inProgress => '已接单',
        RunStatus.driverEnRoute => '前往集合地点',
        RunStatus.driverArrived => '已到达集合点',
        RunStatus.completed => '已完成',
        RunStatus.cancelled => '已取消',
        RunStatus.rematching => '重新匹配中',
        RunStatus.noVolunteer => '暂无可接订单',
      };

  bool get isBlindActive => <RunStatus>{
        RunStatus.pendingMatch,
        RunStatus.pendingAccept,
        RunStatus.inProgress,
        RunStatus.driverEnRoute,
        RunStatus.driverArrived,
        RunStatus.rematching,
        RunStatus.noVolunteer,
      }.contains(this);

  bool get isVolunteerActive => <RunStatus>{
        RunStatus.inProgress,
        RunStatus.driverEnRoute,
        RunStatus.driverArrived,
      }.contains(this);

  bool get isTerminal => <RunStatus>{
        RunStatus.completed,
        RunStatus.cancelled,
      }.contains(this);
}
