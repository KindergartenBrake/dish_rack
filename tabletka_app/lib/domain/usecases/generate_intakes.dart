import '../entities/enums.dart';
import '../entities/intake.dart';
import '../entities/schedule.dart';

/// Генерирует список Intake для расписания на конкретную дату.
///
/// Логика:
/// - daily: приёмы каждый день
/// - everyOtherDay: приёмы через день (считаем от startDate)
/// - specificDaysOfWeek: только в указанные дни недели
List<Intake> generateIntakesForDate({
  required Schedule schedule,
  required DateTime date,
  required DateTime scheduleStartDate,
}) {
  final intakes = <Intake>[];

  // Проверяем, попадает ли дата в расписание
  if (!_shouldTakeOnDate(schedule, date, scheduleStartDate)) {
    return intakes;
  }

  // Создаём Intake для каждого времени
  for (final minutes in schedule.timesInMinutes) {
    final plannedAt = DateTime(
      date.year,
      date.month,
      date.day,
      minutes ~/ 60,
      minutes % 60,
    );
    intakes.add(Intake(
      scheduleId: schedule.id!,
      medicationId: schedule.medicationId,
      plannedAt: plannedAt,
    ));
  }

  return intakes;
}

bool _shouldTakeOnDate(
    Schedule schedule,
    DateTime date,
    DateTime startDate,
    ) {
  switch (schedule.periodicity) {
    case SchedulePeriodicity.daily:
      return true;

    case SchedulePeriodicity.everyOtherDay:
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final current = DateTime(date.year, date.month, date.day);
      final diff = current.difference(start).inDays;
      return diff >= 0 && diff % 2 == 0;

    case SchedulePeriodicity.specificDaysOfWeek:
      if (schedule.weekdays == null || schedule.weekdays!.isEmpty) {
        return false;
      }
      return schedule.weekdays!.contains(date.weekday);
  }
}