import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/workout.dart';
import '../models/exercise.dart';
import '../models/set_entry.dart';
import '../main.dart'; // Global provider ve renkler
import 'package:intl/intl.dart'; // Gün ismini bulmak için

const uuid = Uuid();

// Dosya adı korundu, ancak içeriği form işlevi görecek şekilde güncellendi.
class AddWorkoutScreen extends StatefulWidget {
  final Workout? workoutToEdit; // Düzenleme modunda null değil

  const AddWorkoutScreen({super.key, this.workoutToEdit});

  @override
  _AddWorkoutScreenState createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  late DateTime selectedDate;
  late List<Exercise> currentExercises;
  late TextEditingController _noteController;
  late bool isEditing;

  @override
  void initState() {
    super.initState();
    isEditing = widget.workoutToEdit != null;

    if (isEditing) {
      // Düzenleme modu: Mevcut verileri yükle
      selectedDate = widget.workoutToEdit!.date;
      // Derin kopyalama (Setler dahil)
      currentExercises = List.from(widget.workoutToEdit!.exercises.map((e) => Exercise(
        id: e.id,
        name: e.name,
        muscleGroup: e.muscleGroup,
        sets: List.from(e.sets.map((s) => SetEntry(weight: s.weight, reps: s.reps))),
      )));
      _noteController = TextEditingController(text: widget.workoutToEdit!.notes ?? '');
    } else {
      // Ekleme modu: Varsayılan değerler
      selectedDate = DateTime.now();
      currentExercises = [];
      _noteController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: highlightColor,
              onPrimary: primaryDark,
              surface: surfaceDark,
              onSurface: accentLight,
            ),
            dialogBackgroundColor: surfaceDark,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // YENİ METOT: Günün programını yükler
  void _loadDailyProgram() {
    // Bugünün adını Türkçe olarak bul (Örn: Pazartesi)
    Intl.defaultLocale = 'tr_TR';
    final todayName = DateFormat('EEEE', 'tr_TR').format(selectedDate); // TR lokali belirtildi

    final program = gymTrackerProvider.weeklyProgram;
    final programExercises = program[todayName] ?? [];

    if (programExercises.isEmpty) {
      _showMessage('$todayName için tanımlanmış bir program bulunamadı.');
      return;
    }

    // Var olan hareketleri temizle
    currentExercises.clear();

    // Programdaki her hareket için varsayılan setleri oluştur ve ekle
    for (final exerciseName in programExercises) {

      // Hata koruması: Tanım yoksa 'Bilinmeyen' kas grubu ile devam et.
      final exerciseDef = gymTrackerProvider.exerciseDefinitions.firstWhere(
            (def) => def['name'] == exerciseName,
        orElse: () => {'name': exerciseName, 'muscleGroup': 'Bilinmeyen'},
      );

      final muscleGroup = exerciseDef['muscleGroup'] ?? 'Bilinmeyen';


      final newExercise = Exercise(
        id: uuid.v4(),
        name: exerciseName,
        muscleGroup: muscleGroup,
        // Varsayılan olarak 3 boş set ekle
        sets: [
          SetEntry(weight: 0, reps: 0),
          SetEntry(weight: 0, reps: 0),
          SetEntry(weight: 0, reps: 0),
        ],
      );
      currentExercises.add(newExercise);
    }

    setState(() {
      _showMessage('$todayName programı başarıyla yüklendi!');
    });
  }


  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: Theme.of(context).copyWith(dialogBackgroundColor: surfaceDark),
          // AddExerciseDialog sadece var olanlardan seçim yapacak şekilde basitleştirildi
          child: AddExerciseDialog(
            onAdd: (String name, String muscleGroup) {
              setState(() {
                // Ekleme veya Düzenleme için yeni bir hareket ekle
                currentExercises.add(Exercise(id: uuid.v4(), name: name, muscleGroup: muscleGroup, sets: []));
              });
              Navigator.of(context).pop();
            },
          ),
        );
      },
    );
  }

  void _addSetToExercise(Exercise exercise) {
    setState(() {
      final lastSet = exercise.sets.isNotEmpty ? exercise.sets.last : SetEntry(weight: 0, reps: 0);
      exercise.sets.add(SetEntry(weight: lastSet.weight, reps: lastSet.reps));
    });
  }

  void _submitForm() async {
    if (currentExercises.isEmpty || currentExercises.every((e) => e.sets.isEmpty)) {
      _showMessage('Lütfen en az bir set giriniz.');
      return;
    }

    if (isEditing) {
      // DÜZENLEME İŞLEMİ
      final updatedWorkout = Workout(
        id: widget.workoutToEdit!.id,
        date: selectedDate,
        exercises: currentExercises,
        notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );
      await gymTrackerProvider.updateWorkout(updatedWorkout);

      _showMessage('Antrenman başarıyla GÜNCELLENDİ ve XP yeniden hesaplandı.');
      Navigator.of(context).pop(); // Geçmiş ekranına geri dön

    } else {
      // YENİ EKLEME İŞLEMİ
      await gymTrackerProvider.addWorkout(
        selectedDate,
        currentExercises,
        _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      // Eklemeden sonra formu sıfırla
      setState(() {
        currentExercises = [];
        selectedDate = DateTime.now();
        _noteController.clear();
      });

      _showMessage('Antrenman başarıyla kaydedildi!');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(message, style: TextStyle(color: primaryDark)),
          backgroundColor: highlightColor,
          duration: const Duration(seconds: 3)
      ),
    );
  }

  void _updateSet(SetEntry set, String field, String value) {
    setState(() {
      if (field == 'weight') {
        set.weight = double.tryParse(value) ?? 0.0;
      } else if (field == 'reps') {
        set.reps = int.tryParse(value) ?? 0;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gymTrackerProvider,
      builder: (context, child) {
        // Düzenleme modunda App Bar başlığını değiştir
        final screenContent = SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Tarih Seçici
              _buildDateSelector(),
              const SizedBox(height: 16),

              // SADECE EKLEME MODUNDA GÖSTER: Programı Yükle Butonu
              if (!isEditing)
                _buildLoadProgramButton(),
              if (!isEditing)
                const SizedBox(height: 16),

              // Hareket Kartları
              ...currentExercises.map((exercise) => _buildExerciseCard(exercise)).toList(),
              const SizedBox(height: 16),

              // Yeni Hareket Ekleme Butonu
              OutlinedButton.icon(
                onPressed: _showAddExerciseDialog,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Yeni Hareket Ekle'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // Not Alanı
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Notlar (RPE, Duygular vb.)',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // Kaydet / Güncelle Butonu
              ElevatedButton(
                onPressed: _submitForm,
                child: Text(isEditing ? 'Antrenmanı Güncelle' : 'Antrenmanı Kaydet', style: const TextStyle(fontSize: 18)),
              ),
            ],
          ),
        );

        if (isEditing) {
          // Düzenleme modunda Scaffold'u App Bar ile döndür
          return Scaffold(
            appBar: AppBar(title: const Text('Antrenmanı Düzenle')),
            body: screenContent,
          );
        } else {
          // Ekleme modunda sadece içeriği döndür (Ana sekme olduğu için App Bar'ı MainAppScreen sağlar)
          return screenContent;
        }
      },
    );
  }

  Widget _buildLoadProgramButton() {
    return ElevatedButton.icon(
      onPressed: _loadDailyProgram,
      icon: const Icon(Icons.download_for_offline),
      label: Text(
        'Günün Programını Yükle (${DateFormat('EEEE', 'tr_TR').format(selectedDate)})',
        style: const TextStyle(fontSize: 16),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: taupeAccent,
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }


  Widget _buildDateSelector() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: highlightColor),
        title: Text(
          'Tarih: ${selectedDate.day}.${selectedDate.month}.${selectedDate.year}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        trailing: Icon(Icons.edit, color: taupeAccent),
        onTap: () => _selectDate(context),
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${exercise.name} (${exercise.muscleGroup})',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: highlightColor),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: taupeAccent),
                  onPressed: () {
                    setState(() {
                      currentExercises.remove(exercise);
                    }
                    );
                  },
                ),
              ],
            ),
            const Divider(color: taupeAccent),
            // Set Listesi
            ...exercise.sets.asMap().entries.map((entry) {
              int index = entry.key;
              SetEntry set = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Text('Set ${index + 1}:', style: const TextStyle(fontWeight: FontWeight.bold, color: accentLight)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: set.weight == 0 ? '' : set.weight.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Ağırlık (kg)', isDense: true),
                        onChanged: (val) => _updateSet(set, 'weight', val),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        initialValue: set.reps == 0 ? '' : set.reps.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tekrar', isDense: true),
                        onChanged: (val) => _updateSet(set, 'reps', val),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: taupeAccent),
                      onPressed: () {
                        setState(() {
                          exercise.sets.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              );
            }).toList(),

            // Set Ekleme Butonu
            TextButton.icon(
              onPressed: () => _addSetToExercise(exercise),
              icon: Icon(Icons.add, color: highlightColor),
              label: const Text('Set Ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

// Yeni Hareket Ekleme / Seçme Dialog
class AddExerciseDialog extends StatefulWidget {
  final Function(String name, String muscleGroup) onAdd;

  const AddExerciseDialog({required this.onAdd});

  @override
  _AddExerciseDialogState createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<AddExerciseDialog> {
  String? selectedExerciseName;
  String? selectedMuscleGroup;

  final List<String> muscleGroups = [
    'Göğüs', 'Sırt', 'Bacak', 'Omuz', 'Biceps', 'Triceps', 'Core',
  ];

  // Tanımları Kas Gruplarına göre gruplar
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

  // Dropdown için gruplandırılmış öğe listesini oluşturur
  List<DropdownMenuItem<String>> _buildGroupedDropdownItems(Map<String, List<Map<String, String>>> groupedDefinitions) {
    List<DropdownMenuItem<String>> items = [];

    for (var entry in groupedDefinitions.entries) {
      final groupName = entry.key;
      final exercises = entry.value;

      if (exercises.isNotEmpty) {
        // 1. Kategori Başlığı (Disabled)
        items.add(
          DropdownMenuItem<String>(
            value: null,
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
    final provider = gymTrackerProvider;
    final groupedDefinitions = _groupDefinitionsByMuscleGroup(provider.exerciseDefinitions);
    final groupedDropdownItems = _buildGroupedDropdownItems(groupedDefinitions);

    return AlertDialog(
      title: const Text('Hareket Seç'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Var Olandan Seçim (Artık Gruplandırılmış)
            DropdownButtonFormField<String>(
              value: selectedExerciseName,
              // KULLANICI DOSTU MESAJ: Tanım eksikse yönlendir
              hint: groupedDropdownItems.isEmpty
                  ? Text("Hareket Tanımı Yok. Lütfen Hareketler sekmesinde ekleyin.")
                  : const Text('Hareket Seçin (Kas Grubuna Göre)'),
              decoration: const InputDecoration(isDense: true),
              dropdownColor: surfaceDark,
              isExpanded: true,
              items: groupedDropdownItems,
              onChanged: groupedDropdownItems.isEmpty ? null : (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedExerciseName = newValue;
                    // Seçilen hareketin kas grubunu bul
                    selectedMuscleGroup = provider.exerciseDefinitions.firstWhere((d) => d['name'] == newValue)['muscleGroup'];
                  });
                }
              },
            ),

            // Yeni Tanımlama Alanları KALDIRILDI

          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('İptal'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          onPressed: selectedExerciseName != null ? () {
            String name = selectedExerciseName!;
            // Kas grubu mutlaka bulunmalıdır, çünkü bu listeden seçildi.
            String group = provider.exerciseDefinitions.firstWhere((d) => d['name'] == name)['muscleGroup']!;

            if (name.isNotEmpty && group.isNotEmpty) {
              widget.onAdd(name, group);
            }
          } : null, // Seçim yapılmadıysa buton pasif
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}