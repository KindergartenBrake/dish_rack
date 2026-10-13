import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/intakes_table.dart';
import 'tables/medications_table.dart';
import 'tables/schedules_table.dart';

import '../../domain/entities/enums.dart';

part 'database.g.dart';

/// Главная база данных приложения.
@DriftDatabase(tables: [Medications, Schedules, Intakes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Конструктор для тестов — принимает executor напрямую.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;
}

/// Ленивое открытие соединения: файл создастся только при первом обращении.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'tabletka.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}