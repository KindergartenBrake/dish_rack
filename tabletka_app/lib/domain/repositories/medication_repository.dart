import '../entities/medication.dart';

/// Абстракция репозитория лекарств.
///
/// Domain не знает, как именно хранятся данные.
/// Реализация будет в data/repositories/medication_repository_impl.dart.
abstract class MedicationRepository {
  Future<List<Medication>> getAll();
  Future<Medication?> getById(int id);
  Future<int> add(Medication medication);
  Future<void> update(Medication medication);
  Future<void> delete(int id);
}