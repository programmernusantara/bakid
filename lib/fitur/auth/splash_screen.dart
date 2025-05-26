import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final Widget child;
  const SplashScreen({super.key, required this.child});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Hide splash screen after 3 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          widget.child,

          // Splash screen overlay
          if (_showSplash)
            Container(
              color: Colors.white, // Background color of splash screen
              child: Center(
                child: Image.asset(
                  'assets/logo/bakid.png', // Path to your splash image
                ),
              ),
            ),
        ],
      ),
    );
  }
}
