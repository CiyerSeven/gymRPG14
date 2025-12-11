import 'package:hive/hive.dart';

part 'set_entry.g.dart'; // Bu satır build_runner komutunu çalıştırınca oluşan dosyayı işaret eder

@HiveType(typeId: 3)
class SetEntry extends HiveObject {
  @HiveField(0)
  late double weight;

  @HiveField(1)
  late int reps;

  SetEntry({required this.weight, required this.reps});

  // Hacim (volume) hesaplama
  double get volume => weight * reps;
}