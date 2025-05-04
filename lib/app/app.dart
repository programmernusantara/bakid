import 'package:bakid/app/app_providers.dart';
import 'package:bakid/features/auth/login_screen.dart';
import 'package:bakid/features/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import '../features/splash/splash_screen.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool _initialSplashCompleted = false;

  @override
  void initState() {
    super.initState();
    // Tampilkan splash screen hanya di awal selama 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _initialSplashCompleted = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Tampilkan splash screen awal jika belum selesai
    if (!_initialSplashCompleted) {
      return const SplashScreen();
    }

    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (user) {
        // 2. Setelah splash awal selesai, tampilkan halaman berdasarkan auth state
        if (user != null) {
          return const DashboardScreen();
        }
        return const LoginScreen();
      },
      loading: () {
        // 3. Untuk loading state, tampilkan loading indicator sederhana
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error:
          (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset('assets/error.svg', width: 100),
                  const SizedBox(height: 20),
                  Text('Error: $error'),
                ],
              ),
            ),
          ),
    );
  }
}
