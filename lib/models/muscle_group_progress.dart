import 'package:hive/hive.dart';

part 'muscle_group_progress.g.dart'; // Bu satır build_runner komutunu çalıştırınca oluşan dosyayı işaret eder

@HiveType(typeId: 4)
class MuscleGroupProgress extends HiveObject {
  @HiveField(0)
  late String muscleGroup;

  @HiveField(1)
  late double xp;

  @HiveField(2)
  late int level;

  MuscleGroupProgress({
    required this.muscleGroup,
    required this.xp,
    required this.level,
  });
}