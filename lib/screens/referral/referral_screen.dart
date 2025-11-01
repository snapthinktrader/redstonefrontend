import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../services/dynamic_link_service.dart';
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
  bool _isGeneratingLink = false;
  User? _currentUser;
  List<Referral> _referrals = [];
  final AuthService _authService = AuthService();
  Timer? _realtimeTimer;
  double _realtimeEarningsOffset = 0.0; // Tracks total real-time earnings increase
  Map<String, double> _referralOffsets = {}; // Tracks each referral's individual offset

  @override
  void initState() {
    super.initState();
    _loadData();
    _startRealtimeTimer();
  }

  @override
  void dispose() {
    _realtimeTimer?.cancel();
    super.dispose();
  }

  void _startRealtimeTimer() {
    // Update earnings every second
    _realtimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Calculate total commission per second from all referrals
          double totalCommissionPerSecond = 0;
          for (var referral in _referrals) {
            final commissionPerSecond = referral.myDailyCommission / 86400;
            totalCommissionPerSecond += commissionPerSecond;
            
            // Track individual referral's offset
            _referralOffsets[referral.id] = (_referralOffsets[referral.id] ?? 0) + commissionPerSecond;
          }
          _realtimeEarningsOffset += totalCommissionPerSecond;
        });
      }
    });
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

  Future<void> _shareReferralLink() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load user data'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingLink = true;
    });

    try {
      await DynamicLinkService.instance.shareReferralLink(
        referralCode: _currentUser!.referralCode ?? '',
        referrerName: _currentUser!.fullName,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referral link shared successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share link: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingLink = false;
        });
      }
    }
  }

  Future<void> _copyReferralLink() async {
    if (_currentUser == null) return;

    setState(() {
      _isGeneratingLink = true;
    });

    try {
      final link = await DynamicLinkService.instance.generateReferralLink(
        referralCode: _currentUser!.referralCode ?? '',
        referrerName: _currentUser!.fullName,
      );
      
      await Clipboard.setData(ClipboardData(text: link));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Referral link copied to clipboard!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy link: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingLink = false;
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
                              text: _isGeneratingLink ? 'Generating Link...' : 'Share Referral Link',
                              icon: Icons.share,
                              onPressed: _isGeneratingLink ? null : _shareReferralLink,
                              isLoading: _isGeneratingLink,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _shareReferralCode,
                                    icon: const Icon(
                                      Icons.copy,
                                      size: 18,
                                      color: AppTheme.primaryColor,
                                    ),
                                    label: const Text(
                                      'Copy Code',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.primaryColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isGeneratingLink ? null : _copyReferralLink,
                                    icon: const Icon(
                                      Icons.link,
                                      size: 18,
                                      color: AppTheme.primaryColor,
                                    ),
                                    label: const Text(
                                      'Copy Link',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppTheme.primaryColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
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
                                _buildStatItem('Commission Earned', '\$${((_currentUser?.pendingReferralCommission ?? 0.0) + _realtimeEarningsOffset).toStringAsFixed(2)}'),
                                _buildStatItem('Indirect', '${_currentUser?.indirectReferrals ?? 0}'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Commission Rates
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '${_currentUser?.referralLevelName ?? "Level 1"}',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Column(
                                        children: [
                                          Text(
                                            'Direct Commission',
                                            style: TextStyle(
                                              color: AppTheme.darkColor.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(_currentUser?.commissionRate ?? 0.0) * 100}%',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        children: [
                                          Text(
                                            'Indirect Commission',
                                            style: TextStyle(
                                              color: AppTheme.darkColor.withOpacity(0.6),
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${(_currentUser?.indirectCommissionRate ?? 0.0) * 100}%',
                                            style: TextStyle(
                                              color: AppTheme.primaryColor,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
                                // Calculate lifetime earnings using individual offset
                                final realtimeLifetimeEarnings = referral.myLifetimeEarnings + (_referralOffsets[referral.id] ?? 0);
                                // Calculate real-time daily commission (increases as their balance grows)
                                final realtimeDailyCommission = referral.myDailyCommission + ((_referralOffsets[referral.id] ?? 0) * 86400);
                                
                                return _buildReferralItem(
                                  referral.fullName,
                                  'Level ${referral.level} - ${referral.trackLabel} • ${referral.joinedTimeAgo}',
                                  '\$${realtimeDailyCommission.toStringAsFixed(2)}/day',
                                  'Lifetime Earned: \$${realtimeLifetimeEarnings.toStringAsFixed(2)}',
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
    String myDailyCommission,
    String theirDailyEarnings, {
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
                myDailyCommission,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                theirDailyEarnings,
                style: TextStyle(
                  color: AppTheme.mediumColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}