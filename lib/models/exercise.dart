import 'package:hive/hive.dart';
import 'set_entry.dart';

part 'exercise.g.dart'; // Bu satır build_runner komutunu çalıştırınca oluşan dosyayı işaret eder

@HiveType(typeId: 2)
class Exercise extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String muscleGroup;

  // Bu egzersize ait setler (ilişki)
  @HiveField(3)
  late List<SetEntry> sets;

  Exercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
    required this.sets,
  });

  // En ağır seti bul (Analiz için)
  SetEntry? get heaviestSet {
    if (sets.isEmpty) return null;
    return sets.reduce((a, b) => a.weight > b.weight ? a : b);
  }

  // Toplam hacim
  double get totalVolume => sets.fold(0.0, (sum, set) => sum + set.volume);
}