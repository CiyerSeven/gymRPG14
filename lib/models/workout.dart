import 'package:hive/hive.dart';
import 'exercise.dart';

part 'workout.g.dart'; // Bu satır build_runner komutunu çalıştırınca oluşan dosyayı işaret eder

@HiveType(typeId: 1)
class Workout extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late DateTime date;

  @HiveField(2)
  late String? notes;

  // Antrenman içindeki egzersizler (ilişki)
  @HiveField(3)
  late List<Exercise> exercises;

  Workout({
    required this.id,
    required this.date,
    this.notes,
    required this.exercises,
  });

  int get totalSets => exercises.fold(0, (sum, e) => sum + e.sets.length);
  List<String> get workedMuscleGroups => exercises.map((e) => e.muscleGroup).toSet().toList();
}