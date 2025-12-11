import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // fl_chart kütüphanesi import edildi
import '../main.dart'; // Tema renkleri ve global provider için
import '../models/exercise.dart';
import '../models/workout.dart';

// Analiz için hazırlanan veri noktası
class ChartDataPoint {
  final DateTime date;
  final double value; // Maksimum Ağırlık veya Toplam Hacim
  final int index; // X ekseninde sıralama için

  ChartDataPoint({required this.date, required this.value, required this.index});
}

class ExerciseDetailChartScreen extends StatefulWidget {
  final String exerciseName;

  const ExerciseDetailChartScreen({super.key, required this.exerciseName});

  @override
  State<ExerciseDetailChartScreen> createState() => _ExerciseDetailChartScreenState();
}

class _ExerciseDetailChartScreenState extends State<ExerciseDetailChartScreen> {
  // Varsayılan olarak maksimum ağırlık (Heaviest Set) gösterilir
  bool showVolume = false;

  // Tüm geçmiş veriyi toplayan fonksiyon
  List<ChartDataPoint> _getChartData(bool volumeMode) {
    // Verileri doğrudan global provider'dan çekiyoruz.
    final records = gymTrackerProvider.workouts
        .where((w) => w.exercises.any((e) => e.name == widget.exerciseName))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final List<ChartDataPoint> data = [];

    for (int i = 0; i < records.length; i++) {
      final workout = records[i];
      final exercise = workout.exercises.firstWhere(
            (e) => e.name == widget.exerciseName,
        orElse: () => Exercise(id: '', name: '', muscleGroup: '', sets: []),
      );

      if (exercise.sets.isEmpty) continue; // Geçersiz kaydı atla

      double value = volumeMode
          ? exercise.totalVolume
          : (exercise.heaviestSet?.weight ?? 0.0);

      if (value > 0) {
        data.add(ChartDataPoint(
          date: workout.date,
          value: value,
          index: i.toDouble().toInt(), // X ekseni değeri
        ));
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    // ListenableBuilder, global provider'daki değişiklikleri dinler.
    return ListenableBuilder(
      listenable: gymTrackerProvider,
      builder: (context, child) {
        final data = _getChartData(showVolume);
        final String unit = showVolume ? 'kg (Hacim)' : 'kg (Maks. Ağırlık)';

        return Scaffold(
          appBar: AppBar(
            title: Text('${widget.exerciseName} İlerleme Analizi'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Metrik Seçimi Butonu
                _buildMetricSelector(),
                const SizedBox(height: 20),

                // Veri Özeti
                _buildMetricsSummary(data, unit),
                const SizedBox(height: 30),

                // Grafik Alanı Başlığı
                Text(
                  'Zamana Karşı ${showVolume ? 'Hacim' : 'Maksimum Ağırlık'}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: highlightColor),
                ),
                const SizedBox(height: 16),

                // Grafik Bileşeni
                _buildLineChart(data, unit),
              ],
            ),
          ),
        );
      },
    );
  }

  // Metrik Seçimi Butonu
  Widget _buildMetricSelector() {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          showVolume = !showVolume;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: surfaceDark,
        foregroundColor: accentLight,
        side: BorderSide(color: highlightColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Text(
          showVolume ? 'Maks. Ağırlığı Göster' : 'Toplam Hacmi Göster',
          style: TextStyle(color: highlightColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Özet İstatistikler
  Widget _buildMetricsSummary(List<ChartDataPoint> data, String unit) {
    if (data.isEmpty) {
      return Center(
        child: Text('Grafik verisi bulunamadı.', style: TextStyle(color: taupeAccent)),
      );
    }

    // Güvenli hesaplama
    final maxValue = data.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    final avgValue = data.map((p) => p.value).reduce((a, b) => a + b) / data.length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              label: 'En Yüksek',
              value: '${maxValue.toStringAsFixed(1)} ${unit.split(' ')[0]}',
              icon: Icons.trending_up,
            ),
            _SummaryItem(
              label: 'Ortalama',
              value: '${avgValue.toStringAsFixed(1)} ${unit.split(' ')[0]}',
              icon: Icons.equalizer,
            ),
            _SummaryItem(
              label: 'Toplam Kayıt',
              value: data.length.toString(),
              icon: Icons.storage,
            ),
          ],
        ),
      ),
    );
  }

  // Grafik Bileşeni (fl_chart)
  Widget _buildLineChart(List<ChartDataPoint> data, String unit) {
    if (data.isEmpty) {
      return Container(
        height: 300, // Grafik boyutu
        alignment: Alignment.center,
        child: Text('Yeterli kayıt yok.', style: TextStyle(color: taupeAccent)),
      );
    }

    // FlSpot sınıfı doğrudan fl_chart import'undan gelir.
    final spots = data.map((point) {
      return FlSpot(point.index.toDouble(), point.value);
    }).toList();

    final maxYValue = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final intervalY = (maxYValue / 4).ceilToDouble(); // 4 ana çizgi olması için

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        height: 300,
        child: LineChart(
          LineChartData(
            // Sınırları otomatik hesapla
            minX: spots.first.x,
            maxX: spots.last.x,
            minY: 0,
            maxY: (maxYValue * 1.1).ceilToDouble(),

            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              getDrawingHorizontalLine: (value) => FlLine(
                color: taupeAccent.withOpacity(0.2),
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: taupeAccent.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),

              // X Ekseni (Tarihler)
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: data.length > 5 ? (data.length / 5).ceilToDouble() : 1,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < data.length) {
                      final date = data[index].date;

                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4.0,
                        child: Text('${date.month}/${date.day}', style: TextStyle(color: taupeAccent, fontSize: 10)),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),

              // Y Ekseni (Değerler)
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40, // Hata: 4:0 yerine 40 kullanıldı
                  getTitlesWidget: (value, meta) {
                    return Text(value.toStringAsFixed(0), style: TextStyle(color: taupeAccent, fontSize: 10), textAlign: TextAlign.left);
                  },
                  interval: intervalY == 0 ? 1 : intervalY,
                ),
              ),
            ),

            borderData: FlBorderData(
              show: true,
              border: Border.all(color: surfaceDark, width: 1),
            ),

            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: highlightColor, // Ana hat rengi
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 3,
                    color: accentLight, // Nokta rengi krem
                    strokeWidth: 1.5,
                    strokeColor: highlightColor,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [highlightColor.withOpacity(0.3), highlightColor.withOpacity(0.0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],

            // touchData: const FlTouchData(enabled: true),
          ),
        ),
      ),
    );
  }
}

// Özet İstatistik Alt Bileşeni
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: highlightColor, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accentLight)),
        Text(label, style: TextStyle(fontSize: 12, color: taupeAccent)),
      ],
    );
  }
}