import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/intake_repository_impl.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../data/repositories/schedule_repository_impl.dart';
import '../../domain/repositories/intake_repository.dart';
import '../../domain/repositories/medication_repository.dart';
import '../../domain/repositories/schedule_repository.dart';
import 'database_provider.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  return MedicationRepositoryImpl(ref.watch(databaseProvider));
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(ref.watch(databaseProvider));
});

final intakeRepositoryProvider = Provider<IntakeRepository>((ref) {
  return IntakeRepositoryImpl(ref.watch(databaseProvider));
});