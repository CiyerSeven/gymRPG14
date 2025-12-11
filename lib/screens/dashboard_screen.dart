import 'package:flutter/material.dart';
import '../providers/gym_tracker_provider.dart';
import '../models/muscle_group_progress.dart';
import '../models/workout.dart';
import '../main.dart'; // Global provider ve renk sabitleri için

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gymTrackerProvider,
      builder: (context, child) {
        final prog = gymTrackerProvider.progress.toList()
          ..sort((a, b) => b.level.compareTo(a.level) == 0
              ? b.xp.compareTo(a.xp)
              : b.level.compareTo(a.level));

        // Analizler için gerekli veriler
        final Map<String, int> weeklySetCount = {};
        int totalSets = 0;
        String mostWorkedGroup = 'N/A';
        DateTime? lastWorkoutDate;

        if (gymTrackerProvider.workouts.isNotEmpty) {
          final now = DateTime.now();
          // Haftanın başlangıcı (Pazartesi)
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

          for (var workout in gymTrackerProvider.workouts) {
            if (workout.date.isAfter(startOfWeek)) {
              totalSets += workout.totalSets;
              for (var group in workout.workedMuscleGroups) {
                weeklySetCount[group] = (weeklySetCount[group] ?? 0) + workout.totalSets;
              }
            }
          }

          if (weeklySetCount.isNotEmpty) {
            mostWorkedGroup = weeklySetCount.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
          }
          lastWorkoutDate = gymTrackerProvider.workouts.map((w) => w.date).reduce((a, b) => a.isAfter(b) ? a : b);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Özet Alanı
              _buildSummaryCard(mostWorkedGroup, totalSets, lastWorkoutDate),
              const SizedBox(height: 24),
              Text(
                'Kas Grubu Seviyeleri',
                style: Theme.of(context).textTheme.headlineSmall, // Tema rengi accentLight
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 1.2,
                ),
                itemCount: prog.length,
                itemBuilder: (context, index) {
                  return _MuscleGroupCard(progress: prog[index]);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String mostWorkedGroup, int totalSets, DateTime? lastWorkoutDate) {
    final String lastDateText = lastWorkoutDate != null
        ? '${lastWorkoutDate.day}.${lastWorkoutDate.month}.${lastWorkoutDate.year}'
        : 'Henüz antrenman yok';

    return Card(
      // CardColor ve Shape tema tarafından sağlanıyor
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Haftalık Özet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentLight),
            ),
            // Renk taupeAccent'ten highlightColor'a güncellendi
            const Divider(height: 20, color: highlightColor),
            _SummaryItem(
              icon: Icons.fitness_center,
              title: 'En Çok Çalışan Kas Grubu:',
              value: mostWorkedGroup,
            ),
            _SummaryItem(
              icon: Icons.format_list_numbered,
              title: 'Toplam Set Sayısı (Haftalık):',
              value: totalSets.toString(),
            ),
            _SummaryItem(
              icon: Icons.calendar_today,
              title: 'Son Antrenman Tarihi:',
              value: lastDateText,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _SummaryItem({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: highlightColor), // İkon rengi vurguya çekildi
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 14, color: accentLight.withOpacity(0.8)),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: accentLight),
          ),
        ],
      ),
    );
  }
}

class _MuscleGroupCard extends StatelessWidget {
  final MuscleGroupProgress progress;

  const _MuscleGroupCard({required this.progress});

  // YENİ METOT: Kas grubunun toplam hacmini hesaplar (Analiz ekranındaki mantık)
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
    final requiredXp = gymTrackerProvider.getRequiredXpForNextLevel(progress.level);
    final currentXp = progress.xp.toInt();
    final progressRatio = (progress.xp / requiredXp).clamp(0.0, 1.0);

    // YENİ: Toplam hacmi hesapla
    final totalVolume = _calculateTotalVolumeForGroup(progress.muscleGroup);
    // RPG temasına uygun olarak Ton cinsinden gösterim
    final totalVolumeInTons = (totalVolume / 1000).toStringAsFixed(1);


    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          // Gradient renkleri temaya uygun ayarlandı
          gradient: LinearGradient(
            colors: [surfaceDark, primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // BAŞLIK VE LEVEL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  progress.muscleGroup,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentLight), // Krem metin
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: highlightColor, // Arka plan yeni vurgu rengi
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Lv. ${progress.level}',
                    style: const TextStyle(color: primaryDark, fontWeight: FontWeight.bold, fontSize: 14), // Koyu metin
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // YENİ: TOPLAM HACİM BİLGİSİ
            Text(
              'Ganimet: $totalVolumeInTons Ton',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: highlightColor),
            ),
            const SizedBox(height: 10),


            // XP GÖSTERİMİ
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$currentXp / $requiredXp XP',
                  style: TextStyle(fontSize: 12, color: taupeAccent), // Taupe metin
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: progressRatio,
                    backgroundColor: surfaceDark, // Koyu kart rengi
                    valueColor: const AlwaysStoppedAnimation<Color>(accentLight), // Progress bar: Krem
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}