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
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initServices();

    // Refresh tasks for today
    TaskStore.refreshForToday();

    debugPrint("SYSTEM: All systems nominal. Launching UI.");
  } catch (e) {
    debugPrint("BOOT FATAL ERROR: $e");
  }

  runApp(const NoRegretApp());
}

Future<void> _initServices() async {
  await appSettings.init();

  await Future.wait([
    TaskStore.init(),
    SessionStore.init(),
    ScheduleStore.init(),
    StreakStore.init(),
    QuoteStore.init(),
    NotificationService.init(),
  ]);

  // 🔔 Schedule today's reminders
  await NotificationService.scheduleScheduleReminders();

  debugPrint("SYSTEM: Persistent Storage Online.");
}

// ---------------- SETTINGS ----------------

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

final AppSettings appSettings = AppSettings();

// ---------------- APP ----------------

class NoRegretApp extends StatefulWidget {
  const NoRegretApp({super.key});

  @override
  State<NoRegretApp> createState() => _NoRegretAppState();
}

class _NoRegretAppState extends State<NoRegretApp> with WidgetsBindingObserver {
  DateTime lastCheck = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /// Detect when the app resumes (new day check)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();

      if (!_isSameDay(now, lastCheck)) {
        TaskStore.refreshForToday();
        debugPrint("SYSTEM: New Day Detected → Tasks Refreshed");
      }

      lastCheck = now;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final bool isGhostMode = appSettings.ghostMode;

        final Color activeColor = isGhostMode
            ? const Color(0xFF637381)
            : Colors.orange;

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'No Regret',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.black,
            primaryColor: activeColor,

            fontFamily: isGhostMode ? 'monospace' : 'Inter',

            colorScheme: ColorScheme.dark(
              primary: activeColor,
              secondary: activeColor.withOpacity(0.7),
              surface: const Color(0xFF0A0A0A),
              onSurface: isGhostMode ? activeColor : Colors.white,
            ),

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
