import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import '../core/quote_store.dart';

class DailyQuoteCard extends StatelessWidget {
  const DailyQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    // FIXED: Changed getTodayQuote() to getDailyQuote()
    final quote = QuoteStore.getDailyQuote();

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: "${quote.text} — ${quote.author}"));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Quote copied to clipboard"),
            backgroundColor: Colors.orange.withOpacity(0.8),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 800),
        opacity: 1.0,
        child: Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03), 
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.format_quote_rounded, color: Colors.orange.withOpacity(0.8), size: 32),
                  const Text(
                    "DAILY MOMENTUM",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                quote.text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(width: 24, height: 2, color: Colors.orange.withOpacity(0.5)),
                  const SizedBox(width: 10),
                  Text(
                    quote.author.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.orange,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}