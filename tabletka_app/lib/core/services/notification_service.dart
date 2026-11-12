import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'medication_reminders',
    'Напоминания о лекарствах',
    channelDescription: 'Напоминания о времени приёма лекарств',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
  );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
  );

  static Future<void> initialize() async {
    if (!Platform.isAndroid) return;

    tz.initializeTimeZones();

    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(initializationSettings);

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    _initialized = true;
  }

  static Future<void> scheduleForIntake({
    required int intakeId,
    required DateTime plannedAt,
    required String medicationName,
    String? dosage,
  }) async {
    if (!_initialized) return;

    final localPlannedAt = plannedAt.toLocal();

    final reminder30 = localPlannedAt.subtract(
      const Duration(minutes: 30),
    );

    final reminder5 = localPlannedAt.subtract(
      const Duration(minutes: 5),
    );

    final dosageText =
        dosage == null || dosage.trim().isEmpty ? '' : ' ($dosage)';

    final now = DateTime.now();

    if (reminder30.isAfter(now)) {
      await _notifications.zonedSchedule(
        intakeId * 2,
        'Скоро время приёма',
        'Через 30 минут нужно принять $medicationName$dosageText',
        tz.TZDateTime.from(reminder30, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    if (reminder5.isAfter(now)) {
      await _notifications.zonedSchedule(
        intakeId * 2 + 1,
        'Пора подготовиться к приёму',
        'Через 5 минут нужно принять $medicationName$dosageText',
        tz.TZDateTime.from(reminder5, tz.local),
        _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static Future<void> cancelForIntake(int intakeId) async {
    if (!_initialized) return;

    await _notifications.cancel(intakeId * 2);
    await _notifications.cancel(intakeId * 2 + 1);
  }

  static Future<void> cancelAll() async {
    if (!_initialized) return;

    await _notifications.cancelAll();
  }
}