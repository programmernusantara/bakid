import 'package:bakid/features/admin/dashboard/admin_dasboard.dart';
import 'package:bakid/features/auth/auth_providers.dart';
import 'package:bakid/features/auth/login_screen.dart';
import 'package:bakid/features/auth/splash_screen.dart';
import 'package:bakid/features/guru/dashboard/guru_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = ref.watch(currentUserProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (error, _) => LoginScreen(error: error.toString()),
      data: (user) {
        final effectiveUser = currentUser ?? user;

        if (effectiveUser != null) {
          return _buildDashboard(effectiveUser);
        }
        return const LoginScreen();
      },
    );
  }

  Widget _buildDashboard(Map<String, dynamic> user) {
    final role = user['peran']?.toString().toLowerCase();

    switch (role) {
      case 'admin':
        return const AdminDasboard();
      case 'guru':
        return const GuruDashboard();
      default:
        return LoginScreen(error: 'Role tidak valid: $role');
    }
  }
}
