import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _nameKey = 'user_name';
  static const String _soundKey = 'notification_sound_enabled';
  static const String _pinKey = 'app_pin_hash';

  static const FlutterSecureStorage _secureStorage =
      FlutterSecureStorage();

  // Получение имени пользователя
  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? 'Анна';
  }

  // Сохранение имени пользователя
  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name.trim());
  }

  // Получение настройки звука
  static Future<bool> getSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundKey) ?? true;
  }

  // Сохранение настройки звука
  static Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, enabled);
  }

  // Хеширование PIN-кода
  static String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  // Проверка наличия PIN-кода
  static Future<bool> hasPin() async {
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null;
  }

  // Сохранение PIN-кода
  static Future<void> setPin(String pin) async {
    await _secureStorage.write(
      key: _pinKey,
      value: _hashPin(pin),
    );
  }

  // Проверка PIN-кода
  static Future<bool> verifyPin(String pin) async {
    final savedPin = await _secureStorage.read(key: _pinKey);

    return savedPin != null && savedPin == _hashPin(pin);
  }

  // Удаление PIN-кода
  static Future<void> removePin() async {
    await _secureStorage.delete(key: _pinKey);
  }
}