import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/medication.dart';
import 'repository_providers.dart';

/// Провайдер списка лекарств с поддержкой удаления.
final medicationsProvider =
AsyncNotifierProvider<MedicationsNotifier, List<Medication>>(
  MedicationsNotifier.new,
);

class MedicationsNotifier extends AsyncNotifier<List<Medication>> {
  @override
  Future<List<Medication>> build() async {
    final repo = ref.watch(medicationRepositoryProvider);
    return repo.getAll();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(medicationRepositoryProvider);
      return repo.getAll();
    });
  }

  Future<void> delete(int id) async {
    final repo = ref.read(medicationRepositoryProvider);
    await repo.delete(id);
    await refresh();
  }
}