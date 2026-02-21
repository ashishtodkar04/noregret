import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';

class QuoteScreen extends StatefulWidget {
  const QuoteScreen({super.key});

  @override
  State<QuoteScreen> createState() => _QuoteScreenState();
}

class _QuoteScreenState extends State<QuoteScreen> {
  bool _isNavigating = false;
  final bool _isGhostMode = false;

  void _handleEngage() async {
    if (_isNavigating) return;

    HapticFeedback.heavyImpact();
    setState(() => _isNavigating = true);

    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor =
        _isGhostMode ? const Color(0xFF637381) : Colors.orange;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF080808),
        body: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Text(
                _isGhostMode
                    ? "SUBSYSTEM_STANDBY // ${DateTime.now().year}"
                    : "SYSTEM_INITIALIZED // ${DateTime.now().year}",
                style: TextStyle(
                  color: activeColor,
                  fontFamily:
                      _isGhostMode ? 'monospace' : null,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Icon(
                _isGhostMode
                    ? Icons.terminal_rounded
                    : Icons.radar,
                color: activeColor,
                size: 32,
              ),
              const SizedBox(height: 40),
              const Column(
                children: [
                  Text(
                    "DISCIPLINE BEATS\nMOTIVATION EVERY\nSINGLE DAY.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    "— PROTOCOL: NO REGRET",
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 10,
                      letterSpacing: 4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 64,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: activeColor, width: 2),
                    foregroundColor: activeColor,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: _handleEngage,
                  child: _isNavigating
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            color: activeColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          _isGhostMode
                              ? "ACCESS_TERMINAL"
                              : "ENGAGE PROTOCOL",
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: 3,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
