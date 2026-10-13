import 'package:drift/drift.dart';

import '../../domain/entities/enums.dart' as domain_enums;
import '../../domain/entities/schedule.dart' as domain;
import '../../domain/repositories/schedule_repository.dart';
import '../local/database.dart' as db;

/// Реализация репозитория расписаний через Drift.
class ScheduleRepositoryImpl implements ScheduleRepository {
  final db.AppDatabase _db;

  ScheduleRepositoryImpl(this._db);

  @override
  Future<List<domain.Schedule>> getByMedicationId(int medicationId) async {
    final rows = await (_db.select(_db.schedules)
      ..where((t) => t.medicationId.equals(medicationId)))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<List<domain.Schedule>> getActive() async {
    final rows = await (_db.select(_db.schedules)
      ..where((t) => t.isActive.equals(true)))
        .get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<int> add(domain.Schedule schedule) async {
    return _db.into(_db.schedules).insert(_toCompanion(schedule));
  }

  @override
  Future<void> update(domain.Schedule schedule) async {
    await (_db.update(_db.schedules)
      ..where((t) => t.id.equals(schedule.id!)))
        .write(_toCompanion(schedule, includeId: false));
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.schedules)..where((t) => t.id.equals(id))).go();
  }

  // ─── Маппинг ──────────────────────────────────────────────

  domain.Schedule _toDomain(db.Schedule row) {
    return domain.Schedule(
      id: row.id,
      medicationId: row.medicationId,
      timesInMinutes: _parseIntList(row.timesInMinutes),
      periodicity: row.periodicity,
      weekdays: row.weekdays == null ? null : _parseIntList(row.weekdays!),
      isActive: row.isActive,
    );
  }

  db.SchedulesCompanion _toCompanion(
      domain.Schedule s, {
        bool includeId = false,
      }) {
    return db.SchedulesCompanion(
      id: includeId && s.id != null
          ? Value(s.id!)
          : const Value.absent(),
      medicationId: Value(s.medicationId),
      timesInMinutes: Value(_joinIntList(s.timesInMinutes)),
      periodicity: Value(s.periodicity),
      weekdays: Value(s.weekdays == null ? null : _joinIntList(s.weekdays!)),
      isActive: Value(s.isActive),
    );
  }

  // ─── Утилиты ─────────────────────────────────────────────

  String _joinIntList(List<int> list) => list.join(',');

  List<int> _parseIntList(String raw) {
    if (raw.isEmpty) return [];
    return raw.split(',').map(int.parse).toList();
  }
}