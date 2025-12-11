import 'package:flutter/material.dart';
import '../main.dart'; // Tema renkleri için
import '../providers/gym_tracker_provider.dart';
import 'personal_data_screen.dart'; // YENİ EKRAN İMPORTU

class ProfileScreen extends StatelessWidget {

  // YENİ METOT: Kişisel Veri ekranına yönlendirme
  void _navigateToPersonalData(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PersonalDataScreen(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gymTrackerProvider,
      builder: (context, child) {
        final overallLevel = gymTrackerProvider.overallLevel;
        final totalWorkouts = gymTrackerProvider.workouts.length;
        final totalExercises = gymTrackerProvider.workouts.fold(0, (sum, w) => sum + w.exercises.length);

        // Tema renklerini al
        final highlightColor = Theme.of(context).primaryColor;
        final taupeAccent = Theme.of(context).colorScheme.secondary;
        final primaryDark = Theme.of(context).colorScheme.background;
        final accentLight = Theme.of(context).colorScheme.onSurface;
        final surfaceDark = Theme.of(context).colorScheme.surface;


        return Scaffold(
          appBar: AppBar(
            title: const Text('Profil & Ayarlar'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar Alanı (RPG Savaşçı Simgesi)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: highlightColor, width: 3),
                    color: surfaceDark,
                  ),
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: primaryDark,
                    child: Icon(Icons.shield_outlined, size: 45, color: highlightColor), // Kalkan (Savaşçı Simgesi)
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hoş Geldin Maceracı!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  'Bu Uygulama Level $overallLevel Maceracıya Aittir',
                  style: TextStyle(color: taupeAccent),
                ),
                const SizedBox(height: 16),

                _buildXpBar(context, _calculateOverallProgressRatio(), overallLevel, _calculateNextLevelXpRequired()),
                const SizedBox(height: 32),


                // İstatistikler Kartı (Başarı Metrikleri)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          value: totalWorkouts.toString(),
                          label: 'Toplam Antrenman',
                          color: highlightColor,
                          icon: Icons.calendar_today,
                        ),
                        _StatItem(
                          value: totalExercises.toString(),
                          label: 'Toplam Hareket Kaydı',
                          color: highlightColor,
                          icon: Icons.fitness_center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Genel Ayarlar Başlığı
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                      'Uygulama Ayarları',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentLight)
                  ),
                ),
                const SizedBox(height: 12),

                // YENİ: KİŞİSEL BİLGİLER BUTONU
                _SettingsTile(
                  title: 'Kilo & Boy Takibi',
                  subtitle: 'Kilo geçmişini gör ve BMI hesapla.',
                  icon: Icons.monitor_weight_outlined,
                  onTap: () => _navigateToPersonalData(context),
                ),


                // Genel Ayarlar
                _SettingsTile(
                    title: 'Tema Rengi Seçimi',
                    // Alt başlık varsayılana döndü
                    subtitle: 'Şu an sadece varsayılan tema mevcut.',
                    icon: Icons.color_lens_outlined,
                    // Dialog çağrısı yerine basit SnackBar
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Şu an sadece varsayılan tema mevcut.', style: TextStyle(color: primaryDark)), backgroundColor: highlightColor,),
                      );
                    }
                ),
                _SettingsTile(
                  title: 'Verileri Sıfırla',
                  subtitle: 'Tüm antrenman geçmişini ve XP’yi siler.',
                  icon: Icons.delete_forever,
                  iconColor: Colors.red.shade400,
                  onTap: () => _confirmReset(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Gerekli _calculateOverallProgressRatio metotları (Aynı kalır)
  double _calculateOverallProgressRatio() {
    double totalProgressRatio = 0.0;
    int groupCount = gymTrackerProvider.progress.length;
    if (groupCount == 0) return 0.0;
    for (var prog in gymTrackerProvider.progress) {
      final requiredXp = gymTrackerProvider.getRequiredXpForNextLevel(prog.level);
      if (requiredXp > 0) {
        totalProgressRatio += (prog.xp / requiredXp).clamp(0.0, 1.0);
      }
    }
    return totalProgressRatio / groupCount;
  }

  int _calculateNextLevelXpRequired() {
    if (gymTrackerProvider.progress.isEmpty) return 1000;
    return gymTrackerProvider.progress.length * 1000;
  }

  Widget _buildXpBar(BuildContext context, double ratio, int level, int requiredXp) {
    final currentLevelXp = (requiredXp * ratio).toInt();
    final primaryDark = Theme.of(context).colorScheme.background;
    final highlightColor = Theme.of(context).primaryColor;
    final taupeAccent = Theme.of(context).colorScheme.secondary;
    final accentLight = Theme.of(context).colorScheme.onSurface;
    final surfaceDark = Theme.of(context).colorScheme.surface;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: taupeAccent.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Genel Level İlerlemesi',
                style: TextStyle(color: accentLight, fontWeight: FontWeight.bold),
              ),
              Text(
                'Lv. ${level} -> Lv. ${level + 1}',
                style: TextStyle(color: highlightColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: primaryDark,
              valueColor: AlwaysStoppedAnimation<Color>(highlightColor),
              minHeight: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'XP Kazanımı: ${currentLevelXp} / ${requiredXp} XP',
            textAlign: TextAlign.center,
            style: TextStyle(color: taupeAccent, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    final accentLight = Theme.of(context).colorScheme.onSurface;
    final highlightColor = Theme.of(context).primaryColor;
    final primaryDark = Theme.of(context).colorScheme.background;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Tüm Verileri Sıfırla"),
          content: Text("BU İŞLEM GERİ ALINAMAZ. Tüm antrenman geçmişini, seviyeleri ve XP'yi silmek istediğinizden emin misiniz?", style: TextStyle(color: accentLight)),
          actions: <Widget>[
            TextButton(
              child: const Text("İptal"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
              child: const Text("Sıfırla", style: TextStyle(color: Colors.white)),
              onPressed: () async {
                Navigator.of(context).pop();
                gymTrackerProvider.workouts.clear();
                gymTrackerProvider.progress.clear();
                gymTrackerProvider.notifyListeners();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tüm veriler sıfırlandı. Uygulamayı yeniden başlatın.', style: TextStyle(color: primaryDark)), backgroundColor: highlightColor,),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatItem({required this.value, required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontSize: 14)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;

  const _SettingsTile({required this.title, required this.subtitle, required this.icon, required this.onTap, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final highlightColor = Theme.of(context).primaryColor;
    final taupeAccent = Theme.of(context).colorScheme.secondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? highlightColor, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: taupeAccent)),
        trailing: Icon(Icons.arrow_forward_ios, color: taupeAccent, size: 16),
        onTap: onTap,
      ),
    );
  }
}