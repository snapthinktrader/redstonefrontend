import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/app_theme.dart';

class SharedLayout extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  final bool showBottomNav;

  const SharedLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.showBottomNav = true,
  });

  @override
  State<SharedLayout> createState() => _SharedLayoutState();
}

class _SharedLayoutState extends State<SharedLayout>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Start animation immediately
    _fadeController.forward();
  }

  @override
  void didUpdateWidget(SharedLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentRoute != widget.currentRoute) {
      // Quick fade transition when route changes
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: widget.child,
      ),
      bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null,
    );
  }

  Widget _buildBottomNav() {
    final currentIndex = _getCurrentIndex();
    
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Referrals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex() {
    switch (widget.currentRoute) {
      case '/dashboard':
        return 0;
      case '/wallet':
      case '/deposit':
      case '/withdraw':
        return 1;
      case '/referrals':
        return 2;
      case '/profile':
        return 3;
      default:
        return 0;
    }
  }

  void _onNavTap(int index) {
    // Prevent navigation if already on the same route
    final targetRoute = _getRouteForIndex(index);
    if (widget.currentRoute == targetRoute) return;

    // Use pushReplacement for smoother transitions
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/wallet');
        break;
      case 2:
        context.go('/referrals');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  String _getRouteForIndex(int index) {
    switch (index) {
      case 0:
        return '/dashboard';
      case 1:
        return '/wallet';
      case 2:
        return '/referrals';
      case 3:
        return '/profile';
      default:
        return '/dashboard';
    }
  }
}