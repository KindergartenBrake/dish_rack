import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/settings_providers.dart';
import '../../providers/today_providers.dart';
import '../../widgets/app_widgets.dart';
import '../add_medication/add_medication_screen.dart';
import 'widgets/intake_card.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  late Timer _timer;
  String greeting = _getGreeting();

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      final newGreeting = _getGreeting();

      if (newGreeting != greeting) {
        setState(() {
          greeting = newGreeting;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  static String _getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return 'Доброе утро';
    } else if (hour >= 12 && hour < 18) {
      return 'Добрый день';
    } else if (hour >= 18 && hour < 23) {
      return 'Добрый вечер';
    } else {
      return 'Доброй ночи';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'января', 'февраля', 'марта', 'апреля',
      'мая', 'июня', 'июля', 'августа',
      'сентября', 'октября', 'ноября', 'декабря',
    ];

    const weekdays = [
      'Понедельник', 'Вторник', 'Среда',
      'Четверг', 'Пятница', 'Суббота',
      'Воскресенье',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day} ${months[date.month - 1]}';
  }

  static String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final todayAsync = ref.watch(todayIntakesProvider);
    final name = ref.watch(userNameProvider).maybeWhen<String?>(
          data: (n) => n,
          orElse: () => null,
        );

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddMedicationScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить'),
      ),
      body: SafeArea(
        bottom: false,
        child: todayAsync.when(
          data: (items) => _buildContent(items, name),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Ошибка: $e')),
        ),
      ),
    );
  }

  Widget _buildContent(List<TodayIntake> items, String? name) {
    final taken = items.where((i) => i.status == IntakeStatus.taken).length;
    final pending =
        items.where((i) => i.status == IntakeStatus.pending).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
      children: [
        _Header(
          greeting: greeting,
          name: name,
          date: _formatDate(DateTime.now()),
        ),
        const SizedBox(height: 22),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyState(
              icon: Icons.spa_rounded,
              title: 'На сегодня приёмов нет',
              message: 'Отдыхайте! Нажмите «Добавить», чтобы\n'
                  'создать новое напоминание.',
            ),
          )
        else ...[
          _SummaryCard(
            taken: taken,
            total: items.length,
            nextLabel: pending.isEmpty
                ? null
                : '${_time(pending.first.plannedAt)} · '
                    '${pending.first.medicationName}',
          ),
          const SizedBox(height: 26),
          SectionHeader(
            title: 'Приёмы',
            trailing: pluralIntakes(items.length),
          ),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            IntakeCard(item: items[i]),
          ],
        ],
      ],
    );
  }
}

// ─── Шапка: приветствие, имя, дата ───────────────────────────

class _Header extends StatelessWidget {
  final String greeting;
  final String? name;
  final String date;

  const _Header({
    required this.greeting,
    required this.name,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final hasName = name != null && name!.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasName ? greeting : date,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasName ? name! : greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
              if (hasName) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            gradient: AppTheme.heroGradient,
            shape: BoxShape.circle,
            boxShadow: AppTheme.glowShadow,
          ),
          alignment: Alignment.center,
          child: hasName
              ? Text(
                  name!.trim()[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : const Icon(Icons.person_rounded, color: Colors.white),
        ),
      ],
    );
  }
}

// ─── Карточка прогресса дня ──────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int taken;
  final int total;
  final String? nextLabel;

  const _SummaryCard({
    required this.taken,
    required this.total,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : taken / total;
    final allTaken = total > 0 && taken == total;

    final String chipText;
    final IconData chipIcon;
    if (nextLabel != null) {
      chipText = 'Дальше · $nextLabel';
      chipIcon = Icons.notifications_active_rounded;
    } else if (allTaken) {
      chipText = 'Все приёмы выполнены';
      chipIcon = Icons.verified_rounded;
    } else {
      chipText = 'Ожидающих приёмов нет';
      chipIcon = Icons.done_all_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.heroGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: AppTheme.glowShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Декоративные круги
          Positioned(
            right: -40,
            top: -50,
            child: _Bubble(size: 160, alpha: 0.10),
          ),
          Positioned(
            right: 60,
            bottom: -70,
            child: _Bubble(size: 130, alpha: 0.07),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Сегодня принято',
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$taken',
                                  style: const TextStyle(
                                    fontSize: 46,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.5,
                                  ),
                                ),
                                TextSpan(
                                  text: '  из $total',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xCCFFFFFF),
                                  ),
                                ),
                              ],
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 84,
                            height: 84,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 9,
                              strokeCap: StrokeCap.round,
                              backgroundColor: const Color(0x33FFFFFF),
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x26FFFFFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(chipIcon, size: 18, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          chipText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final double alpha;

  const _Bubble({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}
