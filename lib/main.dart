import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'screens/quote_screen.dart';

// Stores & Services
import 'core/quote_store.dart';
import 'core/notification_service.dart';
import 'core/task_store.dart';
import 'core/streak_store.dart';
import 'core/session_store.dart';
import 'core/schedule_store.dart';

void main() async {
  // 1. Mandatory for storage and notifications
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. BOOT SEQUENCE: Load all data from disk BEFORE showing UI
    await _initServices();
    
    // 3. LOGIC REFRESH: Handle daily resets
    // Note: StreakStore.init() now handles its own "Broken Streak" check 
    // internally, so we don't call updateForToday() here to avoid false increments.
    TaskStore.refreshForToday();
    
    debugPrint("SYSTEM: All systems nominal. Launching UI.");
  } catch (e) {
    debugPrint("BOOT FATAL ERROR: $e");
  }

  runApp(const NoRegretApp());
}

/// Initializes all persistent stores in parallel for faster startup
Future<void> _initServices() async {
  // Initialize AppSettings first to determine the theme immediately
  await appSettings.init();
  
  // Initialize all storage stores 
  await Future.wait([
    TaskStore.init(),
    SessionStore.init(),
    ScheduleStore.init(),
    StreakStore.init(),
    QuoteStore.init(),
    NotificationService.init(),
  ]);
  
  debugPrint("SYSTEM: Persistent Storage Online.");
}

// --- PERSISTED APP SETTINGS ---

class AppSettings extends ChangeNotifier {
  bool ghostMode = false;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    ghostMode = prefs.getBool('ghost_mode_active') ?? false;
    notifyListeners();
  }

  void toggleGhostMode() async {
    ghostMode = !ghostMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('ghost_mode_active', ghostMode);
    notifyListeners();
  }
}

// Global instance for the app to listen to
final AppSettings appSettings = AppSettings();

// --- ROOT APPLICATION ---

class NoRegretApp extends StatelessWidget {
  const NoRegretApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final bool isGhostMode = appSettings.ghostMode;
        
        // UI Customization: Tactical Orange or Stealth Gray
        final Color activeColor =
            isGhostMode ? const Color(0xFF637381) : Colors.orange;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'No Regret',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            primaryColor: activeColor,
            
            // Switches to a terminal-style font for Ghost Mode
            fontFamily: isGhostMode ? 'monospace' : 'Inter', 
            
            colorScheme: ColorScheme.dark(
              primary: activeColor,
              secondary: activeColor.withOpacity(0.7),
              surface: const Color(0xFF0A0A0A),
              onSurface: isGhostMode ? activeColor : Colors.white,
            ),

            // Tactical styling for App Bar
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.black,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: activeColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontFamily: isGhostMode ? 'monospace' : null,
              ),
            ),

            // Dark thematic cards
            cardTheme: CardThemeData(
              color: const Color(0xFF0D0D0D),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: activeColor.withOpacity(0.1)),
              ),
            ),
          ),
          home: const QuoteScreen(),
        );
      },
    );
  }
}