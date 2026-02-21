import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import 'task_store.dart';

class CalendarService {
  static final _googleSignIn = GoogleSignIn(
    // Ensure this Client ID matches your google-services.json precisely
    clientId: "589119281976-649h3tvpg9jfvjd3j0eel77k0vthci01.apps.googleusercontent.com",
    scopes: [
      CalendarApi.calendarReadonlyScope,
      'email',
    ],
  );

  static Future<void> syncGoogleTasks() async {
    if (!TaskStore.isInitialized) {
      debugPrint("SYSTEM: Sync blocked. TaskStore offline.");
      return;
    }

    try {
      // 1. Authenticate
      GoogleSignInAccount? user = await _googleSignIn.signInSilently();
      user ??= await _googleSignIn.signIn();
      
      if (user == null) {
        debugPrint("AUTH: Sync aborted by user.");
        return;
      }

      // 2. Initialize API
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) return;

      final calendarApi = CalendarApi(httpClient);
      
      // 3. Define Today's Window (00:00 to 23:59)
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final events = await calendarApi.events.list(
        "primary",
        timeMin: startOfToday.toUtc(),
        timeMax: endOfToday.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
      );

      if (events.items != null) {
        int addedCount = 0;
        for (var event in events.items!) {
          if (_processEvent(event)) addedCount++;
        }
        
        if (addedCount > 0) {
          debugPrint("SYNC: Integrated $addedCount events.");
          TaskStore.notify(); // Refresh UI
        }
      }
    } catch (e) {
      debugPrint("CALENDAR ERROR: $e");
      // PRO TIP: In 2026, if you get 'ApiException 10', 
      // check your SHA-1 fingerprint in Firebase/Google Cloud.
      rethrow;
    }
  }

  static bool _processEvent(Event event) {
    final String googleId = event.id ?? "";
    final String summary = event.summary ?? 'Untitled Mission';
    if (googleId.isEmpty) return false;

    // Check if task already exists (by ID or exact Title match)
    final bool exists = TaskStore.tasks.any(
      (t) => t.id == googleId || t.title == "📅 $summary",
    );

    if (exists) return false;

    // Inject as a new Task
    final newTask = Task(
      id: googleId,
      title: "📅 $summary",
      isDaily: false, 
      createdDate: DateTime.now(), // Pass current day filter
      completionHistory: [],
    );

    TaskStore.addTask(newTask);
    return true;
  }

  static Future<void> logout() async {
    await _googleSignIn.signOut();
    debugPrint("AUTH: Logged out of Google.");
  }
}