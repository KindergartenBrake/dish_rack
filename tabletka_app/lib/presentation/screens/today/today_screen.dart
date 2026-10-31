import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../core/services/settings_service.dart';
import '../../providers/settings_providers.dart';
import '../../providers/today_providers.dart';
import 'widgets/intake_card.dart';
import '../add_medication/add_medication_screen.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayIntakesProvider);
    final nameAsync = ref.watch(userNameProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddMedicationScreen(),
            ),
          );
        },
        backgroundColor: AppTheme.accentBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        AppTheme.accentBlue.withValues(alpha: 0.15),
                    child: const Icon(
                      Icons.person,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: nameAsync.when(
                      data: (name) => Text(
                        'Доброе утро, $name!',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                      ),
                      loading: () => const Text('Доброе утро!'),
                      error: (_, __) => const Text('Доброе утро!'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                _formatDate(DateTime.now()),
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: 16),

              Expanded(
                child: todayAsync.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'На сегодня приёмов нет',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          IntakeCard(item: items[i]),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (e, _) => Center(
                    child: Text('Ошибка: $e'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
