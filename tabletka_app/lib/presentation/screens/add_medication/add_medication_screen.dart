import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/add_medication_provider.dart';
import '../../providers/calendar_providers.dart';
import '../../providers/medications_providers.dart';
import '../../providers/today_providers.dart';
import '../../widgets/app_widgets.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();

  MedicationForm _form = MedicationForm.tablet;
  DateTime _startDate = DateTime.now();
  DateTime? _endDate;

  // Времена приёма (в минутах от начала суток)
  final List<int> _times = [480]; // 8:00 по умолчанию

  SchedulePeriodicity _periodicity = SchedulePeriodicity.daily;
  final List<int> _weekdays = [];

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите название лекарства')),
      );
      return;
    }
    if (_times.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы одно время приёма')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await addMedicationWithSchedule(
        ref: ref,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim().isEmpty
            ? null
            : _dosageController.text.trim(),
        form: _form,
        photoPath: null,
        startDate: _startDate,
        endDate: _endDate,
        timesInMinutes: _times,
        periodicity: _periodicity,
        weekdays: _periodicity == SchedulePeriodicity.specificDaysOfWeek
            ? _weekdays
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
      }

      // Инвалидация — ПОСЛЕ закрытия экрана, чтобы не пересобирать
      // виджет, который уже уходит с экрана
      ref.invalidate(todayIntakesProvider);
      ref.invalidate(monthIntakesProvider);
      ref.invalidate(medicationsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Новое лекарство'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // ── Лекарство ───────────────────────────────────
            _SectionCard(
              icon: Icons.medication_rounded,
              title: 'Лекарство',
              children: [
                const _FieldLabel('Название'),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Например, Аспирин',
                  ),
                ),
                const SizedBox(height: 14),
                const _FieldLabel('Дозировка'),
                TextField(
                  controller: _dosageController,
                  decoration: const InputDecoration(hintText: '500 мг'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Форма выпуска ───────────────────────────────
            _SectionCard(
              icon: Icons.category_rounded,
              title: 'Форма выпуска',
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: MedicationForm.values.map((f) {
                    final selected = f == _form;
                    return ChoiceChip(
                      showCheckmark: false,
                      avatar: Icon(
                        FormStyle.icon(f),
                        size: 18,
                        color: selected
                            ? AppTheme.primaryDark
                            : FormStyle.color(f),
                      ),
                      label: Text(FormStyle.label(f)),
                      selected: selected,
                      side: _chipSide(selected),
                      onSelected: (_) => setState(() => _form = f),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Расписание ──────────────────────────────────
            _SectionCard(
              icon: Icons.alarm_rounded,
              title: 'Расписание',
              children: [
                const _FieldLabel('Время приёма'),
                ..._times.asMap().entries.map((e) => _TimeRow(
                      minutes: e.value,
                      onChanged: (v) => setState(() => _times[e.key] = v),
                      onDelete: _times.length > 1
                          ? () => setState(() => _times.removeAt(e.key))
                          : null,
                    )),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _times.add(480)),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Добавить время'),
                  ),
                ),
                const SizedBox(height: 10),
                const _FieldLabel('Периодичность'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: SchedulePeriodicity.values.map((p) {
                    final selected = p == _periodicity;
                    return ChoiceChip(
                      showCheckmark: false,
                      label: Text(_periodicityLabel(p)),
                      selected: selected,
                      side: _chipSide(selected),
                      onSelected: (_) => setState(() => _periodicity = p),
                    );
                  }).toList(),
                ),

                // Дни недели (если specificDaysOfWeek)
                if (_periodicity == SchedulePeriodicity.specificDaysOfWeek) ...[
                  const SizedBox(height: 14),
                  const _FieldLabel('Дни недели'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: List.generate(7, (i) {
                      final day = i + 1;
                      final selected = _weekdays.contains(day);
                      return FilterChip(
                        showCheckmark: false,
                        label: Text(_weekdayLabel(day)),
                        selected: selected,
                        side: _chipSide(selected),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _weekdays.add(day);
                            } else {
                              _weekdays.remove(day);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Период ──────────────────────────────────────
            _SectionCard(
              icon: Icons.date_range_rounded,
              title: 'Период приёма',
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Начало',
                        date: _startDate,
                        onPick: (d) => setState(() => _startDate = d),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateField(
                        label: 'Окончание',
                        date: _endDate,
                        onPick: (d) => setState(() => _endDate = d),
                        onClear: _endDate == null
                            ? null
                            : () => setState(() => _endDate = null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Кнопка ──────────────────────────────────────
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Добавить в расписание',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  BorderSide _chipSide(bool selected) => BorderSide(
        color: selected ? AppTheme.primary : AppTheme.outline,
        width: selected ? 1.4 : 1,
      );

  String _periodicityLabel(SchedulePeriodicity p) {
    switch (p) {
      case SchedulePeriodicity.daily:
        return 'Каждый день';
      case SchedulePeriodicity.everyOtherDay:
        return 'Через день';
      case SchedulePeriodicity.specificDaysOfWeek:
        return 'По дням недели';
    }
  }

  String _weekdayLabel(int day) {
    const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return names[day - 1];
  }
}

// ─── Вспомогательные виджеты ───────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, size: 34),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;
  final VoidCallback? onDelete;

  const _TimeRow({
    required this.minutes,
    required this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: minutes ~/ 60,
                      minute: minutes % 60,
                    ),
                  );
                  if (picked != null) {
                    onChanged(picked.hour * 60 + picked.minute);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: AppTheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$h:$m',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: AppTheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.remove_circle_outline_rounded),
              color: AppTheme.danger,
            ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.date,
    required this.onPick,
    this.onClear,
  });

  String _fmt(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd.$mm.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldLabel(label),
        Material(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) onPick(picked);
            },
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
                border: Border.all(color: AppTheme.outline),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 17,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      date == null ? 'Бессрочно' : _fmt(date!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: date == null
                            ? AppTheme.textSecondary
                            : AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  if (onClear != null)
                    GestureDetector(
                      onTap: onClear,
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
