import 'package:hive/hive.dart';

part 'weight_entry.g.dart'; // build_runner komutu ile oluşturulacak dosya

@HiveType(typeId: 5) // Yeni bir TypeId atanmıştır
class WeightEntry extends HiveObject {
  @HiveField(0)
  late DateTime date;

  @HiveField(1)
  late double weight; // Kilo (kg)

  WeightEntry({
    required this.date,
    required this.weight,
  });
}