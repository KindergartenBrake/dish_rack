import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/calendar_providers.dart';
import '../../widgets/app_widgets.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  static const _monthsNominative = [
    'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
    'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь',
  ];

  static const _monthsGenitive = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
  ];

  static const _weekdaysFull = [
    'понедельник', 'вторник', 'среда', 'четверг',
    'пятница', 'суббота', 'воскресенье',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isOnToday {
    final now = DateTime.now();
    return _focusedMonth.year == now.year &&
        _focusedMonth.month == now.month &&
        _isSameDay(_selectedDate, now);
  }

  void _changeMonth(int delta) {
    final next = DateTime(_focusedMonth.year, _focusedMonth.month + delta, 1);
    final now = DateTime.now();
    setState(() {
      _focusedMonth = next;
      // В текущем месяце выбираем сегодня, в остальных — 1-е число,
      // чтобы список под календарём не оставался пустым.
      _selectedDate = (next.year == now.year && next.month == now.month)
          ? DateTime(now.year, now.month, now.day)
          : next;
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _focusedMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  static String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final intakesAsync = ref.watch(monthIntakesProvider(_focusedMonth));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Календарь'),
        actions: [
          if (!_isOnToday)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _goToday,
                icon: const Icon(Icons.today_rounded, size: 18),
                label: const Text('Сегодня'),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // 1. Карточка календаря
          SoftCard(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            child: Column(
              children: [
                _buildMonthHeader(),
                const SizedBox(height: 8),
                intakesAsync.when(
                  loading: () => const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 300,
                    child: Center(child: Text('Ошибка: $e')),
                  ),
                  data: (intakes) => _buildCalendarGrid(intakes),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Приёмы выбранного дня
          intakesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (intakes) {
              final dayIntakes = intakes
                  .where((i) => _isSameDay(i.plannedAt, _selectedDate))
                  .toList()
                ..sort((a, b) => a.plannedAt.compareTo(b.plannedAt));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: '${_selectedDate.day} '
                        '${_monthsGenitive[_selectedDate.month - 1]}',
                    trailing: _weekdaysFull[_selectedDate.weekday - 1],
                  ),
                  if (dayIntakes.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: EmptyState(
                        icon: Icons.event_available_rounded,
                        title: 'Свободный день',
                        message: 'На этот день приёмов нет.',
                      ),
                    )
                  else
                    for (var i = 0; i < dayIntakes.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      IntakeTile(
                        form: dayIntakes[i].form,
                        title: dayIntakes[i].dosage == null
                            ? dayIntakes[i].medicationName
                            : '${dayIntakes[i].medicationName} '
                                '${dayIntakes[i].dosage}',
                        time: _time(dayIntakes[i].plannedAt),
                        trailing: StatusPill.of(dayIntakes[i].status),
                      ),
                    ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ─── Шапка месяца ─────────────────────────────────────────
  Widget _buildMonthHeader() {
    return Row(
      children: [
        _NavButton(
          icon: Icons.chevron_left_rounded,
          onTap: () => _changeMonth(-1),
        ),
        Expanded(
          child: Text(
            '${_monthsNominative[_focusedMonth.month - 1]} '
            '${_focusedMonth.year}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        _NavButton(
          icon: Icons.chevron_right_rounded,
          onTap: () => _changeMonth(1),
        ),
      ],
    );
  }

  // ─── Сетка дней ───────────────────────────────────────────
  Widget _buildCalendarGrid(List<CalendarIntake> intakes) {
    final daysInMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // weekday: 1 = Пн, 7 = Вс → смещение, где Пн = 0
    final firstWeekday =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

    const weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    // Цвет точки для каждого дня месяца.
    final Map<int, List<CalendarIntake>> byDay = {};
    for (final i in intakes) {
      byDay.putIfAbsent(i.plannedAt.day, () => []).add(i);
    }

    Color dotFor(List<CalendarIntake> list) {
      if (list.any((i) => i.status == IntakeStatus.skipped)) {
        return AppTheme.statusSkipped;
      }
      if (list.every((i) => i.status == IntakeStatus.taken)) {
        return AppTheme.statusTaken;
      }
      return AppTheme.warning;
    }

    final now = DateTime.now();

    return Column(
      children: [
        Row(
          children: weekDays
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daysInMonth + firstWeekday,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            if (index < firstWeekday) {
              return const SizedBox.shrink(); // пустые клетки до 1-го числа
            }

            final dayNumber = index - firstWeekday + 1;
            final date = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              dayNumber,
            );

            final dayIntakes = byDay[dayNumber];
            final isSelected = _isSameDay(date, _selectedDate);
            final isToday = _isSameDay(date, now);

            Color? bg;
            Color textColor = AppTheme.textPrimary;
            if (isSelected) {
              bg = AppTheme.primary;
              textColor = Colors.white;
            } else if (isToday) {
              bg = AppTheme.primarySoft;
              textColor = AppTheme.primaryDark;
            }

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _selectedDate = date),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: bg,
                  shape: BoxShape.circle,
                  boxShadow: isSelected ? AppTheme.glowShadow : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: (isSelected || isToday)
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (dayIntakes != null)
                      Positioned(
                        bottom: 6,
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : dotFor(dayIntakes),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        const _Legend(),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primarySoft,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppTheme.primaryDark, size: 26),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color color, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: [
        item(AppTheme.statusTaken, 'Всё принято'),
        item(AppTheme.warning, 'Есть ожидающие'),
        item(AppTheme.statusSkipped, 'Есть пропуски'),
      ],
    );
  }
}
