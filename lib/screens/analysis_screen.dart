import 'package:flutter/material.dart';
import '../main.dart'; // Global provider ve tema renkleri için
import '../providers/gym_tracker_provider.dart'; // Provider'a erişim için
import '../models/exercise.dart'; // Exercise modeline erişim için
import 'exercise_detail_chart_screen.dart'; // Grafik detay ekranına yönlendirme için

class AnalysisScreen extends StatelessWidget {
  final List<String> muscleGroups = [
    'Göğüs', 'Sırt', 'Bacak', 'Omuz', 'Biceps', 'Triceps', 'Core',
  ];

  // YENİ METOT: Belirli bir kas grubunun toplam hacmini hesaplar
  double _calculateTotalVolumeForGroup(String muscleGroup) {
    // Tüm antrenmanlardaki, bu kas grubuna ait egzersizleri filtrele
    final exercisesInGroup = gymTrackerProvider.workouts
        .expand((w) => w.exercises)
        .where((e) => e.muscleGroup == muscleGroup)
        .toList();

    // Bu egzersizlerin toplam hacmini topla
    return exercisesInGroup.fold(0.0, (sum, e) => sum + e.totalVolume);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gymTrackerProvider,
      builder: (context, child) {
        // Kaydedilmiş tüm egzersiz isimlerini çekiyoruz
        final recordedExercises = gymTrackerProvider.workouts
            .expand((w) => w.exercises)
            .map((we) => we.name)
            .toSet()
            .toList();

        if (recordedExercises.isEmpty) {
          // GÜNCELLEME: Boş Kayıtlar için daha iyi geri bildirim
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Analiz için yeterli antrenman verisi yok.',
                  style: TextStyle(color: taupeAccent, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {
                    // Kullanıcıyı Antrenman Ekle sekmesine yönlendir
                    // Bottom Nav Bar index 1'dir. MainAppScreen'de bu yönlendirme yapılmalıdır.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Çalışmaya Başla!', style: TextStyle(color: primaryDark)), backgroundColor: highlightColor,),
                    );
                  },
                  icon: Icon(Icons.add_box_outlined, color: highlightColor),
                  label: const Text('Antrenman Kaydı Ekle'),
                ),
              ],
            ),
          );
        }

        // Kaydedilen hareketlerin tanımlarını (isim ve kas grubu) al
        final List<Map<String, String>> recordedExerciseDefs = gymTrackerProvider.exerciseDefinitions
            .where((def) => recordedExercises.contains(def['name']))
            .toList();


        return DefaultTabController(
          length: muscleGroups.length,
          child: Column(
            children: [
              // TEMA UYUMU: TABBAR RENKLERİ
              TabBar(
                isScrollable: true,
                labelColor: highlightColor, // Seçili sekme rengi
                unselectedLabelColor: taupeAccent, // Seçili olmayan sekme rengi
                indicatorColor: highlightColor,
                tabs: muscleGroups.map((group) => Tab(text: group)).toList(),
              ),
              Expanded(
                child: TabBarView(
                  children: muscleGroups.map((group) {
                    final exercisesInGroup = recordedExerciseDefs
                        .where((e) => e['muscleGroup'] == group)
                        .toList();

                    final totalVolume = _calculateTotalVolumeForGroup(group);

                    if (exercisesInGroup.isEmpty) {
                      // GÜNCELLEME: Boş kas grubunda daha iyi geri bildirim
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$group kas grubunda kaydedilmiş hareket yok.', style: TextStyle(color: taupeAccent)),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                // Kullanıcıyı Hareket Yönetimi sekmesine yönlendir
                                // Bottom Nav Bar index 4'tür.
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lütfen önce bu kas grubuna hareket tanımı ekleyin.', style: TextStyle(color: primaryDark)), backgroundColor: highlightColor,),
                                );
                              },
                              icon: Icon(Icons.list_alt, color: highlightColor),
                              label: const Text('Hareket Yönetimine Git'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: exercisesInGroup.length + 1, // +1, özet kart için
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          // YENİ: Toplam Hacim Özeti Kartı
                          return _VolumeSummaryCard(
                            muscleGroup: group,
                            totalVolume: totalVolume,
                          );
                        }

                        final exerciseDef = exercisesInGroup[index - 1]; // Özet kartı atla
                        return _ExerciseAnalysisCard(exerciseName: exerciseDef['name']!, muscleGroup: exerciseDef['muscleGroup']!);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// YENİ WIDGET: Toplam Hacim Özeti Kartı
class _VolumeSummaryCard extends StatelessWidget {
  final String muscleGroup;
  final double totalVolume;

  const _VolumeSummaryCard({required this.muscleGroup, required this.totalVolume});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toplam Hacim (Tüm Zamanlar)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentLight),
            ),
            const Divider(color: taupeAccent),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.monitor_weight_outlined, color: highlightColor, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      '$muscleGroup Ganimeti:',
                      style: TextStyle(color: taupeAccent, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  '${(totalVolume / 1000).toStringAsFixed(1)} Ton', // Hacim ton cinsinden gösterildi
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: highlightColor),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseAnalysisCard extends StatelessWidget {
  final String exerciseName;
  final String muscleGroup;

  const _ExerciseAnalysisCard({required this.exerciseName, required this.muscleGroup});

  @override
  Widget build(BuildContext context) {
    // Tüm geçmişi al (tarih sırasına göre)
    final allRecords = gymTrackerProvider.workouts
        .expand((w) => w.exercises)
        .where((e) => e.name == exerciseName)
        .toList();

    if (allRecords.isEmpty) return const SizedBox.shrink();

    // En son iki kaydı al (Fonksiyonellik korunmuştur)
    final currentRecord = allRecords.last;
    final previousRecord = allRecords.length >= 2 ? allRecords[allRecords.length - 2] : null;

    final currentHeaviestSet = currentRecord.heaviestSet;
    final previousHeaviestSet = previousRecord?.heaviestSet;

    // YENİ: Maksimum 1RM'i hesapla
    final max1RM = gymTrackerProvider.getMaxOneRepMax(exerciseName);

    String comparisonText = 'İlk Kayıt';
    Color color = taupeAccent; // Varsayılan: Taupe

    if (previousHeaviestSet != null && currentHeaviestSet != null) {
      if (previousHeaviestSet.weight > 0) {
        final percentageChange = ((currentHeaviestSet.weight - previousHeaviestSet.weight) / previousHeaviestSet.weight) * 100;
        final sign = percentageChange >= 0 ? '+' : '';
        comparisonText = '$sign${percentageChange.toStringAsFixed(1)}%';

        // TEMA UYUMU: İlerleme Renkleri
        if (percentageChange > 0) {
          color = Colors.green.shade400; // İlerleme
        } else if (percentageChange < 0) {
          color = Colors.red.shade400; // Gerileme
        }
      } else {
        comparisonText = 'Önceki Kayıt Ağırlığı 0';
      }
    }

    // YENİ: 1RM GÖSTERİMİ
    Widget oneRmDisplay = Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Text(
            'Maks. Güç Skoru (1RM): ',
            style: TextStyle(color: accentLight, fontSize: 14),
          ),
          Text(
            '${max1RM.toStringAsFixed(1)} kg',
            style: TextStyle(fontWeight: FontWeight.bold, color: highlightColor, fontSize: 14),
          ),
        ],
      ),
    );


    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          exerciseName,
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: highlightColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Son En Ağır Set: ${currentHeaviestSet?.weight.toStringAsFixed(1) ?? '0'} kg x ${currentHeaviestSet?.reps ?? 0} tekrar',
              style: TextStyle(color: taupeAccent),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Önceki Kayda Göre Değişim:', style: TextStyle(color: taupeAccent)),
                const SizedBox(width: 8),
                Text(
                  comparisonText,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            // YENİ 1RM Ekranı
            if (max1RM > 0)
              oneRmDisplay,
          ],
        ),
        trailing: Icon(Icons.show_chart, color: highlightColor),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => ExerciseDetailChartScreen(exerciseName: exerciseName),
          ));
        },
      ),
    );
  }
}