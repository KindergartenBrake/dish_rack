import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../presentation/providers/repository_providers.dart';
import '../../../../presentation/providers/today_providers.dart';

class IntakeCard extends ConsumerWidget {
  final TodayIntake item;

  const IntakeCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Иконка формы
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _iconColor(item.medication.form).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForForm(item.medication.form),
              color: _iconColor(item.medication.form),
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          // Название + время
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dosage == null
                      ? item.medicationName
                      : '${item.medicationName} ${item.dosage}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(item.plannedAt),
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),

          // Кнопка / статус
          _buildStatusOrButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildStatusOrButton(BuildContext context, WidgetRef ref) {
    switch (item.status) {
      case IntakeStatus.taken:
        return _StatusBadge(
          text: 'Принято',
          color: AppTheme.statusTaken,
        );
      case IntakeStatus.skipped:
        return _StatusBadge(
          text: 'Пропущено',
          color: AppTheme.statusSkipped,
        );
      case IntakeStatus.postponed:
        return _StatusBadge(
          text: 'Отложено',
          color: AppTheme.statusPostponed,
        );
      case IntakeStatus.pending:
        return ElevatedButton(
          onPressed: () async {
            final repo = ref.read(intakeRepositoryProvider);
            await repo.markTaken(item.intake.id!, DateTime.now());
            ref.invalidate(todayIntakesProvider);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.statusTaken,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          child: const Text('Принял', style: TextStyle(fontSize: 14)),
        );
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

  Color _iconColor(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return const Color(0xFF3B82F6);
      case MedicationForm.capsule:
        return const Color(0xFFEF4444);
      case MedicationForm.syrup:
        return const Color(0xFFF59E0B);
      case MedicationForm.injection:
        return const Color(0xFF8B5CF6);
      case MedicationForm.drops:
        return const Color(0xFF10B981);
      case MedicationForm.other:
        return const Color(0xFF6B7280);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _StatusBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}