import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarih formatlama için
import '../models/workout.dart';
import '../models/exercise.dart';
import '../main.dart'; // Global provider ve tema renkleri için

// Aylık gruplama yapıldıktan sonra kullanılacak WorkoutDetailScreen (HistoryScreen'in devamı)
class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailScreen({required this.workout});

  // Önceki kayda göre hacim değişimini hesaplar (Fonksiyonellik korunmuştur)
  String _getComparisonText(Exercise currentExercise) {
    final previousExercise = gymTrackerProvider.getPreviousExerciseData(currentExercise.name);

    if (previousExercise == null || previousExercise.sets.isEmpty) {
      return ' (İlk Kayıt)';
    }

    final currentVolume = currentExercise.totalVolume;
    final previousVolume = previousExercise.totalVolume;

    if (previousVolume == 0) return ' (Önceki Hacim 0)';

    final percentageChange = ((currentVolume - previousVolume) / previousVolume) * 100;

    final String sign = percentageChange >= 0 ? '+' : '';
    final String text = '$sign${percentageChange.toStringAsFixed(1)}% Hacim Değişimi';

    return ' ($text)';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${workout.date.day}.${workout.date.month}.${workout.date.year} Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            color: Colors.red.shade400, // Silme için belirgin kırmızı tonu
            onPressed: () => _confirmDelete(context, workout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Genel Bilgiler', style: Theme.of(context).textTheme.headlineSmall),
            const Divider(color: taupeAccent),
            _DetailItem(title: 'Toplam Set', value: workout.totalSets.toString()),
            _DetailItem(title: 'Çalışılan Kaslar', value: workout.workedMuscleGroups.join(', ')),
            if (workout.notes != null && workout.notes!.isNotEmpty)
              _DetailItem(title: 'Notlar', value: workout.notes!),
            const SizedBox(height: 24),
            Text('Hareketler ve Setler', style: Theme.of(context).textTheme.headlineSmall),
            const Divider(color: taupeAccent),
            ...workout.exercises.map((exercise) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: highlightColor),
                        ),
                        Text(
                          'Kas Grubu: ${exercise.muscleGroup}',
                          style: TextStyle(fontSize: 14, color: taupeAccent),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Özet Karşılaştırma: ${_getComparisonText(exercise)}',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: taupeAccent.withOpacity(0.8)),
                        ),
                        const Divider(height: 16, color: primaryDark),
                        ...exercise.sets.asMap().entries.map((setEntry) {
                          final set = setEntry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Text('Set ${setEntry.key + 1}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: accentLight)),
                                Text('${set.weight} kg x ${set.reps} tekrar', style: const TextStyle(color: accentLight)),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Workout workout) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Antrenmanı Sil"),
          content: Text("Bu antrenmanı kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.", style: TextStyle(color: accentLight)),
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
                await gymTrackerProvider.deleteWorkout(workout.id);

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Antrenman kaydı silindi.', style: TextStyle(color: primaryDark)), backgroundColor: highlightColor,),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String title;
  final String value;

  const _DetailItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold, color: highlightColor),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(color: accentLight))),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// ANA GEÇMİŞ EKRANI (AYLIK GRUPLAMA İLE)
// ----------------------------------------------------

class HistoryScreen extends StatelessWidget {
  // Antrenman listesini ay-yıl formatına göre gruplandırır
  Map<String, List<Workout>> _groupWorkoutsByMonth(List<Workout> workouts) {
    final Map<String, List<Workout>> grouped = {};

    // En yeni en üstte olması için ters sırala
    final sortedWorkouts = workouts.toList()..sort((a, b) => b.date.compareTo(a.date));

    for (var workout in sortedWorkouts) {
      // Örn: "Aralık 2025"
      final monthKey = DateFormat('MMMM yyyy', 'tr_TR').format(workout.date);

      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(workout);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    // Intln'i doğru kullanmak için yerel ayarı ayarlayın (Türkçe)
    Intl.defaultLocale = 'tr_TR';

    return ListenableBuilder(
      listenable: gymTrackerProvider,
      builder: (context, child) {
        if (gymTrackerProvider.workouts.isEmpty) {
          return Center(
            child: Text(
              'Henüz antrenman geçmişi yok.',
              style: TextStyle(color: taupeAccent, fontSize: 16),
            ),
          );
        }

        final groupedWorkouts = _groupWorkoutsByMonth(gymTrackerProvider.workouts);
        final monthKeys = groupedWorkouts.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: monthKeys.length,
          itemBuilder: (context, index) {
            final month = monthKeys[index];
            final workoutsInMonth = groupedWorkouts[month]!;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              // Ayları genişletilebilir bir kart içinde gösteriyoruz
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: surfaceDark, // Tema kart rengi
                child: Theme(
                  // ExpansionTile'ın varsayılan mavi vurgu rengini değiştirmek için Theme kullanıyoruz
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: index == 0, // En son ayı otomatik aç
                    iconColor: highlightColor,
                    collapsedIconColor: taupeAccent,
                    title: Text(
                      month,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: highlightColor,
                      ),
                    ),
                    children: workoutsInMonth.map((workout) {
                      return ListTile(
                        // Her bir antrenman kaydı
                        leading: Icon(Icons.date_range, color: taupeAccent, size: 20),
                        title: Text(
                          '${DateFormat('dd MMMM', 'tr_TR').format(workout.date)}',
                          style: TextStyle(fontWeight: FontWeight.w500, color: accentLight),
                        ),
                        subtitle: Text(
                          '${workout.totalSets} Set. Kaslar: ${workout.workedMuscleGroups.join(', ')}',
                          style: TextStyle(color: taupeAccent.withOpacity(0.8), fontSize: 12),
                        ),
                        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: taupeAccent),
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => WorkoutDetailScreen(workout: workout),
                          ));
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// NOT: Bu dosyanın çalışması için 'intl' paketini pubspec.yaml'a eklemeniz gerekir.
// intl: ^0.18.0