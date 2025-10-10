import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../../models/referral.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  int _selectedIndex = 2; // Referrals tab is selected
  bool _isLoadingUser = true;
  bool _isLoadingReferrals = true;
  User? _currentUser;
  List<Referral> _referrals = [];
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUserData(),
      _loadReferrals(),
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

  Future<void> _loadReferrals() async {
    try {
      final referrals = await _authService.getUserReferrals();
      if (mounted) {
        setState(() {
          _referrals = referrals;
          _isLoadingReferrals = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReferrals = false;
        });
      }
    }
  }

  void _shareReferralCode() {
    final referralCode = _currentUser?.referralCode ?? 'REDSTONE123';
    Clipboard.setData(ClipboardData(text: referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied to clipboard!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
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
          onPressed: () => Navigator.of(context).canPop() 
              ? Navigator.of(context).pop() 
              : context.go('/dashboard'),
        ),
        title: const Text(
          'My Referrals',
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
              Icons.info_outline,
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
                      // Referral Code Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          children: [
                            Text(
                              'Your Referral Code',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.darkColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                              decoration: BoxDecoration(
                                color: AppTheme.secondaryColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _currentUser?.referralCode ?? 'REDSTONE123',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CustomButton(
                              text: 'Share Code',
                              icon: Icons.share,
                              onPressed: _shareReferralCode,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Referral Stats
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('Direct Referrals', '${_currentUser?.directReferrals ?? 0}'),
                                _buildStatItem('Total Earnings', '\$${(_currentUser?.totalEarnings ?? 0.0).toStringAsFixed(2)}'),
                                _buildStatItem('Indirect', '${_currentUser?.indirectReferrals ?? 0}'),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Next Bonus: \$${_currentUser?.nextBonusAmount ?? 100}',
                                      style: TextStyle(
                                        color: AppTheme.darkColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      '${_currentUser?.directReferrals ?? 0}/${_currentUser?.nextBonusTarget ?? 10} referrals',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: (_currentUser?.directReferrals ?? 0) / (_currentUser?.nextBonusTarget ?? 10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Referral Network List
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
                                  'Your Network',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: AppTheme.darkColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // View all functionality
                                  },
                                  child: const Text('View All'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // Referral Items
                            if (_isLoadingReferrals)
                              const Center(
                                child: CircularProgressIndicator(color: AppTheme.primaryColor),
                              )
                            else if (_referrals.isEmpty)
                              Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.group_add,
                                      size: 48,
                                      color: AppTheme.mediumColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No referrals yet',
                                      style: TextStyle(
                                        color: AppTheme.mediumColor,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Share your referral code to start earning',
                                      style: TextStyle(
                                        color: AppTheme.mediumColor,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              )
                            else
                              ..._referrals.asMap().entries.map((entry) {
                                final index = entry.key;
                                final referral = entry.value;
                                return _buildReferralItem(
                                  referral.fullName,
                                  'Level ${referral.level} • Joined ${referral.joinedTimeAgo}',
                                  '+\$${referral.earnings.toStringAsFixed(2)}',
                                  'Deposit: \$${referral.totalDeposit.toStringAsFixed(2)}',
                                  isLast: index == _referrals.length - 1,
                                );
                              }).toList(),
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
              context.push('/wallet');
              break;
            case 2:
              // Already on referrals
              break;
            case 3:
              context.push('/profile');
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
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.mediumColor,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildReferralItem(
    String name,
    String subtitle,
    String earnings,
    String deposit, {
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
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.person,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
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
                earnings,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                deposit,
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