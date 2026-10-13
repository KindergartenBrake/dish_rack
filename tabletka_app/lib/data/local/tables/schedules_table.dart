import 'package:drift/drift.dart';
import '../../../../domain/entities/enums.dart';
import 'medications_table.dart';

/// Таблица «Расписания приёма».
class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get medicationId => integer().references(Medications, #id)();

  /// Времена храним строкой: "480,840,1200" (минуты от начала суток).
  TextColumn get timesInMinutes => text()();

  IntColumn get periodicity => intEnum<SchedulePeriodicity>()();

  /// Дни недели: "1,3,5" (1=Пн ... 7=Вс). Только для specificDaysOfWeek.
  TextColumn get weekdays => text().nullable()();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}