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
import 'screens/wallet/pending_deposits_screen.dart';
import 'screens/referral/referral_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'utils/app_theme.dart';
import 'utils/storage_helper.dart';
import 'utils/performance_optimizer.dart';
import 'screens/auth_guard.dart';
import 'services/analytics_service.dart';
import 'services/dynamic_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage before running the app
  final storageHelper = StorageHelper();
  await storageHelper.init();
  
  // Initialize analytics (replaces Firebase)
  try {
    await AnalyticsService.instance.initialize();
    print('✅ AnalyticsService initialized (Firebase removed)');

    // Initialize Dynamic Link Service (no-op initialize kept)
    await DynamicLinkService.instance.initialize();
    print('✅ Dynamic Link Service initialize() called');
  } catch (e) {
    print('⚠️ Analytics/DynamicLink initialization error: $e');
    print('App will continue without Firebase features');
  }
  
  // Set performance mode based on device capabilities
  AppPerformanceSettings.setHighPerformanceMode();
  
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
          pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const SplashScreen(),
          ),
        ),
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const LoginScreen(),
          ),
        ),
        GoRoute(
          path: '/signup',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const SignupScreen(),
          ),
        ),
        GoRoute(
          path: '/email-verification/:email',
          pageBuilder: (context, state) {
            final email = state.pathParameters['email'] ?? '';
            return _buildPageWithTransition(
              context, state, EmailVerificationScreen(email: email),
            );
          },
        ),
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const AuthGuard(child: DashboardScreen()),
          ),
        ),
        GoRoute(
          path: '/wallet',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const AuthGuard(child: WalletScreen()),
          ),
        ),
        GoRoute(
          path: '/deposit',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const AuthGuard(child: DepositScreen()),
          ),
        ),
        GoRoute(
          path: '/withdraw',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const AuthGuard(child: WithdrawScreen()),
          ),
        ),
        GoRoute(
          path: '/pending-deposits',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const AuthGuard(child: PendingDepositsScreen()),
          ),
        ),
        GoRoute(
          path: '/referrals',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const AuthGuard(child: ReferralScreen()),
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => _buildPageWithTransition(
            context, state, const AuthGuard(child: ProfileScreen()),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'RedStone',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      // Add builder to wrap the entire app with optimizations
      builder: (context, child) {
        return MediaQuery(
          // Disable animations on low-end devices for better performance
          data: MediaQuery.of(context).copyWith(
            textScaleFactor: 1.0, // Prevent text scaling issues
          ),
          child: child ?? Container(),
        );
      },
    );
  }

  // Custom page transition builder for smooth animations
  Page<void> _buildPageWithTransition(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: PerformanceOptimizer(child: child),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (!AppPerformanceSettings.enableTransitions) {
          return child;
        }

        // Use slide transition for better performance than fade
        const begin = Offset(0.1, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutQuart;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: AppPerformanceSettings.transitionDuration,
    );
  }
}