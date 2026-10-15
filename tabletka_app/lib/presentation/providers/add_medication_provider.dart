import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/intake.dart';
import '../../domain/entities/medication.dart';
import '../../domain/entities/schedule.dart';
import '../../domain/usecases/generate_intakes.dart';
import 'repository_providers.dart';

/// Добавляет лекарство + расписание + генерирует приёмы на сегодня.
///
/// Возвращает id созданного лекарства.
Future<int> addMedicationWithSchedule({
  required WidgetRef ref,
  required String name,
  required String? dosage,
  required MedicationForm form,
  required String? photoPath,
  required DateTime startDate,
  required DateTime? endDate,
  required List<int> timesInMinutes,
  required SchedulePeriodicity periodicity,
  required List<int>? weekdays,
}) async {
  final medRepo = ref.read(medicationRepositoryProvider);
  final schedRepo = ref.read(scheduleRepositoryProvider);
  final intakeRepo = ref.read(intakeRepositoryProvider);

  // 1. Сохраняем лекарство
  final medId = await medRepo.add(Medication(
    name: name,
    dosage: dosage,
    form: form,
    photoPath: photoPath,
    startDate: startDate,
    endDate: endDate,
  ));

  // 2. Сохраняем расписание
  final schedule = Schedule(
    medicationId: medId,
    timesInMinutes: timesInMinutes,
    periodicity: periodicity,
    weekdays: weekdays,
    isActive: true,
  );
  final schedId = await schedRepo.add(schedule);

  // 3. Генерируем приёмы на сегодня
  final savedSchedule = schedule.copyWith(id: schedId);
  final intakes = generateIntakesForDate(
    schedule: savedSchedule,
    date: DateTime.now(),
    scheduleStartDate: startDate,
  );

  for (final intake in intakes) {
    await intakeRepo.add(intake);
  }

  return medId;
}
