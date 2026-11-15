import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/medication.dart';
import '../../providers/medications_providers.dart';
import '../../widgets/app_widgets.dart';
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
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton.filledTonal(
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primarySoft,
                foregroundColor: AppTheme.primaryDark,
              ),
              icon: const Icon(Icons.add_rounded),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AddMedicationScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: medsAsync.when(
        data: (meds) {
          if (meds.isEmpty) {
            return const EmptyState(
              icon: Icons.medication_rounded,
              title: 'Пока нет лекарств',
              message: 'Нажмите «+», чтобы добавить первое\nлекарство и расписание.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            itemCount: meds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
  final Medication medication;
  const _MedicationTile({required this.medication});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = FormStyle.color(medication.form);

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      child: Row(
        children: [
          FormBadge(form: medication.form, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.dosage == null
                      ? medication.name
                      : '${medication.name} ${medication.dosage}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        FormStyle.label(medication.form),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateRange(medication.startDate, medication.endDate),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppTheme.danger,
            tooltip: 'Удалить',
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
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(medicationsProvider.notifier).delete(medication.id!);
    }
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    String fmt(DateTime d) {
      final dd = d.day.toString().padLeft(2, '0');
      final mm = d.month.toString().padLeft(2, '0');
      return '$dd.$mm.${d.year}';
    }

    if (end == null) return 'с ${fmt(start)}';
    return '${fmt(start)} — ${fmt(end)}';
  }
}
