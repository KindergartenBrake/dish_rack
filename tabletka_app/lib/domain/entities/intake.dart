import 'enums.dart';

/// Сущность «Факт приёма».
///
/// Время храним в UTC, чтобы не сломаться при смене часового пояса.
class Intake {
  final int? id;
  final int scheduleId;
  final int medicationId;
  final DateTime plannedAt;
  final DateTime? takenAt;
  final IntakeStatus status;

  const Intake({
    this.id,
    required this.scheduleId,
    required this.medicationId,
    required this.plannedAt,
    this.takenAt,
    this.status = IntakeStatus.pending,
  });

  Intake copyWith({
    int? id,
    int? scheduleId,
    int? medicationId,
    DateTime? plannedAt,
    DateTime? takenAt,
    IntakeStatus? status,
  }) {
    return Intake(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      medicationId: medicationId ?? this.medicationId,
      plannedAt: plannedAt ?? this.plannedAt,
      takenAt: takenAt ?? this.takenAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() =>
      'Intake(id: $id, medicationId: $medicationId, plannedAt: $plannedAt, status: $status)';
}