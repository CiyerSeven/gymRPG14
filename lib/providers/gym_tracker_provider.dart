import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/db_service.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/muscle_group_progress.dart';
import '../models/set_entry.dart';
import '../models/weight_entry.dart'; // YENİ: Kilo Giriş Modeli
import 'dart:math';

const uuid = Uuid();

// Program verisi için tip tanımı
typedef WeeklyProgram = Map<String, List<String>>;

class GymTrackerProvider extends ChangeNotifier {
  final DBService _dbService = DBService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Sabitler
  final Map<String, double> _muscleGroupMultipliers = {
    'Göğüs': 1.0, 'Sırt': 1.0, 'Bacak': 1.2, 'Omuz': 0.9, 'Biceps': 0.8, 'Triceps': 0.8, 'Core': 0.7,
  };

  final List<String> _allMuscleGroups = [
    'Göğüs', 'Sırt', 'Bacak', 'Omuz', 'Biceps', 'Triceps', 'Core',
  ];

  // TEMA REFERANSLARI
  static const Color primaryDark = Color(0xFF222831);
  static const Color surfaceDark = Color(0xFF393E46);
  static const Color taupeAccent = Color(0xFF948979);
  static const Color accentLight = Color(0xFFF0EAE3);
  static const Color highlightColor = Color(0xFFB8A287);

  // Uygulama Veri Durumu
  List<Workout> workouts = [];
  List<MuscleGroupProgress> progress = [];
  List<Map<String, String>> exerciseDefinitions = [];
  WeeklyProgram weeklyProgram = {};

