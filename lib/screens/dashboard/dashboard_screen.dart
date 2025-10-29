import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/shared_layout.dart';
import '../../widgets/loading_state_manager.dart';
import '../../widgets/earnings_projection_chart.dart';
import '../../services/auth_service.dart';
import '../../services/realtime_earnings_service.dart';
import '../../models/user.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  User? _currentUser;
  bool _isLoading = true;
  bool _isLoadingStats = true;
  final AuthService _authService = AuthService();
  final RealTimeEarningsService _earningsService = RealTimeEarningsService();
  Timer? _realtimeTimer;
  
  // Real data from API
  double _currentBalance = 0.0;
  double _totalDeposits = 0.0;
  double _dailyEarnings = 0.0;
  int _userLevel = 1;
  int _userReferralLevel = 1;
  Map<String, dynamic>? _userStats;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _realtimeTimer?.cancel();
    _earningsService.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // Load fresh user data from API (not cache)
      await _authService.refreshUserFromAPI();
      
      // Then get the updated user
      final user = await _authService.getUser();
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
        
        // Load stats after user is set
        await _loadUserStats();
        
        // Start real-time balance updates
        _startRealtimeUpdates();
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingStats = false;
        });
      }
    }
  }
  
  void _startRealtimeUpdates() {
    if (_currentUser == null) return;
    
    // Cancel any existing timer
    _realtimeTimer?.cancel();
    
    // Update balance every second for real-time effect
    _realtimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentUser != null && mounted) {
        setState(() {
          _currentBalance = _earningsService.calculateRealTimeBalance(_currentUser!);
        });
      }
    });
  }

  Future<void> _loadUserStats() async {
    try {
      // Use _currentUser data if available
      if (_currentUser != null) {
        if (mounted) {
          setState(() {
            _currentBalance = _currentUser!.walletBalance;
            _totalDeposits = _currentUser!.totalDeposit;
            _dailyEarnings = _currentUser!.dailyEarnings;
            _userLevel = _currentUser!.currentLevel;
            _userReferralLevel = _currentUser!.referralLevel;
            _isLoadingStats = false;
          });
        }
      } else {
        // Fallback to default values if no user data
        if (mounted) {
          setState(() {
            _currentBalance = 0.0;
            _totalDeposits = 0.0;
            _dailyEarnings = 0.0;
            _userLevel = 1;
            _userReferralLevel = 1;
            _isLoadingStats = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user stats: $e');
      // Keep default values on error and stop loading
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SharedLayout(
      currentRoute: '/dashboard',
      child: LoadingStateManager(
        isLoading: _isLoading,
        loadingText: 'Loading dashboard...',
        child: _buildDashboardContent(),
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Failed to load user data'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Light gray background like HTML
      body: _buildDashboardBody(),
    );
  }

  Widget _buildDashboardBody() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Scrollable content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _isLoadingStats = true;
                });
                await _loadUserStats();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Wallet Summary Card
                    _buildWalletSummary(),
                    
                    const SizedBox(height: 24),
                    
                    // Metrics Grid
                    _buildMetricsGrid(),
                    
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    _buildActionButtons(),
                    
                    const SizedBox(height: 24),
                    
                    // Earnings Chart
                    _buildEarningsChart(),
                    
                    const SizedBox(height: 100), // Bottom padding for navigation
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // RedStone Logo
              Image.asset(
                'assets/logo/logo.png',
                height: 48,
                width: 48,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.diamond,
                    size: 48,
                    color: AppTheme.primaryColor,
                  );
                },
              ),
              const SizedBox(width: 16),
              Text(
                'RedStone',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
            color: const Color(0xFF374151),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Balance',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6B7280),
                ),
              ),
              if (_isLoadingStats)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '\$${_currentBalance.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.attach_money,
                title: 'Total Deposits',
                value: '\$${_totalDeposits.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.trending_up,
                title: 'Daily Earnings',
                value: '\$${_dailyEarnings.toStringAsFixed(2)}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.diamond,
                title: 'Deposit Level',
                value: _currentUser?.levelName ?? 'Basic',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.group,
                title: 'Referral Level',
                value: _currentUser?.referralLevelName ?? 'Level 1',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF111827),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: CustomButton(
            text: 'Deposit',
            onPressed: () => context.push('/deposit'),
            backgroundColor: AppTheme.primaryColor,
            textColor: Colors.white,
            height: 48,
            icon: Icons.add,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomButton(
            text: 'Withdraw',
            onPressed: () => context.push('/withdraw'),
            isOutlined: true,
            backgroundColor: AppTheme.primaryColor,
            textColor: AppTheme.primaryColor,
            height: 48,
            icon: Icons.remove,
          ),
        ),
      ],
    );
  }

  Widget _buildEarningsChart() {
    return EarningsProjectionChart(
      currentBalance: _currentBalance,
      dailyRate: 0.02, // 2% daily
      daysToProject: 30, // Project next 30 days
    );
  }
}