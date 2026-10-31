
import 'dart:convert';
import 'dart:io';
import '../../providers/settings_providers.dart';
import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/settings_service.dart';
import '../../providers/database_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _userName = 'Анна';
  bool _soundEnabled = true;
  bool _hasPin = false;
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final name = await SettingsService.getUserName();
    final sound = await SettingsService.getSoundEnabled();
    final pin = await SettingsService.hasPin();

    if (!mounted) return;

    setState(() {
      _userName = name;
      _soundEnabled = sound;
      _hasPin = pin;
      _loading = false;
    });
  }

  // Редактирование имени пользователя
  Future<void> _editName() async {
    final controller = TextEditingController(text: _userName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Имя пользователя'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: 'Введите имя',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(context, name);
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null) return;

    await SettingsService.setUserName(result);
    ref.invalidate(userNameProvider);
    if (!mounted) return;

    setState(() => _userName = result);
  }

  // Ввод PIN-кода
  Future<String?> _askPin({
    required String title,
    required bool confirmation,
  }) async {
    final controller = TextEditingController();
    final confirmController = TextEditingController();

    String? error;

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'PIN-код',
                  counterText: '',
                ),
              ),
              if (confirmation)
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Повторите PIN-код',
                    counterText: '',
                  ),
                ),
              if (error != null)
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () {
                final pin = controller.text;

                if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
                  setDialogState(() {
                    error = 'Введите от 4 до 6 цифр';
                  });
                  return;
                }

                if (confirmation && pin != confirmController.text) {
                  setDialogState(() {
                    error = 'PIN-коды не совпадают';
                  });
                  return;
                }

                Navigator.pop(dialogContext, pin);
              },
              child: const Text('Продолжить'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    confirmController.dispose();

    return result;
  }

  // Создание PIN-кода
  Future<void> _createPin() async {
    final pin = await _askPin(
      title: 'Создание PIN-кода',
      confirmation: true,
    );

    if (pin == null) return;

    await SettingsService.setPin(pin);

    if (!mounted) return;

    setState(() => _hasPin = true);
    _message('PIN-код сохранён');
  }

  // Управление PIN-кодом
  Future<void> _configurePin() async {
    if (!_hasPin) {
      await _createPin();
      return;
    }

    final currentPin = await _askPin(
      title: 'Введите действующий PIN',
      confirmation: false,
    );

    if (currentPin == null) return;

    final correct = await SettingsService.verifyPin(currentPin);

    if (!correct) {
      _message('Неверный PIN-код');
      return;
    }

    if (!mounted) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Изменить PIN-код'),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_open),
              title: const Text('Отключить PIN-код'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );

    if (action == 'remove') {
      await SettingsService.removePin();

      if (!mounted) return;

      setState(() => _hasPin = false);
      _message('PIN-код отключён');
    }

    if (action == 'change') {
      await _createPin();
    }
  }

  // Переключение звука
  Future<void> _toggleSound(bool value) async {
    await SettingsService.setSoundEnabled(value);

    if (!mounted) return;

    setState(() => _soundEnabled = value);
  }

  // Экспорт отчёта
  Future<void> _exportReport() async {
    if (_exporting) return;

    setState(() => _exporting = true);

    try {
      final database = ref.read(databaseProvider);

      final intakes = await database.select(database.intakes).get();
      final medications = await database.select(database.medications).get();

      final medicationMap = {
        for (final medication in medications)
          medication.id: medication,
      };

      final rows = <List<String>>[
        [
          'Лекарство',
          'Дозировка',
          'Запланировано',
          'Фактически принято',
          'Статус',
        ],
      ];

      for (final intake in intakes) {
        final medication = medicationMap[intake.medicationId];

        String status;

        switch (intake.status.name) {
          case 'taken':
            status = 'Принято';
            break;
          case 'skipped':
            status = 'Пропущено';
            break;
          case 'postponed':
            status = 'Отложено';
            break;
          default:
            status = 'Ожидается';
        }

        rows.add([
          medication?.name ?? 'Неизвестное лекарство',
          medication?.dosage ?? '',
          _formatDate(intake.plannedAt),
          intake.takenAt == null
              ? ''
              : _formatDate(intake.takenAt!),
          status,
        ]);
      }

      final csv = rows.map((row) {
        return row.map((value) {
          final escaped = value.replaceAll('"', '""');

          if (escaped.contains(';') ||
              escaped.contains('"') ||
              escaped.contains('\n')) {
            return '"$escaped"';
          }

          return escaped;
        }).join(';');
      }).join('\r\n');

      final location = await getSaveLocation(
        suggestedName: 'tabletka_report.csv',
        acceptedTypeGroups: [
          const XTypeGroup(
            label: 'CSV',
            extensions: ['csv'],
          ),
        ],
      );

      if (location == null) return;

      await File(location.path).writeAsBytes(
        [
          0xEF,
          0xBB,
          0xBF,
          ...utf8.encode(csv),
        ],
      );

      if (!mounted) return;

      _message('Отчёт успешно сохранён');
    } catch (e) {
      if (mounted) {
        _message('Ошибка экспорта: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day.$month.$year $hour:$minute';
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text)),
      );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: AppTheme.accentBlue,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
        trailing: Text(
          trailing,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 15,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Профиль'),

          _tile(
            icon: Icons.person_outline,
            title: 'Имя пользователя',
            trailing: _userName,
            onTap: _editName,
          ),

          const SizedBox(height: 16),

          _section('Напоминания'),

          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              secondary: const Icon(
                Icons.notifications_outlined,
                color: AppTheme.accentBlue,
              ),
              title: const Text(
                'Звук уведомлений',
                style: TextStyle(fontSize: 16),
              ),
              value: _soundEnabled,
              activeColor: AppTheme.accentBlue,
              onChanged: _toggleSound,
            ),
          ),

          const SizedBox(height: 16),

          _section('Безопасность'),

          _tile(
            icon: Icons.lock_outline,
            title: 'PIN-код',
            trailing: _hasPin ? 'Вкл' : 'Выкл',
            onTap: _configurePin,
          ),

          const SizedBox(height: 16),

          _section('Данные'),

          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.file_download_outlined,
                color: AppTheme.accentBlue,
              ),
              title: const Text(
                'Экспорт отчёта',
                style: TextStyle(fontSize: 16),
              ),
              trailing: _exporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.chevron_right,
                      color: Colors.black26,
                    ),
              onTap: _exporting ? null : _exportReport,
            ),
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const ListTile(
              leading: Icon(
                Icons.info_outline,
                color: AppTheme.accentBlue,
              ),
              title: Text(
                'О приложении',
                style: TextStyle(fontSize: 16),
              ),
              trailing: Text(
                'v0.1.0',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
