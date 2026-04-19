class ResolvedOrderTime {
  const ResolvedOrderTime({
    required this.displayLabel,
    required this.plannedStart,
    required this.plannedEnd,
  });

  final String displayLabel;
  final DateTime plannedStart;
  final DateTime plannedEnd;
}

class OrderTimeResolver {
  const OrderTimeResolver();

  ResolvedOrderTime resolve(String label, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final normalized = label.trim();

    DateTime plannedStart;
    DateTime plannedEnd;

    if (normalized == '现在出发') {
      plannedStart = current.add(const Duration(minutes: 15));
      plannedEnd = plannedStart.add(const Duration(hours: 1));
    } else if (normalized == '30分钟后') {
      plannedStart = current.add(const Duration(minutes: 30));
      plannedEnd = plannedStart.add(const Duration(hours: 1));
    } else if (normalized == '明天上午') {
      final tomorrow = current.add(const Duration(days: 1));
      plannedStart = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        9,
      );
      plannedEnd = plannedStart.add(const Duration(hours: 1));
    } else if (normalized == '今天晚上') {
      final tonight = DateTime(
        current.year,
        current.month,
        current.day,
        19,
      );
      plannedStart = tonight.isAfter(current)
          ? tonight
          : tonight.add(const Duration(days: 1));
      plannedEnd = plannedStart.add(const Duration(hours: 1));
    } else {
      plannedStart = current.add(const Duration(minutes: 30));
      plannedEnd = plannedStart.add(const Duration(hours: 1));
    }

    return ResolvedOrderTime(
      displayLabel: normalized.isEmpty ? '30分钟后' : normalized,
      plannedStart: plannedStart,
      plannedEnd: plannedEnd,
    );
  }
}
