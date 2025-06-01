import 'package:bakid/fitur/admin/dashboard/admin_dasboard.dart';
import 'package:bakid/fitur/auth/auth_providers.dart';
import 'package:bakid/fitur/auth/login_screen.dart';
import 'package:bakid/fitur/auth/splash_screen.dart';
import 'package:bakid/fitur/guru/dashboard/guru_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final authState = ref.watch(authStateProvider);

    // Prioritaskan currentUser langsung jika ada
    if (currentUser != null) {
      return _buildDashboard(currentUser);
    }

    return authState.when(
      loading: () => const SplashScreen(child: SizedBox()),
      error: (error, _) => LoginScreen(error: error.toString()),
      data: (user) {
        if (user == null) return const LoginScreen();
        return _buildDashboard(user);
      },
    );
  }

  Widget _buildDashboard(Map<String, dynamic> user) {
    final role = user['peran']?.toString().toLowerCase();

    switch (role) {
      case 'admin':
        return const AdminDashboard();
      case 'guru':
        return const GuruDashboard();
      default:
        return LoginScreen(error: 'Role tidak valid: $role');
    }
  }
}
