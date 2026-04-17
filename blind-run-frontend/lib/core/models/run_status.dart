enum RunStatus {
  pending,
  accepted,
  arrived,
  running,
  completed,
  cancelled,
}

extension RunStatusX on RunStatus {
  String get blindLabel => switch (this) {
        RunStatus.pending => '正在匹配志愿者',
        RunStatus.accepted => '志愿者已接单',
        RunStatus.arrived => '志愿者已到达',
        RunStatus.running => '跑步进行中',
        RunStatus.completed => '行程已结束',
        RunStatus.cancelled => '行程已取消',
      };

  String get volunteerLabel => switch (this) {
        RunStatus.pending => '待接单',
        RunStatus.accepted => '前往集合地点',
        RunStatus.arrived => '已到达集合点',
        RunStatus.running => '陪伴跑步中',
        RunStatus.completed => '已完成',
        RunStatus.cancelled => '已取消',
      };
}
