import 'package:google_generative_ai/google_generative_ai.dart';
import 'session_store.dart';
import 'task_store.dart';
import 'streak_store.dart';

class AIStore {
  static const _apiKey = 'AIzaSyBXcCNYBiqno1SG7UTd1VqKtypJdV7r9W8';
  static const bool isDevMode = false; 
  static const _modelName = 'gemini-2.5-flash'; 

  static GenerativeModel get _model {
    final todayFocus = SessionStore.todayTotalFormatted;
    final currentStreak = StreakStore.currentStreak;
    final pendingTasks = TaskStore.tasks.where((t) => !t.isCompleted).length;

    return GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      systemInstruction: Content.system('''
        You are a Ruthless Performance Coach and Expert Study Tutor. 
        Current Stats: Focus: $todayFocus, Streak: $currentStreak days, Tasks: $pendingTasks.
        
        PERSONALITY:
        - Brutally honest, direct, and zero-tolerance for laziness.
        - If focus is 0m, your "Roast" should be scathing. 
        - End every response with one challenging Active Recall question.
        
        RULES:
        - Use Markdown for impact (bolding, headers).
        - Reply with ONLY the response, no meta-talk or "Sure, I can help."
      '''),
      generationConfig: GenerationConfig(
        maxOutputTokens: 1024,
        temperature: 0.9,
      ),
    );
  }

  // Initialize Chat Session
  static ChatSession _chat = _model.startChat();

  static List<Content> get history => _chat.history.toList();

  static void clearChat() {
    _chat = _model.startChat();
  }

  /// Main Chat Interface for "Audit My Day", "Roast Me", etc.
  static Future<String> askGemini(String userPrompt) async {
    if (isDevMode) return "**DEV MODE ACTIVE**: Skipping API call.";

    try {
      final response = await _chat.sendMessage(Content.text(userPrompt));
      final text = response.text;
      
      if (text == null || text.isEmpty) {
        return "The Gatekeeper remains silent. Try rephrasing your command.";
      }
      return text;
    } catch (e) {
      // Log the full error to the debug console
      print("AI ERROR: $e"); 
      
      if (e.toString().contains('quota')) {
        return "QUOTA_EXCEEDED: The Gatekeeper is overwhelmed. Take a 60s break.";
      }
      return "ERROR: Connection failed. Check your internet or API key.";
    }
  }

  /// PHASE 2: Generate the Gatekeeper quiz after focus session
  static Future<String> generateGatekeeperQuiz(
    String taskTitle,
    String userTopic,
  ) async {
    if (isDevMode) {
      return "DEV MODE: Briefly explain the core concept of **$userTopic**.";
    }

    try {
      final model = GenerativeModel(
        model: _modelName,
        apiKey: _apiKey,
        systemInstruction: Content.system('''
          You are the Gatekeeper. User finished: $taskTitle.
          Topic: $userTopic.
          
          RULE:
          - Generate ONE high-difficulty, conceptual question about $userTopic.
          - Be direct, intimidating, and concise.
          - Do not provide the answer.
        '''),
      );

      final response = await model.generateContent([
        Content.text("Challenge me on $userTopic."),
      ]);

      return response.text ?? "Prove you were working. What did you just learn?";
    } catch (e) {
      if (e.toString().contains('quota')) return "QUOTA_EXCEEDED";
      return "THE GATEKEEPER IS BUSY. TRY AGAIN LATER.";
    }
  }

  /// PHASE 3: Grade the user's answer to the quiz
  static Future<bool> gradeAnswer(String question, String userAnswer) async {
    if (isDevMode) return userAnswer.trim().length > 3;

    try {
      final model = GenerativeModel(model: _modelName, apiKey: _apiKey);

      final prompt = '''
        Question: $question
        User's Answer: $userAnswer
        
        Is this answer correct and shows deep understanding? 
        Reply with ONLY the word "PASS" or "FAIL".
      ''';

      final response = await model.generateContent([Content.text(prompt)]);
      final result = response.text?.trim().toUpperCase() ?? "FAIL";

      return result.contains("PASS");
    } catch (e) {
      // Fail-safe: if the API hits a limit during grading, let them pass
      // so their hard-earned focus session isn't lost.
      if (e.toString().contains('quota')) return true;
      return false;
    }
  }
}