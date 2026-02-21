import 'package:flutter/material.dart';

// Screens
import 'screens/quote_screen.dart';

// Stores & Services
import 'core/quote_store.dart';
import 'core/notification_service.dart';
import 'core/task_store.dart';
import 'core/streak_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initServices();
    // Pre-initialize daily logic
    TaskStore.refreshForToday();
    StreakStore.updateForToday();
  } catch (e) {
    debugPrint("BOOT ERROR: $e");
  }

  runApp(const NoRegretApp());
}

Future<void> _initServices() async {
  try {
    // Note: Hive init is removed since we are using In-Memory logic stores
    await NotificationService.init();
    await QuoteStore.init();
    debugPrint("SYSTEM: Services Online.");
  } catch (e) {
    debugPrint("SERVICE ERROR: $e");
  }
}

// In-memory settings controller (replaces Hive settingsBox)
class AppSettings extends ChangeNotifier {
  bool ghostMode = false;

  void toggleGhostMode() {
    ghostMode = !ghostMode;
    notifyListeners();
  }
}

// Global instance for the app to listen to
final AppSettings appSettings = AppSettings();

class NoRegretApp extends StatelessWidget {
  const NoRegretApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appSettings,
      builder: (context, _) {
        final bool isGhostMode = appSettings.ghostMode;
        
        // UI Customization based on mode
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
            fontFamily: isGhostMode ? 'monospace' : null, 
            colorScheme: ColorScheme.dark(
              primary: activeColor,
              surface: const Color(0xFF0A0A0A),
            ),
            // Ensuring the app bars and cards match our dark theme
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              elevation: 0,
            ),
          ),
          home: const QuoteScreen(),
        );
      },
    );
  }
}