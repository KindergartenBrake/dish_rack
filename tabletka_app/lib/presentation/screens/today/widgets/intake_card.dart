import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/entities/enums.dart';
import '../../../providers/calendar_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/today_providers.dart';
import '../../../widgets/app_widgets.dart';

class IntakeCard extends ConsumerWidget {
  final TodayIntake item;

  const IntakeCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IntakeTile(
      form: item.medication.form,
      title: item.dosage == null
          ? item.medicationName
          : '${item.medicationName} ${item.dosage}',
      time: _formatTime(item.plannedAt),
      trailing: _buildStatusOrButton(context, ref),
    );
  }

  Widget _buildStatusOrButton(BuildContext context, WidgetRef ref) {
    switch (item.status) {
      case IntakeStatus.taken:
        return GestureDetector(
          onTap: () => _showUndoDialog(context, ref),
          child: StatusPill.of(IntakeStatus.taken),
        );
      case IntakeStatus.skipped:
        return StatusPill.of(IntakeStatus.skipped);
      case IntakeStatus.postponed:
        return StatusPill.of(IntakeStatus.postponed);
      case IntakeStatus.pending:
        return FilledButton.icon(
          onPressed: () async {
            final repo = ref.read(intakeRepositoryProvider);
            await repo.markTaken(item.intake.id!, DateTime.now());

            // Обновляем данные
            ref.invalidate(todayIntakesProvider);
            ref.invalidate(monthIntakesProvider);

            // Показываем SnackBar с возможностью отмены
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Лекарство отмечено как принятое'),
                  action: SnackBarAction(
                    label: 'Отменить',
                    onPressed: () async {
                      await repo.markPending(item.intake.id!);
                      ref.invalidate(todayIntakesProvider);
                      ref.invalidate(monthIntakesProvider);
                    },
                  ),
                ),
              );
            }
          },
          icon: const Icon(Icons.check_rounded, size: 18),
          label: const Text('Принял'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(13),
            ),
          ),
        );
    }
  }

  // Диалоговое окно для отмены случайного нажатия
  Future<void> _showUndoDialog(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Отменить приём?'),
        content: const Text('Вернуть статус в «Ожидается»?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Да, отменить'),
          ),
        ],
      ),
    );

    if (ok == true) {
      final repo = ref.read(intakeRepositoryProvider);
      await repo.markPending(item.intake.id!);
      ref.invalidate(todayIntakesProvider);
      ref.invalidate(monthIntakesProvider);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
