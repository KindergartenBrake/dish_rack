import 'package:drift/drift.dart';
import '../../../domain/entities/enums.dart';

/// Таблица «Лекарства».
class Medications extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get dosage => text().nullable()();
  IntColumn get form => intEnum<MedicationForm>()();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
}