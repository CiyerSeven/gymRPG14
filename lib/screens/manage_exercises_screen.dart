import 'package:flutter/material.dart';
import '../main.dart'; // Global provider ve tema renkleri için

class ManageExercisesScreen extends StatefulWidget {
  @override
  State<ManageExercisesScreen> createState() => _ManageExercisesScreenState();
}

class _ManageExercisesScreenState extends State<ManageExercisesScreen> {
  final List<String> muscleGroups = [
    'Göğüs', 'Sırt', 'Bacak', 'Omuz', 'Biceps', 'Triceps', 'Core',
  ];

  // Hareket tanımlarını kas gruplarına göre gruplar
  Map<String, List<Map<String, String>>> _groupDefinitions(List<Map<String, String>> definitions) {
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

  void _showAddDefinitionDialog(BuildContext context) {
    String newExerciseName = '';
    String? selectedMuscleGroup;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Yeni Hareket Tanımla"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Hareket Adı'),
                onChanged: (value) => newExerciseName = value.trim(),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: selectedMuscleGroup,
                hint: const Text('Kas Grubu Seçin'),
                decoration: const InputDecoration(),
                dropdownColor: surfaceDark,
                style: const TextStyle(color: accentLight),
                items: muscleGroups.map((group) {
                  return DropdownMenuItem(value: group, child: Text(group));
                }).toList(),
                onChanged: (String? newValue) {
                  selectedMuscleGroup = newValue;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("İptal"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newExerciseName.isNotEmpty && selectedMuscleGroup != null) {
                  await gymTrackerProvider.addExerciseDefinition(newExerciseName, selectedMuscleGroup!);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("'$newExerciseName' başarıyla eklendi.", style: TextStyle(color: primaryDark)), backgroundColor: highlightColor),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lütfen tüm alanları doldurun.", style: TextStyle(color: primaryDark)), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text("Tanımla"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gymTrackerProvider,
      builder: (context, child) {
        final definitions = gymTrackerProvider.exerciseDefinitions;
        final groupedDefs = _groupDefinitions(definitions);

        return Scaffold(
          body: definitions.isEmpty
              ? Center(
            child: Text(
              'Henüz tanımlanmış hareket yok.',
              style: TextStyle(color: taupeAccent, fontSize: 16),
            ),
          )
              : ListView(
            padding: const EdgeInsets.all(16.0),
            children: muscleGroups.map((group) {
              final exercises = groupedDefs[group]!;
              if (exercises.isEmpty) {
                return const SizedBox.shrink(); // Boş grupları gösterme
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Card(
                  elevation: 2,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: false,
                      iconColor: highlightColor,
                      collapsedIconColor: taupeAccent,
                      title: Text(
                        '$group (${exercises.length} Hareket)',
                        style: TextStyle(fontWeight: FontWeight.bold, color: highlightColor),
                      ),
                      children: exercises.map((def) {
                        final name = def['name']!;
                        return _ExerciseDefinitionTile(
                          name: name,
                          group: group,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddDefinitionDialog(context),
            label: const Text('Yeni Hareket Ekle'),
            icon: const Icon(Icons.add),
            backgroundColor: highlightColor,
            foregroundColor: primaryDark,
          ),
        );
      },
    );
  }
}

class _ExerciseDefinitionTile extends StatelessWidget {
  final String name;
  final String group;

  const _ExerciseDefinitionTile({required this.name, required this.group});

  void _confirmDelete(BuildContext context, String exerciseName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Hareket Tanımını Sil"),
          content: Text(
              "'$exerciseName' hareketini tanımlı listeden silmek istediğinizden emin misiniz? Bu hareket, mevcut antrenman kayıtlarından SİLİNMEZ, ancak yeni kayıt eklerken görünmez.",
              style: TextStyle(color: accentLight)
          ),
          actions: <Widget>[
            TextButton(
              child: const Text("İptal"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              child: const Text("Sil", style: TextStyle(color: accentLight)),
              onPressed: () async {
                Navigator.of(context).pop();
                await gymTrackerProvider.deleteExerciseDefinition(exerciseName);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("'$exerciseName' tanımı silindi.", style: TextStyle(color: primaryDark)),
                    backgroundColor: highlightColor,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Icon(Icons.line_weight, color: taupeAccent),
      title: Text(
          name,
          style: TextStyle(fontWeight: FontWeight.w500, color: accentLight)
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
        onPressed: () => _confirmDelete(context, name),
      ),
    );
  }
}