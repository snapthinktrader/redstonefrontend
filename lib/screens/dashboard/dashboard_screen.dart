import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/shared_layout.dart';
import '../../widgets/loading_state_manager.dart';
import '../../services/auth_service.dart';
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
  
  // Real data from API
  double _currentBalance = 0.0;
  double _totalDeposits = 0.0;
  double _dailyEarnings = 0.0;
  int _userLevel = 1;
  Map<String, dynamic>? _userStats;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user data and stats in parallel
      final futures = await Future.wait([
        _authService.getUser(),
        _loadUserStats(),
      ]);
      
      final user = futures[0] as User?;
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
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

  Future<void> _loadUserStats() async {
    try {
      // Temporarily disable API call to avoid route not found error
      // const dashboardData = await _apiService.getUserStats();
      
      if (mounted) {
        setState(() {
          // _userStats = dashboardData;
          _isLoadingStats = false;
          // Use default values for now
          _currentBalance = 0.0;
          _totalDeposits = 0.0;
          _dailyEarnings = 0.0;
          _userLevel = 1;
        });
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
    return Row(
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
        const SizedBox(width: 16),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.star_outline,
            title: 'Level',
            value: _userLevel.toString(),
          ),
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
    // Get earnings data from stats or use default
    final earningsData = _userStats?['weeklyEarnings'] as List<dynamic>? ?? 
        [0.3, 0.5, 0.7, 0.6, 0.9, 0.4, 0.8]; // Default chart data
    
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Last 7 Days Earnings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              Icon(
                Icons.bar_chart,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Simple bar chart
          Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: earningsData.asMap().entries.map((entry) {
                double value = (entry.value is num) ? entry.value.toDouble() : 0.3;
                return _buildChartBar(value);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartBar(double heightFactor) {
    return Container(
      width: 32,
      height: 120 * heightFactor,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
    );
  }
}