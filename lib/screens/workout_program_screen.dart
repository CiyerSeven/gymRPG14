import 'package:flutter/material.dart';
import '../main.dart';
import '../providers/gym_tracker_provider.dart';

// Simülasyon: Haftalık program verilerini tutan Map yapısı
// (Normalde bu veri Hive'dan gelir)
// Map<DayName, List<ExerciseName>>
typedef WeeklyProgram = Map<String, List<String>>;

class WorkoutProgramScreen extends StatefulWidget {
  const WorkoutProgramScreen({super.key});

  @override
  State<WorkoutProgramScreen> createState() => _WorkoutProgramScreenState();
}

class _WorkoutProgramScreenState extends State<WorkoutProgramScreen> {
  final List<String> daysOfWeek = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  // Kas grubu listesi, gruplandırma için gereklidir
  final List<String> muscleGroups = [
    'Göğüs', 'Sırt', 'Bacak', 'Omuz', 'Biceps', 'Triceps', 'Core',
  ];


  // YENİ METOT: Tanımları Kas Gruplarına göre gruplar (AddWorkoutScreen'den kopyalandı)
  Map<String, List<Map<String, String>>> _groupDefinitionsByMuscleGroup(List<Map<String, String>> definitions) {
    final Map<String, List<Map<String, String>>> grouped = {};
    for (var group in muscleGroups) {
      grouped[group] = [];
    }
    for (var def in definitions) {
      if (grouped.containsKey(def['muscleGroup'])) {
        grouped[def['muscleGroup']]!.add(def);
      }
    }
    return grouped;
  }

  // YENİ METOT: Dropdown için gruplandırılmış öğe listesini oluşturur (AddWorkoutScreen'den kopyalandı)
  List<DropdownMenuItem<String>> _buildGroupedDropdownItems(Map<String, List<Map<String, String>>> groupedDefinitions) {
    List<DropdownMenuItem<String>> items = [];

    for (var entry in groupedDefinitions.entries) {
      final groupName = entry.key;
      final exercises = entry.value;

      if (exercises.isNotEmpty) {
        // 1. Kategori Başlığı (Disabled)
        items.add(
          DropdownMenuItem<String>(
            value: null, // Seçilemez
            enabled: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                '--- $groupName ---',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: highlightColor,
                    fontSize: 16
                ),
              ),
            ),
          ),
        );

        // 2. Hareketler
        for (var exercise in exercises) {
          items.add(
            DropdownMenuItem<String>(
              value: exercise['name'],
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  exercise['name']!,
                  style: const TextStyle(color: accentLight),
                ),
              ),
            ),
          );
        }
      }
    }
    return items;
  }


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gymTrackerProvider,
      builder: (context, child) {
        final currentProgram = gymTrackerProvider.weeklyProgram;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Haftalık Antrenman Programı'),
          ),
          body: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: daysOfWeek.length,
            itemBuilder: (context, index) {
              final day = daysOfWeek[index];
              final exercisesForDay = currentProgram[day] ?? [];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Card(
                  elevation: 2,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: highlightColor,
                      collapsedIconColor: taupeAccent,
                      title: Text(
                        day,
                        style: TextStyle(fontWeight: FontWeight.bold, color: accentLight),
                      ),
                      children: [
                        // O güne ait hareketlerin listesi
                        ...exercisesForDay.map((exerciseName) {
                          return _ProgramExerciseTile(
                            day: day,
                            exerciseName: exerciseName,
                          );
                        }).toList(),

                        // Hareket Ekleme Butonu
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddExerciseDialog(context, day),
                            icon: Icon(Icons.add, color: highlightColor),
                            label: const Text('Hareket Ekle'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Hareket Ekleme Dialogu
  void _showAddExerciseDialog(BuildContext context, String day) {
    String? selectedExerciseName;
    final definitions = gymTrackerProvider.exerciseDefinitions;

    // Gruplandırılmış Dropdown öğelerini hazırla
    final groupedDefinitions = _groupDefinitionsByMuscleGroup(definitions);
    final groupedDropdownItems = _buildGroupedDropdownItems(groupedDefinitions);


    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$day Programına Hareket Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // GRUPLANDIRILMIŞ DROPDOWN
                DropdownButtonFormField<String>(
                  value: selectedExerciseName,
                  hint: const Text('Hareket Seçin (Kas Grubuna Göre)'),
                  decoration: const InputDecoration(isDense: true),
                  dropdownColor: surfaceDark,
                  isExpanded: true,
                  items: groupedDropdownItems,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      selectedExerciseName = newValue;
                      // State'i dialog içinde güncellemeye gerek yok, sadece değişkende tut
                    }
                  },
                ),
                // NOT: Yeni Hareket Tanımla kısmı bu ekranda gerekli değildir,
                // sadece AddWorkoutScreen'de hareket tanımı eklenebilmelidir.
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedExerciseName != null) {
                  // Ekleme işlemini Provider'a gönder
                  gymTrackerProvider.addExerciseToProgram(day, selectedExerciseName!);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );
  }
}

// Programdaki tek bir hareket satırı
class _ProgramExerciseTile extends StatelessWidget {
  final String day;
  final String exerciseName;

  const _ProgramExerciseTile({required this.day, required this.exerciseName});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.fitness_center, color: taupeAccent),
      title: Text(exerciseName, style: const TextStyle(color: accentLight)),
      trailing: IconButton(
        icon: Icon(Icons.delete, color: Colors.red.shade400),
        onPressed: () {
          // Silme işlemini Provider üzerinden yap
          gymTrackerProvider.removeExerciseFromProgram(day, exerciseName);
        },
      ),
    );
  }
}