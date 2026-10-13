import '../entities/schedule.dart';

/// Абстракция репозитория расписаний.
abstract class ScheduleRepository {
  Future<List<Schedule>> getByMedicationId(int medicationId);
  Future<List<Schedule>> getActive();
  Future<int> add(Schedule schedule);
  Future<void> update(Schedule schedule);
  Future<void> delete(int id);
}