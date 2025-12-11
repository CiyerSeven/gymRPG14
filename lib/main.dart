import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'providers/gym_tracker_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/add_workout_screen.dart';
import 'screens/history_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/manage_exercises_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/workout_program_screen.dart'; // Program ekranı için import edildi

// Yeni Renk Paleti Tanımları
const Color primaryDark = Color(0xFF222831);    // #222831 - Ana Arka Plan (Dark Charcoal)
const Color surfaceDark = Color(0xFF393E46);    // #393E46 - Kartlar ve Yüzeyler (Dark Slate)
const Color taupeAccent = Color(0xFF948979);    // #948979 - İkincil Vurgu (Taupe)
const Color accentLight = Color(0xFFF0EAE3);    // #F0EAE3 - Birincil Vurgu/Metin (Daha Parlak Krem)
const Color highlightColor = Color(0xFFB8A287); // Yeni Vurgu Rengi (Hafif Koyu Taupe)

// Global olarak erişilebilecek provider instance'ı
final gymTrackerProvider = GymTrackerProvider();

void main() async {
  // Hive ve Flutter Binding'lerini başlat
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Locale data'yı başlat (HistoryScreen için gerekli)
  await initializeDateFormatting('tr_TR', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Provider'ın yüklenme durumunu dinler
    return ListenableBuilder(
      listenable: gymTrackerProvider,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hoşgeldin Maceracı',
          theme: ThemeData(
            useMaterial3: true,

            // Ana Arka Plan
            scaffoldBackgroundColor: primaryDark,
            cardColor: surfaceDark,

            // Temel Renkler (Vurgu)
            primaryColor: highlightColor,
            colorScheme: ColorScheme.dark(
              primary: highlightColor,
              secondary: taupeAccent,
              surface: surfaceDark,
              background: primaryDark,
              onPrimary: primaryDark,
              onSurface: accentLight,
            ),

            // AppBar Teması
            appBarTheme: AppBarTheme(
              backgroundColor: surfaceDark,
              foregroundColor: accentLight,
              titleTextStyle: TextStyle(
                color: accentLight,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              elevation: 0,
            ),

            // Bottom Navigasyon Teması
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              backgroundColor: surfaceDark,
              selectedItemColor: accentLight,
              unselectedItemColor: taupeAccent,
              type: BottomNavigationBarType.fixed,
            ),

            // Metin Teması
            textTheme: Typography.whiteMountainView.copyWith(
              bodyMedium: const TextStyle(color: accentLight),
              bodyLarge: const TextStyle(color: accentLight),
              titleMedium: const TextStyle(color: accentLight),
              titleLarge: const TextStyle(color: accentLight),
              headlineSmall: const TextStyle(
                color: accentLight,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Giriş Alanları (InputDecoration) Teması
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

            // Buton Teması (ElevatedButton)
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: highlightColor,
                foregroundColor: primaryDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            // TextButton/OutlinedButton için varsayılan renkler
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: highlightColor,
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: highlightColor,
                side: BorderSide(color: highlightColor),
              ),
            ),

            // Card Teması
            cardTheme: CardTheme(
              color: surfaceDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
          ),
          // Veri yüklenene kadar Splash ekranı göster
          home: gymTrackerProvider.isInitialized
              ? MainAppScreen()
              : const SplashScreen(),
        );
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: accentLight),
            const SizedBox(height: 16),
            Text(
              'Veriler Yükleniyor...',
              style: TextStyle(fontSize: 18, color: accentLight),
            ),
          ],
        ),
      ),
    );
  }
}

class MainAppScreen extends StatefulWidget {
  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    AddWorkoutScreen(),
    HistoryScreen(),
    AnalysisScreen(),
    ManageExercisesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Logo Widget'ı (AppBar'da kullanmak için boyutlandırıldı)
  Widget _buildAppBarLogo() {
    return SizedBox(
      width: 72, // BÜYÜTÜLDÜ
      height: 72,
      child: Image.asset(
        'assets/logo.png',
        errorBuilder: (context, error, stackTrace) {
          // Logo dosyası bulunamazsa yedek ikon
          return Icon(
            Icons.fitness_center,
            color: highlightColor,
            size: 52, // BÜYÜK FALLBACK İKON
          );
        },
      ),
    );
  }

  // Profil ekranına yönlendirme
  void _navigateToProfile(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfileScreen(),
    ));
  }

  // Program ekranına yönlendirme
  void _navigateToProgram(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const WorkoutProgramScreen(),
    ));
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72, // APPBAR YÜKSEKLİĞİ ARTIRILDI
        title: Row(
          children: [
            _buildAppBarLogo(), // Logo
            const SizedBox(width: 12),
          ],
        ),
        // Profil ve Program Butonları Eklendi
        actions: [
          // Program Butonu
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            color: highlightColor,
            iconSize: 30,
            onPressed: () => _navigateToProgram(context), // Program Ekranına Yönlendir
          ),
          // Profil Butonu
          IconButton(
            icon: const Icon(Icons.person_outline),
            color: highlightColor,
            iconSize: 30,
            onPressed: () => _navigateToProfile(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: 'Antrenman',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            label: 'Geçmiş',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            label: 'Analiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Hareketler',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}