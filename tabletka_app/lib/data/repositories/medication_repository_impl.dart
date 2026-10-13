import 'package:drift/drift.dart';

import '../../domain/entities/enums.dart' as domain_enums;
import '../../domain/entities/medication.dart' as domain;
import '../../domain/repositories/medication_repository.dart';
import '../local/database.dart' as db;

/// Реализация репозитория лекарств через Drift.
class MedicationRepositoryImpl implements MedicationRepository {
  final db.AppDatabase _db;

  MedicationRepositoryImpl(this._db);

  @override
  Future<List<domain.Medication>> getAll() async {
    final rows = await _db.select(_db.medications).get();
    return rows.map(_toDomain).toList();
  }

  @override
  Future<domain.Medication?> getById(int id) async {
    final row = await (_db.select(_db.medications)
      ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<int> add(domain.Medication medication) async {
    return _db.into(_db.medications).insert(_toCompanion(medication));
  }

  @override
  Future<void> update(domain.Medication medication) async {
    await (_db.update(_db.medications)
      ..where((t) => t.id.equals(medication.id!)))
        .write(_toCompanion(medication, includeId: false));
  }

  @override
  Future<void> delete(int id) async {
    await (_db.delete(_db.medications)..where((t) => t.id.equals(id))).go();
  }

  // ─── Маппинг ──────────────────────────────────────────────

  domain.Medication _toDomain(db.Medication row) {
    return domain.Medication(
      id: row.id,
      name: row.name,
      dosage: row.dosage,
      form: _formFromDb(row.form),
      photoPath: row.photoPath,
      startDate: row.startDate,
      endDate: row.endDate,
      notes: row.notes,
    );
  }

  db.MedicationsCompanion _toCompanion(
      domain.Medication m, {
        bool includeId = false,
      }) {
    return db.MedicationsCompanion(
      id: includeId && m.id != null
          ? Value(m.id!)
          : const Value.absent(),
      name: Value(m.name),
      dosage: Value(m.dosage),
      form: Value(_formToDb(m.form)),
      photoPath: Value(m.photoPath),
      startDate: Value(m.startDate),
      endDate: Value(m.endDate),
      notes: Value(m.notes),
    );
  }

  domain_enums.MedicationForm _formFromDb(domain_enums.MedicationForm value) {
    return value;
  }

  domain_enums.MedicationForm _formToDb(domain_enums.MedicationForm value) {
    return value;
  }
}