  // YENİ KİŞİSEL VERİ ALANLARI
  double userHeight = 0.0; // Boy (metre cinsinden)
  List<WeightEntry> weightHistory = []; // Kilo geçmişi

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // Varsayılan Temayı Uygula (Statik tema)
  ThemeData get currentTheme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: primaryDark,
    cardColor: surfaceDark,
    primaryColor: highlightColor,
    colorScheme: ColorScheme.dark(
      primary: highlightColor,
      secondary: taupeAccent,
      surface: surfaceDark,
      background: primaryDark,
      onPrimary: primaryDark,
      onSurface: accentLight,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: accentLight,
      titleTextStyle: TextStyle(color: accentLight, fontSize: 20, fontWeight: FontWeight.bold),
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: accentLight,
      unselectedItemColor: taupeAccent,
      type: BottomNavigationBarType.fixed,
    ),
    textTheme: Typography.whiteMountainView,
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: accentLight.withOpacity(0.8)),
      hintStyle: TextStyle(color: taupeAccent),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: taupeAccent),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: taupeAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: highlightColor, width: 2),
      ),
      fillColor: surfaceDark,
      filled: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: highlightColor,
        foregroundColor: primaryDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );


  GymTrackerProvider() {
    _initData();
  }

  // Hive'dan verileri yükleyen ve varsayılanları oluşturan metod
  Future<void> _initData() async {
    try {
      await _dbService.init();

      await _dbService.initializeDefaultDefinitions();
      await _dbService.initializeDefaultProgress(_allMuscleGroups);

      // Ana Veri Yüklemeleri
      workouts = _dbService.getAllWorkouts();
      progress = _dbService.getAllProgress();
      exerciseDefinitions = _dbService.getAllExerciseDefinitions();
      weeklyProgram = await _dbService.getWeeklyProgram();

      // YENİ: Kişisel Veri Yüklemeleri
      userHeight = _dbService.getHeight();
      weightHistory = _dbService.getAllWeightEntries();

    } catch (e) {
      print("KRİTİK HATA: Veri başlatılırken bir istisna oluştu. Uygulama yine de devam edecek. Hata: $e");
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // --- KİŞİSEL VERİ İŞLEMLERİ ---
  Future<void> saveHeight(double height) async {
    await _dbService.saveHeight(height);
    userHeight = height;
    notifyListeners();
  }

  Future<void> saveWeightEntry(WeightEntry entry) async {
    await _dbService.saveWeightEntry(entry);
    weightHistory = _dbService.getAllWeightEntries(); // Geçmişi yeniden çek
    notifyListeners();
  }


  // Genel level hesaplama
  int get overallLevel {
    if (progress.isEmpty) return 1;

    double totalWeightedLevel = 0.0;
    int groupCount = progress.length;

    for (var prog in progress) {
      final requiredXp = getRequiredXpForNextLevel(prog.level);
      double progressRatio = 0.0;

      if (requiredXp > 0) {
        progressRatio = (prog.xp / requiredXp).clamp(0.0, 1.0);
      }

      totalWeightedLevel += prog.level + progressRatio;
    }

    final averageLevel = totalWeightedLevel / groupCount;

    return max(1, averageLevel.floor());
  }

  // XP için gereken miktar
  int getRequiredXpForNextLevel(int currentLevel) {
    return currentLevel * 1000;
  }

  // XP hesaplama
  double _calculateXpForSet(double weight, int reps, String muscleGroup) {
    final multiplier = _muscleGroupMultipliers[muscleGroup] ?? 1.0;
    return weight * reps * multiplier;
  }

  // Sesi Çalar
  void _playLevelUpSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/levelup.mp3'));
    } catch (e) {
      print("Hata: Level up sesi çalınamadı. Dosya yolu (assets/sounds/levelup.mp3) veya assets tanımını kontrol edin: $e");
    }
  }

  Future<void> _updateMuscleGroupXp(String muscleGroup, double newXp) async {
    try {
      final prog =
      progress.firstWhere((p) => p.muscleGroup == muscleGroup);
      prog.xp += newXp;

      var requiredXp = getRequiredXpForNextLevel(prog.level);
      bool leveledUp = false;

      while (prog.xp >= requiredXp) {
        prog.xp -= requiredXp;
        prog.level += 1;
        requiredXp = getRequiredXpForNextLevel(prog.level);
        leveledUp = true;
      }

      if (leveledUp) {
        _playLevelUpSound();
      }

      await _dbService.saveMuscleGroupProgress(prog);
    } catch (e) {
      print(
          'Hata: Kas grubu bulunamadı veya initialize edilmedi: $muscleGroup');
    }
  }

  Future<void> _recalculateAllProgress() async {
    for (var prog in progress) {
      prog.level = 1;
      prog.xp = 0;
      await _dbService.saveMuscleGroupProgress(prog);
    }

    final allWorkouts = workouts.toList()..sort((a, b) => a.date.compareTo(b.date));

    for (var workout in allWorkouts) {
      for (var exercise in workout.exercises) {
        final muscleGroup = exercise.muscleGroup;
        var totalXpForExercise = 0.0;

        for (var set in exercise.sets) {
          totalXpForExercise += _calculateXpForSet(set.weight, set.reps, muscleGroup);
        }

        await _updateMuscleGroupXp(muscleGroup, totalXpForExercise);
      }
    }
    notifyListeners();
  }

  void addExerciseToProgram(String day, String exerciseName) async {
    final List<String> currentList = weeklyProgram[day] ?? [];
    if (!currentList.contains(exerciseName)) {
      currentList.add(exerciseName);
      weeklyProgram[day] = currentList;
      await _dbService.saveWeeklyProgram(weeklyProgram);
      notifyListeners();
    }
  }

  void removeExerciseFromProgram(String day, String exerciseName) async {
    if (weeklyProgram.containsKey(day)) {
      weeklyProgram[day]!.remove(exerciseName);
      await _dbService.saveWeeklyProgram(weeklyProgram);
      notifyListeners();
    }
  }

  Future<void> addWorkout(
      DateTime date,
      List<Exercise> exercises,
      String? notes,
      ) async {
    final newWorkout = Workout(
      id: uuid.v4(),
      date: date,
      exercises: exercises,
      notes: notes,
    );

    for (final exercise in exercises) {
      final muscleGroup = exercise.muscleGroup;
      var totalXpForExercise = 0.0;

      for (final set in exercise.sets) {
        totalXpForExercise += _calculateXpForSet(
          set.weight,
          set.reps,
          muscleGroup,
        );
      }

      await _updateMuscleGroupXp(muscleGroup, totalXpForExercise);
    }

    await _dbService.saveWorkout(newWorkout);
    workouts.add(newWorkout);

    notifyListeners();
  }

  Future<void> updateWorkout(Workout updatedWorkout) async {
    await _dbService.saveWorkout(updatedWorkout);

    final index = workouts.indexWhere((w) => w.id == updatedWorkout.id);
    if (index != -1) {
      workouts[index] = updatedWorkout;
    }

    await _recalculateAllProgress();
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _dbService.deleteWorkout(workoutId);

    workouts.removeWhere((w) => w.id == workoutId);

    await _recalculateAllProgress();
  }

  Future<void> addExerciseDefinition(
      String name,
      String muscleGroup,
      ) async {
    final exists = exerciseDefinitions.any((e) => e['name'] == name);
    if (!exists) {
      await _dbService.saveExerciseDefinition(name, muscleGroup);
      exerciseDefinitions.add({
        'name': name,
        'muscleGroup': muscleGroup,
      });
      notifyListeners();
    }
  }

  Future<void> deleteExerciseDefinition(String exerciseName) async {
    await _dbService.deleteExerciseDefinition(exerciseName);

    exerciseDefinitions
        .removeWhere((def) => def['name'] == exerciseName);

    notifyListeners();
  }

  Exercise? getPreviousExerciseData(String exerciseName) {
    final sortedWorkouts = workouts.toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final workout in sortedWorkouts) {
      try {
        final previousExercise = workout.exercises.firstWhere(
              (e) => e.name == exerciseName,
        );
        if (previousExercise.sets.isNotEmpty) {
          return previousExercise;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  double calculateOneRepMax(double weight, int reps) {
    if (reps == 0) return 0.0;
    if (reps == 1) return weight;

    if (reps > 10) reps = 10;

    return weight / (1.0278 - (0.0278 * reps));
  }

  double getMaxOneRepMax(String exerciseName) {
    double max1RM = 0.0;

    final allRecords = workouts.expand((w) => w.exercises)
        .where((e) => e.name == exerciseName)
        .toList();

    for (var exercise in allRecords) {
      for (var set in exercise.sets) {
        if (set.reps > 0 && set.weight > 0) {
          final current1RM = calculateOneRepMax(set.weight, set.reps);
          if (current1RM > max1RM) {
            max1RM = current1RM;
          }
        }
      }
    }
    return max1RM;
  }
}