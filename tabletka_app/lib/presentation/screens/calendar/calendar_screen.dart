import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/calendar_providers.dart';
import '../today/widgets/intake_card.dart'; // Переиспользуем карточку из "Сегодня"

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _focusedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final intakesAsync = ref.watch(monthIntakesProvider(_focusedMonth));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Календарь')),
      body: Column(
        children: [
          // 1. Шапка с переключением месяцев
          _buildMonthHeader(),

          // 2. Сетка календаря (зависит от данных)
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

          const Divider(height: 1),

          // 3. Список приёмов на выбранный день
          Expanded(
            child: intakesAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (intakes) {
                final selectedDayIntakes = intakes.where((i) {
                  return i.plannedAt.year == _selectedDate.year &&
                      i.plannedAt.month == _selectedDate.month &&
                      i.plannedAt.day == _selectedDate.day;
                }).toList();

                if (selectedDayIntakes.isEmpty) {
                  return const Center(
                    child: Text(
                      'На этот день приёмов нет',
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: selectedDayIntakes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    // Адаптируем CalendarIntake под виджет TodayIntake
                    final item = selectedDayIntakes[i];
                    return Container(
                      color: Colors.transparent, // Для правильного отображения
                      child: _buildAdaptedCard(item, ref),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Виджет шапки месяца ──────────────────────────────────
  Widget _buildMonthHeader() {
    const months = [
      'Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь',
      'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
              });
            },
          ),
          Text(
            '${months[_focusedMonth.month - 1]} ${_focusedMonth.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
              });
            },
          ),
        ],
      ),
    );
  }

  // ─── Виджет сетки календаря ───────────────────────────────
  Widget _buildCalendarGrid(List<CalendarIntake> intakes) {
    // Вычисляем, сколько дней в месяце и с какого дня недели он начинается
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    // weekday: 1 = Пн, 7 = Вс. Нам нужно смещение, где Пн = 0, Вс = 6
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday - 1;

    const weekDays = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Дни недели
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays.map((d) => Text(
              d,
              style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Сетка чисел
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
                return const SizedBox.shrink(); // Пустые клетки до 1-го числа
              }

              final dayNumber = index - firstWeekday + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);

              // Есть ли приёмы в этот день?
              final hasIntakes = intakes.any((i) =>
              i.plannedAt.year == date.year &&
                  i.plannedAt.month == date.month &&
                  i.plannedAt.day == date.day);

              // Выбран ли этот день?
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.accentBlue : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      if (hasIntakes && !isSelected)
                        Positioned(
                          bottom: 4,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentBlue,
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
        ],
      ),
    );
  }

  // Адаптер для переиспользования IntakeCard
  Widget _buildAdaptedCard(CalendarIntake item, WidgetRef ref) {
    // Чтобы не переписывать IntakeCard, мы можем обернуть его или использовать
    // напрямую, если структура данных совпадает.
    // В нашем случае TodayIntake и CalendarIntake имеют одинаковые геттеры.
    // Для простоты, скопируем логику отображения карточки из TodayScreen.

    // ВАЖНО: В реальном проекте лучше вынести карточку в общий виджет,
    // принимающий абстрактный интерфейс.
    // Здесь мы просто создадим визуальную копию для календаря.

    return _CalendarCard(item: item);
  }
}

// Упрощённая копия IntakeCard для календаря
class _CalendarCard extends ConsumerWidget {
  final CalendarIntake item;
  const _CalendarCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            child: const Icon(Icons.medication, color: AppTheme.accentBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.dosage == null ? item.medicationName : '${item.medicationName} ${item.dosage}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.plannedAt.hour.toString().padLeft(2, '0')}:${item.plannedAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          _buildStatusBadge(item.status),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(IntakeStatus status) {
    Color color;
    String text;
    switch (status) {
      case IntakeStatus.taken:
        color = AppTheme.statusTaken;
        text = 'Принято';
      case IntakeStatus.skipped:
        color = AppTheme.statusSkipped;
        text = 'Пропущено';
      case IntakeStatus.postponed:
        color = AppTheme.statusPostponed;
        text = 'Отложено';
      case IntakeStatus.pending:
        color = AppTheme.statusPending;
        text = 'Ожидается';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}