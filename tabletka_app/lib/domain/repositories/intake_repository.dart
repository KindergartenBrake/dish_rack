import '../entities/intake.dart';

/// Абстракция репозитория фактов приёма.
abstract class IntakeRepository {
  Future<List<Intake>> getToday();
  Future<List<Intake>> getByMedicationId(int medicationId);
  Future<int> add(Intake intake);
  Future<void> markTaken(int intakeId, DateTime takenAt);
  Future<void> markSkipped(int intakeId);
  Future<void> markPostponed(int intakeId, Duration postponeBy);
}