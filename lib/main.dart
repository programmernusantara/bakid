import 'dart:async';
import 'package:bakid/core/services/auth_service.dart';
import 'package:bakid/fitur/auth/auth_checker.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/auth/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  await runZonedGuarded(
    () async {
      final sharedPrefs = await SharedPreferences.getInstance();

      await Supabase.initialize(
        url: 'https://zptdyukjsovnfyrbxgjl.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpwdGR5dWtqc292bmZ5cmJ4Z2psIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDcyMjgzMzYsImV4cCI6MjA2MjgwNDMzNn0.pALc3UH0N4GEQedbraZF1dU01hrFn7px3Y_p_B0Xot4',
      );

      runApp(
        ProviderScope(
          overrides: [sharedPrefsProvider.overrideWithValue(sharedPrefs)],
          child: const MadrasahApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Global error: $error');
      debugPrint('Stack trace: $stack');
    },
  );
}

class MadrasahApp extends StatelessWidget {
  const MadrasahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manajemen Madrasah',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SplashScreenWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper> {
  @override
  Widget build(BuildContext context) {
    return const SplashScreen(child: AuthCheckerWrapper());
  }
}

class AuthCheckerWrapper extends ConsumerStatefulWidget {
  const AuthCheckerWrapper({super.key});

  @override
  ConsumerState<AuthCheckerWrapper> createState() => _AuthCheckerWrapperState();
}

class _AuthCheckerWrapperState extends ConsumerState<AuthCheckerWrapper> {
  Future<Map<String, dynamic>?>? _userFuture;

  @override
  void initState() {
    super.initState();
    // Don't modify providers here, just load the data
    _userFuture = ref.read(authServiceProvider).getStoredUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Use didChangeDependencies to handle the future result
    _userFuture?.then((user) {
      if (user != null && mounted) {
        // Schedule the provider update for the next frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(currentUserProvider.notifier).state = user;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _userFuture,
      builder: (context, snapshot) {
        return const AuthChecker();
      },
    );
  }
}
