import 'package:drift/drift.dart';

import '../../domain/entities/enums.dart' as domain_enums;
import '../../domain/entities/intake.dart' as domain;
import '../../domain/repositories/intake_repository.dart';
import '../local/database.dart' as db;

/// Реализация репозитория фактов приёма через Drift.
class IntakeRepositoryImpl implements IntakeRepository {
  final db.AppDatabase _db;

  IntakeRepositoryImpl(this._db);

  @override
  Future<List<domain.Intake>> getToday() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows = await (_db.select(_db.intakes)
      ..where((t) =>
      t.plannedAt.isBiggerOrEqualValue(startOfDay) &
      t.plannedAt.isSmallerThanValue(endOfDay))
      ..orderBy([(t) => OrderingTerm(expression: t.plannedAt)]))
        .get();

    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<domain.Intake>> getByMedicationId(int medicationId) async {
    final rows = await (_db.select(_db.intakes)
      ..where((t) => t.medicationId.equals(medicationId))
      ..orderBy([(t) => OrderingTerm(expression: t.plannedAt, mode: OrderingMode.desc)]))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<int> add(domain.Intake intake) async {
    return _db.into(_db.intakes).insert(_toCompanion(intake));
  }

  @override
  Future<void> markTaken(int intakeId, DateTime takenAt) async {
    await (_db.update(_db.intakes)..where((t) => t.id.equals(intakeId))).write(
      db.IntakesCompanion(
        status: Value(domain_enums.IntakeStatus.taken),
        takenAt: Value(takenAt),
      ),
    );
  }

  @override
  Future<void> markSkipped(int intakeId) async {
    await (_db.update(_db.intakes)..where((t) => t.id.equals(intakeId))).write(
      const db.IntakesCompanion(
        status: Value(domain_enums.IntakeStatus.skipped),
      ),
    );
  }

  @override
  Future<void> markPostponed(int intakeId, Duration postponeBy) async {
    final row = await (_db.select(_db.intakes)
      ..where((t) => t.id.equals(intakeId)))
        .getSingle();
    final newTime = row.plannedAt.add(postponeBy);

    await (_db.update(_db.intakes)..where((t) => t.id.equals(intakeId))).write(
      db.IntakesCompanion(
        plannedAt: Value(newTime),
        status: Value(domain_enums.IntakeStatus.postponed),
      ),
    );
  }

  // ─── Маппинг ──────────────────────────────────────────────

  domain.Intake _toDomain(db.Intake row) {
    return domain.Intake(
      id: row.id,
      scheduleId: row.scheduleId,
      medicationId: row.medicationId,
      plannedAt: row.plannedAt,
      takenAt: row.takenAt,
      status: row.status,
    );
  }

  db.IntakesCompanion _toCompanion(domain.Intake i, {bool includeId = false}) {
    return db.IntakesCompanion(
      id: includeId && i.id != null ? Value(i.id!) : const Value.absent(),
      scheduleId: Value(i.scheduleId),
      medicationId: Value(i.medicationId),
      plannedAt: Value(i.plannedAt),
      takenAt: Value(i.takenAt),
      status: Value(i.status),
    );
  }
}