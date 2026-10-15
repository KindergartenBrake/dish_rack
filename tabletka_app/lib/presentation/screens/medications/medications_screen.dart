import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/medications_providers.dart';
import '../add_medication/add_medication_screen.dart';

class MedicationsScreen extends ConsumerWidget {
  const MedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Лекарства'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddMedicationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: medsAsync.when(
        data: (meds) {
          if (meds.isEmpty) {
            return const Center(
              child: Text(
                'Пока нет лекарств.\nНажмите «+», чтобы добавить.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: meds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _MedicationTile(medication: meds[i]),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
      ),
    );
  }
}

class _MedicationTile extends ConsumerWidget {
  final dynamic medication;
  const _MedicationTile({required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForForm(medication.form),
              color: AppTheme.accentBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.dosage == null
                      ? medication.name
                      : '${medication.name} ${medication.dosage}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDateRange(medication.startDate, medication.endDate),
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Удалить лекарство?'),
        content: Text('«${medication.name}» будет удалено вместе с расписанием.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(medicationsProvider.notifier).delete(medication.id!);
    }
  }

  IconData _iconForForm(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return Icons.medication;
      case MedicationForm.capsule:
        return Icons.medication_liquid;
      case MedicationForm.syrup:
        return Icons.sanitizer;
      case MedicationForm.injection:
        return Icons.vaccines;
      case MedicationForm.drops:
        return Icons.water_drop;
      case MedicationForm.other:
        return Icons.medical_services;
    }
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    String fmt(DateTime d) => '${d.day}.${d.month}.${d.year}';
    if (end == null) return 'с ${fmt(start)}';
    return '${fmt(start)} — ${fmt(end)}';
  }
}