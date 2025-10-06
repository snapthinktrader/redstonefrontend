import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../models/transaction.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  int _selectedIndex = 1; // Wallet tab is selected
  bool _isLoadingUser = true;
  bool _isLoadingTransactions = true;
  User? _currentUser;
  List<Transaction> _transactions = [];
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserData(),
      _loadTransactions(),
    ]);
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await _authService.getUserTransactions();
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _isLoadingTransactions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mediumColor),
          onPressed: () => context.go('/dashboard'),
        ),
        title: const Text(
          'Wallet',
          style: TextStyle(
            color: AppTheme.darkColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.lightColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.add,
              color: AppTheme.mediumColor,
              size: 18,
            ),
          ),
        ],
      ),
      body: _isLoadingUser
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                      Colors.white,
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Balance Overview Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Available Balance',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.mediumColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\$${(_currentUser?.walletBalance ?? 0.0).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: CustomButton(
                                    text: 'Deposit',
                                    icon: Icons.download,
                                    onPressed: () => context.go('/deposit'),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: CustomButton(
                                    text: 'Withdraw',
                                    icon: Icons.upload,
                                    isOutlined: true,
                                    onPressed: () => context.go('/withdraw'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Transaction History
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Transaction History',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.darkColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Filter functionality
                                  },
                                  child: const Text('Filter'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Transaction Items
                            if (_isLoadingTransactions)
                              const Center(
                                child: CircularProgressIndicator(color: AppTheme.primaryColor),
                              )
                            else if (_transactions.isEmpty)
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.receipt_long,
                                      size: 48,
                                      color: AppTheme.mediumColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No transactions yet',
                                      style: TextStyle(
                                        color: AppTheme.mediumColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._transactions.asMap().entries.map((entry) {
                                final index = entry.key;
                                final transaction = entry.value;
                                return _buildTransactionItem(
                                  transaction.typeDisplayName,
                                  transaction.description,
                                  transaction.formattedAmount,
                                  transaction.timeAgo,
                                  transaction.icon,
                                  transaction.isCredit,
                                  isLast: index == _transactions.length - 1,
                                );
                              }).toList(),
                            
                            if (_transactions.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    // Load more functionality
                                  },
                                  child: const Text('Load More Transactions'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                
                const SizedBox(height: 100), // Bottom padding for navigation
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              // Already on wallet
              break;
            case 2:
              context.go('/referrals');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Referrals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransactionItem(
    String title,
    String subtitle,
    String amount,
    String time,
    IconData icon,
    bool isPositive, {
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPositive ? AppTheme.secondaryColor : AppTheme.lightColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isPositive ? AppTheme.primaryColor : AppTheme.mediumColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.mediumColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: isPositive ? AppTheme.primaryColor : AppTheme.darkColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  color: AppTheme.mediumColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}