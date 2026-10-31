import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/intake.dart';
import '../../domain/entities/medication.dart';
import 'repository_providers.dart';

// Модель, объединяющая приём и лекарство (аналогично TodayIntake)
class CalendarIntake {
  final Intake intake;
  final Medication medication;

  const CalendarIntake({required this.intake, required this.medication});

  DateTime get plannedAt => intake.plannedAt;
  IntakeStatus get status => intake.status;
  String get medicationName => medication.name;
  String? get dosage => medication.dosage;
  MedicationForm get form => medication.form;
}

// Провайдер, который загружает приёмы на конкретный месяц (семейство провайдеров)
final monthIntakesProvider = FutureProvider.family<List<CalendarIntake>, DateTime>((ref, month) async {
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 1); // Первое число следующего месяца

  final intakeRepo = ref.watch(intakeRepositoryProvider);
  final medRepo = ref.watch(medicationRepositoryProvider);

  final intakes = await intakeRepo.getByDateRange(start, end);
  final result = <CalendarIntake>[];

  for (final intake in intakes) {
    final med = await medRepo.getById(intake.medicationId);
    if (med != null) {
      result.add(CalendarIntake(intake: intake, medication: med));
    }
  }

  return result;
});