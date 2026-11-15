import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/services/settings_service.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/app_widgets.dart';

import 'package:cross_file/cross_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(initialName: _userName),
    );

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
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AskPinDialog(
        title: title,
        confirmation: confirmation,
      ),
    );
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
        for (final medication in medications) medication.id: medication,
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
          intake.takenAt == null ? '' : _formatDate(intake.takenAt!),
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

      final bytes = [
        0xEF,
        0xBB,
        0xBF,
        ...utf8.encode(csv),
      ];

      // Android: создаём временный файл и открываем меню отправки.
      if (Platform.isAndroid) {
        final directory = await getTemporaryDirectory();

        final file = File(
          '${directory.path}${Platform.pathSeparator}tabletka_report.csv',
        );

        await file.writeAsBytes(bytes, flush: true);

        await SharePlus.instance.share(
          ShareParams(
            title: 'Экспорт отчёта',
            subject: 'Отчёт о приёме лекарств',
            files: [
              XFile(file.path, mimeType: 'text/csv'),
            ],
          ),
        );

        if (!mounted) return;

        _message('Выберите приложение для сохранения или открытия отчёта');
      } else {
        // Windows: оставляем привычное окно выбора места сохранения.
        final location = await getSaveLocation(
          suggestedName: 'tabletka_report.csv',
          acceptedTypeGroups: [
            XTypeGroup(
              label: 'CSV',
              extensions: ['csv'],
            ),
          ],
        );

        if (location == null) return;

        await File(location.path).writeAsBytes(
          bytes,
          flush: true,
        );

        if (!mounted) return;

        _message('Отчёт успешно сохранён');
      }
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
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: AppTheme.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  /// Группа строк в одной карточке, с разделителями.
  Widget _group(List<Widget> tiles) {
    final children = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      if (i > 0) {
        children.add(const Divider(height: 1, indent: 70, endIndent: 16));
      }
      children.add(tiles[i]);
    }
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? value,
    Widget? trailing,
    VoidCallback? onTap,
    bool chevron = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: IconBadge(icon: icon),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (value != null)
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (chevron) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary,
                ),
              ],
            ],
          ),
      onTap: onTap,
    );
  }

  Widget _profileCard() {
    final initial =
        _userName.trim().isEmpty ? '?' : _userName.trim()[0].toUpperCase();

    return SoftCard(
      padding: const EdgeInsets.all(18),
      onTap: _editName,
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppTheme.heroGradient,
              shape: BoxShape.circle,
              boxShadow: AppTheme.glowShadow,
            ),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Нажмите, чтобы изменить имя',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const IconBadge(icon: Icons.edit_rounded, size: 38),
        ],
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
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _profileCard(),

          const SizedBox(height: 26),
          _section('Напоминания'),
          _group([
            _tile(
              icon: Icons.notifications_active_rounded,
              title: 'Звук уведомлений',
              chevron: false,
              trailing: Switch(
                value: _soundEnabled,
                onChanged: _toggleSound,
              ),
              onTap: () => _toggleSound(!_soundEnabled),
            ),
          ]),

          const SizedBox(height: 26),
          _section('Безопасность'),
          _group([
            _tile(
              icon: Icons.lock_rounded,
              title: 'PIN-код',
              value: _hasPin ? 'Включён' : 'Выключен',
              onTap: _configurePin,
            ),
          ]),

          const SizedBox(height: 26),
          _section('Данные'),
          _group([
            _tile(
              icon: Icons.file_download_rounded,
              title: 'Экспорт отчёта',
              trailing: _exporting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary,
                    ),
              onTap: _exporting ? null : _exportReport,
            ),
            _tile(
              icon: Icons.info_rounded,
              title: 'О приложении',
              value: 'v0.1.0',
              chevron: false,
            ),
          ]),
        ],
      ),
    );
  }
}

// ─── Диалог редактирования имени ───────────────────────────

class _EditNameDialog extends StatefulWidget {
  final String initialName;

  const _EditNameDialog({required this.initialName});

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Имя пользователя'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        decoration: const InputDecoration(hintText: 'Введите имя'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () {
            final name = _controller.text.trim();
            if (name.isNotEmpty) {
              Navigator.pop(context, name);
            }
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

// ─── Диалог ввода PIN-кода ─────────────────────────────────

class _AskPinDialog extends StatefulWidget {
  final String title;
  final bool confirmation;

  const _AskPinDialog({
    required this.title,
    required this.confirmation,
  });

  @override
  State<_AskPinDialog> createState() => _AskPinDialogState();
}

class _AskPinDialogState extends State<_AskPinDialog> {
  final _controller = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _controller.text;

    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      setState(() => _error = 'Введите от 4 до 6 цифр');
      return;
    }

    if (widget.confirmation && pin != _confirmController.text) {
      setState(() => _error = 'PIN-коды не совпадают');
      return;
    }

    Navigator.pop(context, pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'PIN-код',
              counterText: '',
            ),
          ),
          if (widget.confirmation)
            TextField(
              controller: _confirmController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Повторите PIN-код',
                counterText: '',
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _error!,
                style: const TextStyle(color: AppTheme.danger),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Продолжить'),
        ),
      ],
    );
  }
}
