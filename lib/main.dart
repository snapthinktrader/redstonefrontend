import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/wallet/wallet_screen.dart';
import 'screens/wallet/deposit_screen.dart';
import 'screens/wallet/withdraw_screen.dart';
import 'screens/referral/referral_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: RedStoneApp(),
    ),
  );
}

class RedStoneApp extends ConsumerWidget {
  const RedStoneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/email-verification/:email',
          builder: (context, state) {
            final email = state.pathParameters['email'] ?? '';
            return EmailVerificationScreen(email: email);
          },
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const WalletScreen(),
        ),
        GoRoute(
          path: '/deposit',
          builder: (context, state) => const DepositScreen(),
        ),
        GoRoute(
          path: '/withdraw',
          builder: (context, state) => const WithdrawScreen(),
        ),
        GoRoute(
          path: '/referrals',
          builder: (context, state) => const ReferralScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'RedStone',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}