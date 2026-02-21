import 'dart:convert';
import 'dart:math';
import '../models/quote_model.dart';

class QuoteStore {
  static final List<Quote> _quotes = [];
  static final Map<String, int> _dailyQuoteCache = {};

  static Future<void> init() async {
    if (_quotes.isEmpty) {
      _seedDatabase();
    }
  }

  static void _seedDatabase() {
    const String jsonSource = '''
    [
      { "text": "The pain of discipline is far less than the pain of regret.", "author": "Jim Rohn" },
      { "text": "Amateurs sit and wait for inspiration, the rest of us just get up and go to work.", "author": "Stephen King" },
      { "text": "Discipline is choosing between what you want now and what you want most.", "author": "Abraham Lincoln" },
      { "text": "You do not rise to the level of your goals. You fall to the level of your systems.", "author": "James Clear" },
      { "text": "Work like there is someone working twenty-four hours a day to take it away from you.", "author": "Mark Cuban" },
      { "text": "Don't stop when you're tired. Stop when you're done.", "author": "David Goggins" },
      { "text": "If you are going through hell, keep going.", "author": "Winston Churchill" },
      { "text": "Deep work is not a remote perk, it's a superpower.", "author": "Cal Newport" },
      { "text": "The successful warrior is the average man, with laser-like focus.", "author": "Bruce Lee" },
      { "text": "You cannot escape the responsibility of tomorrow by evading it today.", "author": "Abraham Lincoln" },
      { "text": "Hard work beats talent when talent doesn’t work hard.", "author": "Tim Notke" },
      { "text": "Your mind is for having ideas, not holding them.", "author": "David Allen" },
      { "text": "Focus is a matter of deciding what things you're not going to do.", "author": "John Carmack" },
      { "text": "It’s not the daily increase but daily decrease. Hack away at the unessential.", "author": "Bruce Lee" },
      { "text": "Productivity is being able to do things that you were never able to do before.", "author": "Franz Kafka" },
      { "text": "Action is the foundational key to all success.", "author": "Pablo Picasso" },
      { "text": "Do today what others won't, so you can live tomorrow what others can't.", "author": "Jerry Rice" },
      { "text": "The best way to predict the future is to create it.", "author": "Peter Drucker" },
      { "text": "Success is stumbling from failure to failure with no loss of enthusiasm.", "author": "Winston Churchill" },
      { "text": "I fear not the man who has practiced 10,000 kicks once, but the man who has practiced one kick 10,000 times.", "author": "Bruce Lee" },
      { "text": "You don’t need more time, you need more focus.", "author": "Unknown" },
      { "text": "Self-discipline is the only way to get where you want to go.", "author": "Unknown" },
      { "text": "Efficiency is doing things right; effectiveness is doing the right things.", "author": "Peter Drucker" },
      { "text": "The only difference between where you are and where you want to be is the work you haven't done yet.", "author": "Unknown" },
      { "text": "Either you run the day or the day runs you.", "author": "Jim Rohn" },
      { "text": "Motivation is what gets you started. Habit is what keeps you going.", "author": "Jim Rohn" },
      { "text": "The way to get started is to quit talking and begin doing.", "author": "Walt Disney" },
      { "text": "Your future self is watching you right now through memories. Give them a good show.", "author": "Unknown" },
      { "text": "The cost of a thing is the amount of life which is required to be exchanged for it.", "author": "Henry David Thoreau" },
      { "text": "If you don't pay the price for success, you will pay the price of failure.", "author": "Unknown" }
    ]
    ''';

    final List<dynamic> decodedData = jsonDecode(jsonSource);

    _quotes.addAll(decodedData.map((item) {
      return Quote(
        text: item['text'],
        author: item['author'],
        createdAt: DateTime.now(),
      );
    }).toList());
  }

  static Quote getDailyQuote() {
    if (_quotes.isEmpty) {
      return Quote(
        text: "The best preparation for tomorrow is doing your best today.",
        author: "H. Jackson Brown Jr.",
        createdAt: DateTime.now(),
      );
    }

    final now = DateTime.now();
    final String todayKey = "quote_${now.year}_${now.month}_${now.day}";

    int? dailyIndex = _dailyQuoteCache[todayKey];

    if (dailyIndex == null) {
      dailyIndex = Random().nextInt(_quotes.length);
      _dailyQuoteCache[todayKey] = dailyIndex;
    }

    return _quotes[dailyIndex % _quotes.length];
  }
}
