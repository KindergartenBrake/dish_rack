import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/enums.dart';
import '../../providers/add_medication_provider.dart';
import '../../providers/today_providers.dart';

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

      ref.invalidate(todayIntakesProvider);

      if (mounted) {
        Navigator.of(context).pop();
      }
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
          padding: const EdgeInsets.all(16),
          children: [
            // Название
            const _Label('Название'),
            TextField(
              controller: _nameController,
              decoration: _inputDecoration('Например, Аспирин'),
            ),
            const SizedBox(height: 16),

            // Дозировка
            const _Label('Дозировка'),
            TextField(
              controller: _dosageController,
              decoration: _inputDecoration('500 мг'),
            ),
            const SizedBox(height: 16),

            // Форма выпуска
            const _Label('Форма выпуска'),
            DropdownButtonFormField<MedicationForm>(
              initialValue: _form,
              decoration: _inputDecoration(null),
              items: MedicationForm.values.map((f) {
                return DropdownMenuItem(
                  value: f,
                  child: Text(_formLabel(f)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _form = v!),
            ),
            const SizedBox(height: 16),

            // Времена приёма
            const _Label('Время приёма'),
            ..._times.asMap().entries.map((e) => _TimeRow(
              minutes: e.value,
              onChanged: (v) => setState(() => _times[e.key] = v),
              onDelete: _times.length > 1
                  ? () => setState(() => _times.removeAt(e.key))
                  : null,
            )),
            TextButton.icon(
              onPressed: () => setState(() => _times.add(480)),
              icon: const Icon(Icons.add),
              label: const Text('Добавить время'),
            ),
            const SizedBox(height: 16),

            // Периодичность
            const _Label('Периодичность'),
            DropdownButtonFormField<SchedulePeriodicity>(
              initialValue: _periodicity,
              decoration: _inputDecoration(null),
              items: SchedulePeriodicity.values.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(_periodicityLabel(p)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _periodicity = v!),
            ),

            // Дни недели (если specificDaysOfWeek)
            if (_periodicity == SchedulePeriodicity.specificDaysOfWeek) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final selected = _weekdays.contains(day);
                  return FilterChip(
                    label: Text(_weekdayLabel(day)),
                    selected: selected,
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
            const SizedBox(height: 16),

            // Даты
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Дата начала',
                    date: _startDate,
                    onPick: (d) => setState(() => _startDate = d),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'Дата окончания',
                    date: _endDate,
                    onPick: (d) => setState(() => _endDate = d),
                    onClear: _endDate == null
                        ? null
                        : () => setState(() => _endDate = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Кнопка
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String? hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _formLabel(MedicationForm f) {
    switch (f) {
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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
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
            child: OutlinedButton.icon(
              onPressed: () async {
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
              icon: const Icon(Icons.access_time),
              label: Text('$h:$m'),
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2100),
            );
            if (picked != null) onPick(picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date == null
                        ? 'Выбрать дату'
                        : '${date!.day}.${date!.month}.${date!.year}',
                    style: TextStyle(
                      color: date == null ? Colors.black54 : Colors.black87,
                    ),
                  ),
                ),
                if (onClear != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.close, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}