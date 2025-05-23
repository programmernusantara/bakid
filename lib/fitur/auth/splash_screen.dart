import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
    Future.delayed(const Duration(seconds: 5), () {
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
              color: Colors.white,
              child: Center(
                child: Lottie.asset(
                  'assets/animations/splash_animation.json', // Update this path to your actual asset path
                  width: 300,
                  height: 300,
                  fit: BoxFit.contain,
                  repeat: false,
                  frameRate: FrameRate.max,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
