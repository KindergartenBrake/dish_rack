import 'enums.dart';

/// Сущность «Расписание приёма».
///
/// timesInMinutes — список времён в минутах от начала суток.
/// Например, [480, 840, 1200] = 8:00, 14:00, 20:00.
class Schedule {
  final int? id;
  final int medicationId;
  final List<int> timesInMinutes;
  final SchedulePeriodicity periodicity;

  /// Дни недели для periodicity == specificDaysOfWeek.
  /// 1 = Пн, 2 = Вт, ..., 7 = Вс.
  final List<int>? weekdays;

  final bool isActive;

  const Schedule({
    this.id,
    required this.medicationId,
    required this.timesInMinutes,
    required this.periodicity,
    this.weekdays,
    this.isActive = true,
  });

  Schedule copyWith({
    int? id,
    int? medicationId,
    List<int>? timesInMinutes,
    SchedulePeriodicity? periodicity,
    List<int>? weekdays,
    bool? isActive,
  }) {
    return Schedule(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      timesInMinutes: timesInMinutes ?? this.timesInMinutes,
      periodicity: periodicity ?? this.periodicity,
      weekdays: weekdays ?? this.weekdays,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() =>
      'Schedule(id: $id, medicationId: $medicationId, times: $timesInMinutes)';
}