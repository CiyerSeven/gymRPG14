import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/set_entry.dart';
import '../models/muscle_group_progress.dart';
import '../models/weight_entry.dart'; // YENİ: Kilo Giriş Modeli
import '../providers/gym_tracker_provider.dart'; // WeeklyProgram tipi için

class DBService {
  static const String workoutsBox = 'workouts';
  static const String progressBox = 'progress';
  static const String exerciseDefinitionsBox = 'exerciseDefinitions';
  static const String programBox = 'weeklyProgram';
  static const String settingsBox = 'settings';
  static const String weightBox = 'weightHistory'; // YENİ KUTU: Kilo Geçmişi

  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  late Box<Workout> _workoutBox;
  late Box<MuscleGroupProgress> _progressBox;
  late Box<Map<dynamic, dynamic>> _exerciseDefBox;
  late Box<Map<dynamic, dynamic>> _programBox;
  late Box<dynamic> _settingsBox;
  late Box<WeightEntry> _weightBox; // YENİ: Kilo Geçmişi Kutusu

  Future<void> init() async {
    // Adapter kayıtları
    Hive.registerAdapter(WorkoutAdapter());
    Hive.registerAdapter(ExerciseAdapter());
    Hive.registerAdapter(SetEntryAdapter());
    Hive.registerAdapter(MuscleGroupProgressAdapter());
    Hive.registerAdapter(WeightEntryAdapter()); // YENİ ADAPTER KAYDI

    // Kutu açılışları
    _workoutBox = await Hive.openBox<Workout>(workoutsBox);
    _progressBox = await Hive.openBox<MuscleGroupProgress>(progressBox);
    _exerciseDefBox = await Hive.openBox<Map<dynamic, dynamic>>(exerciseDefinitionsBox);
    _programBox = await Hive.openBox<Map<dynamic, dynamic>>(programBox);
    _settingsBox = await Hive.openBox(settingsBox);
    _weightBox = await Hive.openBox<WeightEntry>(weightBox); // YENİ KUTU AÇILIŞI
  }

  // --- KİLO VE BOY İŞLEMLERİ ---

  static const String heightKey = 'userHeight';

  // Boy bilgisini kaydet (metre cinsinden)
  Future<void> saveHeight(double height) async {
    await _settingsBox.put(heightKey, height);
  }

  // Boy bilgisini getir (Varsayılan 0.0)
  double getHeight() {
    return _settingsBox.get(heightKey) ?? 0.0;
  }

  // Kilo girişini kaydet
  Future<void> saveWeightEntry(WeightEntry entry) async {
    // Tarihi anahtar olarak kullan
    // Kilo girişinde aynı gün/saatte birden fazla kayıt olmaması için toIso8601String() kullanıldı.
    await _weightBox.put(entry.date.toIso8601String(), entry);
  }

  // Tüm kilo geçmişini getir (Tarihe göre sıralı)
  List<WeightEntry> getAllWeightEntries() {
    final list = _weightBox.values.toList();
    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  // --- WORKOUT İŞLEMLERİ ---
  Future<void> saveWorkout(Workout workout) async {
    await _workoutBox.put(workout.id, workout);
  }

  List<Workout> getAllWorkouts() {
    return _workoutBox.values.toList();
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _workoutBox.delete(workoutId);
  }

  // --- KAS GRUBU İLERLEME İŞLEMLERİ ---
  Future<void> saveMuscleGroupProgress(MuscleGroupProgress progress) async {
    await _progressBox.put(progress.muscleGroup, progress);
  }

  List<MuscleGroupProgress> getAllProgress() {
    return _progressBox.values.toList();
  }

  Future<void> initializeDefaultProgress(List<String> groups) async {
    for (var group in groups) {
      if (!_progressBox.containsKey(group)) {
        await saveMuscleGroupProgress(
          MuscleGroupProgress(muscleGroup: group, xp: 0, level: 1),
        );
      }
    }
  }

  // --- HAREKET TANIMLARI İŞLEMLERİ ---
  Future<void> saveExerciseDefinition(String name, String muscleGroup) async {
    await _exerciseDefBox.put(name, {
      'name': name,
      'muscleGroup': muscleGroup,
    });
  }

  List<Map<String, String>> getAllExerciseDefinitions() {
    return _exerciseDefBox.values.map((map) => {
      'name': map['name'] as String,
      'muscleGroup': map['muscleGroup'] as String,
    }).toList();
  }

  Future<void> deleteExerciseDefinition(String exerciseName) async {
    await _exerciseDefBox.delete(exerciseName);
  }

  Future<void> initializeDefaultDefinitions() async {
    const defaults = {
      'Bench Press': 'Göğüs',
      'Deadlift': 'Sırt',
      'Squat': 'Bacak',
      'Overhead Press': 'Omuz',
      'Barbell Curl': 'Biceps',
      'Triceps Pushdown': 'Triceps',
      'Plank': 'Core',
    };
    for (var entry in defaults.entries) {
      if (!_exerciseDefBox.containsKey(entry.key)) {
        await saveExerciseDefinition(entry.key, entry.value);
      }
    }
  }

  // --- HAFTALIK PROGRAM İŞLEMLERİ ---
  Future<void> saveWeeklyProgram(WeeklyProgram program) async {
    await _programBox.put('program', program);
  }

  Future<WeeklyProgram> getWeeklyProgram() async {
    final rawMap = _programBox.get('program');

    if (rawMap is Map) {
      final convertedMap = rawMap.map((key, value) {
        final List<String> list = (value as List).cast<String>();
        return MapEntry(key.toString(), list);
      });
      return Map<String, List<String>>.from(convertedMap);
    }

    return {};
  }
}