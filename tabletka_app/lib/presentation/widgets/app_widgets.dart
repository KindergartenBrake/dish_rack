import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/enums.dart';

/// Внешний вид формы выпуска: иконка, цвет и подпись — в одном месте.
abstract final class FormStyle {
  static IconData icon(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return Icons.medication_rounded;
      case MedicationForm.capsule:
        return Icons.medication_liquid_rounded;
      case MedicationForm.syrup:
        return Icons.sanitizer_rounded;
      case MedicationForm.injection:
        return Icons.vaccines_rounded;
      case MedicationForm.drops:
        return Icons.water_drop_rounded;
      case MedicationForm.other:
        return Icons.medical_services_rounded;
    }
  }

  /// Приглушённые цвета, подобранные под зелёную палитру.
  static Color color(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return const Color(0xFF23866B);
      case MedicationForm.capsule:
        return const Color(0xFFE0745F);
      case MedicationForm.syrup:
        return const Color(0xFFD69A3A);
      case MedicationForm.injection:
        return const Color(0xFF7A6FD0);
      case MedicationForm.drops:
        return const Color(0xFF3E9BC9);
      case MedicationForm.other:
        return const Color(0xFF668B7D);
    }
  }

  static String label(MedicationForm form) {
    switch (form) {
      case MedicationForm.tablet:
        return 'Таблетка';
      case MedicationForm.capsule:
        return 'Капсула';
      case MedicationForm.syrup:
        return 'Сироп';
      case MedicationForm.injection:
        return 'Инъекция';
      case MedicationForm.drops:
        return 'Капли';
      case MedicationForm.other:
        return 'Другое';
    }
  }
}

/// «приём / приёма / приёмов» с числом.
String pluralIntakes(int n) {
  final m10 = n % 10;
  final m100 = n % 100;
  final String word;
  if (m10 == 1 && m100 != 11) {
    word = 'приём';
  } else if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) {
    word = 'приёма';
  } else {
    word = 'приёмов';
  }
  return '$n $word';
}

/// Белая карточка с мягкой тенью и тонкой рамкой.
class SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusM);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: color ?? AppTheme.surface,
        borderRadius: radius,
        border: Border.all(color: AppTheme.outline, width: 0.7),
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Скруглённый квадрат с иконкой.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppTheme.primary,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.33),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

/// Значок формы выпуска (цвет зависит от формы).
class FormBadge extends StatelessWidget {
  final MedicationForm form;
  final double size;

  const FormBadge({super.key, required this.form, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return IconBadge(
      icon: FormStyle.icon(form),
      color: FormStyle.color(form),
      size: size,
    );
  }
}

/// Таблетка-статус: «Принято», «Пропущено» и т.д.
class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const StatusPill({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  factory StatusPill.of(IntakeStatus status) {
    switch (status) {
      case IntakeStatus.taken:
        return const StatusPill(
          text: 'Принято',
          color: AppTheme.statusTaken,
          icon: Icons.check_rounded,
        );
      case IntakeStatus.skipped:
        return const StatusPill(
          text: 'Пропущено',
          color: AppTheme.statusSkipped,
          icon: Icons.close_rounded,
        );
      case IntakeStatus.postponed:
        return const StatusPill(
          text: 'Отложено',
          color: AppTheme.statusPostponed,
          icon: Icons.update_rounded,
        );
      case IntakeStatus.pending:
        return const StatusPill(
          text: 'Ожидается',
          color: AppTheme.statusPending,
          icon: Icons.schedule_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Строка-приём: значок формы, название, время и произвольный trailing.
/// Используется и на «Сегодня», и в «Календаре».
class IntakeTile extends StatelessWidget {
  final MedicationForm form;
  final String title;
  final String time;
  final Widget trailing;

  const IntakeTile({
    super.key,
    required this.form,
    required this.title,
    required this.time,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          FormBadge(form: form),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 14,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

/// Заголовок секции списка.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}

/// Пустое состояние: круглая иконка, заголовок и подсказка.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: const BoxDecoration(
                color: AppTheme.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Icon(icon, size: 36, color: AppTheme.primary),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
