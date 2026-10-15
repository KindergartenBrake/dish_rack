import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Профиль'),
          _tile(Icons.person_outline, 'Имя пользователя', 'Анна'),
          const SizedBox(height: 16),

          _section('Напоминания'),
          _tile(Icons.notifications_outlined, 'Звук уведомлений', 'Вкл'),
          _tile(Icons.vibration, 'Вибрация', 'Вкл'),
          const SizedBox(height: 16),

          _section('Безопасность'),
          _tile(Icons.lock_outline, 'PIN-код', 'Выкл'),
          _tile(Icons.fingerprint, 'Биометрия', 'Выкл'),
          const SizedBox(height: 16),

          _section('Данные'),
          _tile(Icons.file_download_outlined, 'Экспорт отчёта', null),
          _tile(Icons.info_outline, 'О приложении', 'v0.1.0'),
        ],
      ),
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

  Widget _tile(IconData icon, String title, String? trailing) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.accentBlue),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        trailing: trailing == null
            ? const Icon(Icons.chevron_right, color: Colors.black26)
            : Text(
          trailing,
          style: const TextStyle(color: Colors.black54, fontSize: 15),
        ),
        onTap: () {},
      ),
    );
  }
}