import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/intake.dart';
import '../../domain/entities/medication.dart';
import 'repository_providers.dart';
import '../../domain/entities/enums.dart';

/// Объединённая модель: приём + лекарство, к которому он относится.
class TodayIntake {
  final Intake intake;
  final Medication medication;

  const TodayIntake({required this.intake, required this.medication});

  int get medicationId => medication.id!;
  String get medicationName => medication.name;
  String? get dosage => medication.dosage;
  DateTime get plannedAt => intake.plannedAt;
  IntakeStatus get status => intake.status;
}

/// Провайдер: приёмы на сегодня + связанные лекарства.
///
/// Порядок — по времени приёма (plannedAt).
final todayIntakesProvider = FutureProvider<List<TodayIntake>>((ref) async {
  final intakeRepo = ref.watch(intakeRepositoryProvider);
  final medRepo = ref.watch(medicationRepositoryProvider);

  final intakes = await intakeRepo.getToday();
  final result = <TodayIntake>[];

  for (final intake in intakes) {
    final med = await medRepo.getById(intake.medicationId);
    if (med != null) {
      result.add(TodayIntake(intake: intake, medication: med));
    }
  }

  result.sort((a, b) => a.plannedAt.compareTo(b.plannedAt));
  return result;
});