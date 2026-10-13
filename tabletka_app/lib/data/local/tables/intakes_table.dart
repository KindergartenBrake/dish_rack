import 'package:drift/drift.dart';
import '../../../../domain/entities/enums.dart';
import 'medications_table.dart';
import 'schedules_table.dart';

/// Таблица «Факты приёма».
class Intakes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get scheduleId => integer().references(Schedules, #id)();
  IntColumn get medicationId => integer().references(Medications, #id)();
  DateTimeColumn get plannedAt => dateTime()();
  DateTimeColumn get takenAt => dateTime().nullable()();
  IntColumn get status => intEnum<IntakeStatus>()();
}