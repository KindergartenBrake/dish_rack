import 'enums.dart';

/// Сущность «Лекарство».
///
/// Чистая Domain-модель: не знает ни о Drift, ни о Flutter.
class Medication {
  final int? id;
  final String name;
  final String? dosage;
  final MedicationForm form;
  final String? photoPath;
  final DateTime startDate;
  final DateTime? endDate;
  final String? notes;

  const Medication({
    this.id,
    required this.name,
    this.dosage,
    required this.form,
    this.photoPath,
    required this.startDate,
    this.endDate,
    this.notes,
  });

  Medication copyWith({
    int? id,
    String? name,
    String? dosage,
    MedicationForm? form,
    String? photoPath,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      form: form ?? this.form,
      photoPath: photoPath ?? this.photoPath,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
    );
  }

  @override
  String toString() => 'Medication(id: $id, name: $name, dosage: $dosage)';
}