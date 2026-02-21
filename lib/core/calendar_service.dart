import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import '../models/task_model.dart';
import 'task_store.dart';

class CalendarService {
  static final _googleSignIn = GoogleSignIn(
    clientId: "589119281976-649h3tvpg9jfvjd3j0eel77k0vthci01.apps.googleusercontent.com",
    scopes: [
      CalendarApi.calendarReadonlyScope,
      'email',
    ],
  );

  static Future<void> syncGoogleTasks() async {
    if (!TaskStore.isInitialized) {
      print("Calendar Sync: TaskStore not initialized.");
      return;
    }

    try {
      // 1. Silent sign-in attempt first, then full sign-in
      GoogleSignInAccount? user = await _googleSignIn.signInSilently();
      user ??= await _googleSignIn.signIn();
      
      if (user == null) {
        print("Calendar Sync: User cancelled login.");
        return;
      }

      // 2. Get the authenticated HTTP client
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        print("Calendar Sync: Failed to get authenticated client.");
        return;
      }

      final calendarApi = CalendarApi(httpClient);
      
      // 3. Define Time Range (Local Today)
      // We fetch from start of today 00:00 to end of today 23:59
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      print("Syncing events from ${startOfToday.toIso8601String()}");

      final events = await calendarApi.events.list(
        "primary",
        timeMin: startOfToday.toUtc(),
        timeMax: endOfToday.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      if (events.items != null && events.items!.isNotEmpty) {
        int addedCount = 0;
        for (var event in events.items!) {
          bool added = _convertToLocalTask(event);
          if (added) addedCount++;
        }
        print("Calendar Sync: Added $addedCount new events.");
        
        // Notify the UI listeners
        TaskStore.notify();
      } else {
        print("Calendar Sync: No events found for today.");
      }
    } catch (e) {
      print("Calendar Sync Error: $e");
      rethrow;
    }
  }

  /// Converts a Google Event to a local Task. 
  /// Returns true if added, false if it already existed.
  static bool _convertToLocalTask(Event event) {
    final String googleId = event.id ?? "";
    final String summary = event.summary ?? 'Untitled Event';
    if (googleId.isEmpty) return false;

    // Duplicate Check: Look for ID or the specific Calendar Title format
    final bool exists = TaskStore.tasks.any(
      (t) => t.id == googleId || t.title == "📅 $summary",
    );

    if (exists) return false;

    // Create the mission
    final newTask = Task(
      id: googleId,
      title: "📅 $summary",
      isDaily: false, 
      // We set createdDate to exactly NOW so it passes the 'wasCreatedToday' UI filter
      createdDate: DateTime.now(),
      completionHistory: [],
      timeSpentInSeconds: 0,
    );

    TaskStore.addTask(newTask);
    return true;
  }

  static Future<void> logout() => _googleSignIn.signOut();
}