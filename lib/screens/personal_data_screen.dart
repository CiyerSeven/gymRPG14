import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // Global renk sabitleri için
import '../models/weight_entry.dart';
import '../providers/gym_tracker_provider.dart';

class PersonalDataScreen extends StatefulWidget {
  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  // Kontrolcüler, state'ten ayrılmış olarak veri girişini yönetir
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // initState'te Controller'ları başlangıç verileriyle doldururuz.
    _initializeControllers();
    // Provider her güncellendiğinde controller'ları da güncel tutmak için listener ekleriz.
    gymTrackerProvider.addListener(_initializeControllers);
  }

  void _initializeControllers() {
    // Bu metod, ListenableBuilder'ın dışında, initState'te ve notifyListeners() çağrıldıktan sonra çalışır.
    final provider = gymTrackerProvider;

    // Boyu cm cinsinden göster
    _heightController.text = (provider.userHeight * 100).toStringAsFixed(0);

    // Kilo girişini en son kilo ile doldur
    if (provider.weightHistory.isNotEmpty) {
      _weightController.text = provider.weightHistory.last.weight.toStringAsFixed(1);
    } else {
      _weightController.text = ''; // Kayıt yoksa boş bırak
    }
  }

  @override
  void dispose() {
    // Listener'ı temizle
    gymTrackerProvider.removeListener(_initializeControllers);
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Veriler artık ListenableBuilder'dan alınacak.
  String _calculateBMI(double height, List<WeightEntry> history) {
    if (height <= 0 || history.isEmpty) {
      return 'N/A';
    }
    final latestWeight = history.last.weight;

    final bmi = latestWeight / (height * height);
    return bmi.toStringAsFixed(2);
  }

  String _getBMICategory(double bmi) {
    if (bmi <= 0) return 'Bilinmiyor';
    if (bmi < 18.5) return 'Zayıf';
    if (bmi < 24.9) return 'Normal Ağırlık';
    if (bmi < 29.9) return 'Fazla Kilolu';
    return 'Obez';
  }

  void _saveData() async {
    final weightValue = double.tryParse(_weightController.text.replaceAll(',', '.'));
    final heightCm = double.tryParse(_heightController.text.replaceAll(',', '.'));

    bool updated = false;

    if (heightCm != null && heightCm > 50) {
      await gymTrackerProvider.saveHeight(heightCm / 100);
      updated = true;
    }

    if (weightValue != null && weightValue > 0) {
      final newEntry = WeightEntry(date: DateTime.now(), weight: weightValue);
      await gymTrackerProvider.saveWeightEntry(newEntry);
      updated = true;
    }

    // Kayıt başarılı olduğunda Listener (veya Provider) UI'ı güncelleyecektir.

    // Snackbar renkleri global sabitlerden çekiliyor
    if (updated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kişisel veriler güncellendi.', style: TextStyle(color: primaryDark)), backgroundColor: highlightColor),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lütfen geçerli kilo veya boy giriniz.', style: TextStyle(color: primaryDark)), backgroundColor: Colors.red.shade400),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kilo & Boy Takibi'),
      ),
      // KRİTİK DÜZELTME: Veri okuma ListenableBuilder içinde yapılıyor.
      body: ListenableBuilder(
        listenable: gymTrackerProvider,
        builder: (context, child) {
          final userHeight = gymTrackerProvider.userHeight;
          final weightHistory = gymTrackerProvider.weightHistory;

          // Tema renklerini al
          final highlightColor = Theme.of(context).primaryColor;
          final taupeAccent = Theme.of(context).colorScheme.secondary;
          final accentLight = Theme.of(context).colorScheme.onSurface;
          final surfaceDark = Theme.of(context).colorScheme.surface;

          final bmiText = _calculateBMI(userHeight, weightHistory);
          final bmiValue = double.tryParse(bmiText) ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kilo & Boy Girişi
                _buildDataInputCard(highlightColor),
                const SizedBox(height: 24),

                // BMI Sonuç Kartı
                if (bmiValue > 0)
                  _buildBMISummaryCard(bmiText, _getBMICategory(bmiValue), highlightColor, accentLight),
                if (bmiValue > 0)
                  const SizedBox(height: 24),


                // Kilo Takip Grafiği
                Text(
                  'Kilo Geçmişi',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: highlightColor),
                ),
                const SizedBox(height: 16),
                _buildWeightChart(weightHistory, highlightColor, surfaceDark, taupeAccent, accentLight),
                const SizedBox(height: 24),

                // Geçmiş Kilo Kayıtları
                _buildHistoryList(weightHistory, highlightColor, taupeAccent),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDataInputCard(Color highlightColor) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Güncel Bilgiler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: highlightColor)),
            const Divider(),

            // Boy Girişi
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Boy (cm)',
                hintText: 'Örn: 180',
              ),
            ),
            const SizedBox(height: 15),

            // Kilo Girişi
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Kilo (kg) [${DateFormat('dd/MM').format(DateTime.now())}]',
                hintText: 'Örn: 75.5',
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _saveData,
              icon: const Icon(Icons.save),
              label: const Text('Kaydet ve Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMISummaryCard(String bmiText, String category, Color highlightColor, Color accentLight) {

    // Kategoriye göre renk ataması
    Color color;
    if (category == 'Normal Ağırlık') {
      color = Colors.green.shade600;
    } else if (category == 'Zayıf' || category == 'Fazla Kilolu') {
      color = Colors.orange.shade600;
    } else {
      color = Colors.red.shade600;
    }

    return Card(
      elevation: 4,
      color: color.withOpacity(0.2), // Hafif arka plan rengi
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vücut Kitle İndeksi (BMI)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: highlightColor)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('BMI Skorunuz:', style: TextStyle(color: accentLight)),
                Text(bmiText, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: highlightColor)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Kategori:', style: TextStyle(color: accentLight)),
                Text(category, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildWeightChart(List<WeightEntry> history, Color highlightColor, Color surfaceDark, Color taupeAccent, Color accentLight) {
    if (history.length < 2) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text('Grafiği görmek için en az 2 kilo kaydı giriniz.', style: TextStyle(color: taupeAccent)),
      );
    }

    final spots = history.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    final minWeight = history.map((e) => e.weight).reduce((a, b) => a < b ? a : b);
    final maxWeight = history.map((e) => e.weight).reduce((a, b) => a > b ? a : b);
    final intervalY = ((maxWeight - minWeight) / 4).ceilToDouble();


    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        height: 250,
        child: LineChart(
          LineChartData(
            minX: spots.first.x,
            maxX: spots.last.x,
            minY: minWeight - 1,
            maxY: maxWeight + 1,

            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) => FlLine(color: taupeAccent.withOpacity(0.2), strokeWidth: 1),
              getDrawingVerticalLine: (value) => FlLine(color: taupeAccent.withOpacity(0.2), strokeWidth: 1),
            ),

            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

              // X Ekseni (Tarihler)
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: history.length > 5 ? (history.length / 5).ceilToDouble() : 1,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < history.length) {
                      final date = history[index].date;
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4.0,
                        child: Text(DateFormat('dd/MM').format(date), style: TextStyle(color: taupeAccent, fontSize: 10)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Y Ekseni (Kilo)
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text('${value.toStringAsFixed(0)} kg', style: TextStyle(color: taupeAccent, fontSize: 10), textAlign: TextAlign.left);
                  },
                  interval: intervalY == 0 ? 1 : intervalY,
                ),
              ),
            ),

            borderData: FlBorderData(show: true, border: Border.all(color: surfaceDark, width: 1)),

            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: highlightColor,
                barWidth: 3,
                dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: accentLight,
                  strokeWidth: 2,
                  strokeColor: highlightColor,
                ),
                ),
                belowBarData: BarAreaData(show: true, color: highlightColor.withOpacity(0.3)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<WeightEntry> history, Color highlightColor, Color taupeAccent) {
    if (history.isEmpty) return const SizedBox.shrink();

    // En yeni en üstte olacak şekilde ters çevir
    final reversedHistory = history.toList().reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tüm Kilo Kayıtları',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: highlightColor),
        ),
        const SizedBox(height: 10),
        // Silme butonu kaldırıldı (iptal isteğine uyuldu)
        ...reversedHistory.map((entry) {
          return ListTile(
            leading: Icon(Icons.fitness_center, color: taupeAccent),
            title: Text('${entry.weight.toStringAsFixed(1)} kg', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('dd MMMM yyyy, HH:mm').format(entry.date), style: TextStyle(color: taupeAccent)),
          );
        }).toList()
      ],
    );
  }
}