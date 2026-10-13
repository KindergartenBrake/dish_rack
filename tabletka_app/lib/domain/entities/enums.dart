// Перечисления предметной области приложения «Таблеточница».

/// Лекарственная форма.
enum MedicationForm {
  tablet,
  capsule,
  syrup,
  injection,
  drops,
  other,
}

/// Периодичность приёма.
enum SchedulePeriodicity {
  /// Каждый день.
  daily,

  /// Через день.
  everyOtherDay,

  /// По конкретным дням недели (см. Schedule.weekdays).
  specificDaysOfWeek,
}

/// Статус факта приёма.
enum IntakeStatus {
  /// Ожидается.
  pending,

  /// Принято.
  taken,

  /// Пропущено.
  skipped,

  /// Отложено.
  postponed,
}