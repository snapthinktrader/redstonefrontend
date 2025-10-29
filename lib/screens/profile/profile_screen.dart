import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';
import '../settings/change_password_screen.dart';
import '../settings/two_factor_screen.dart';
import '../settings/about_redstone_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoadingUser = true;
  User? _currentUser;
  final AuthService _authService = AuthService();
  int _selectedIndex = 3; // Settings tab is selected
  
  // Dynamic settings from backend
  Map<String, dynamic>? _userSettings;
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadSettings();
  }

  Future<void> _loadUserData() async {
    try {
      // Refresh user data from API to get latest earnings
      await _authService.refreshUserFromAPI();
      
      // Then load the updated data from storage
      final user = await _authService.getUser();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Try loading from storage anyway
      try {
        final user = await _authService.getUser();
        if (mounted) {
          setState(() {
            _currentUser = user;
            _isLoadingUser = false;
          });
        }
      } catch (e2) {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
          });
        }
      }
    }
  }

  Future<void> _loadSettings() async {
    try {
      final settingsResponse = await _authService.getSettings();
      if (mounted && settingsResponse['success'] == true) {
        setState(() {
          _userSettings = settingsResponse['data'];
          _isLoadingSettings = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _isLoadingSettings = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _userSettings?['notificationSettings']?['push'] = value;
    });

    try {
      final response = await _authService.updateNotificationSettings(
        push: value,
      );

      if (mounted && response['success'] != true) {
        // Revert on error
        setState(() {
          _userSettings?['notificationSettings']?['push'] = !value;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update notifications'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _userSettings?['notificationSettings']?['push'] = !value;
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
          'Profile & Settings',
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
              Icons.edit,
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
                      // User Profile Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppTheme.secondaryColor,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: AppTheme.primaryColor,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _currentUser?.fullName ?? 'No Name',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _currentUser?.email ?? 'No Email',
                                        style: TextStyle(
                                          color: AppTheme.mediumColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          // Deposit Level
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppTheme.primaryColor,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.diamond, color: Colors.white, size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _currentUser?.levelName ?? 'Basic',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          // Referral Level
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.group, color: Colors.white, size: 12),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _currentUser?.referralLevelName ?? 'Level 1',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem('Joined', _currentUser?.joinedTimeAgo ?? 'Unknown'),
                                _buildStatItem('Total Earned', '\$${(_currentUser?.actualTotalEarnings ?? 0.0).toStringAsFixed(2)}', isEarnings: true),
                                _buildStatItem('Referrals', '${_currentUser?.totalReferrals ?? 0}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                
                const SizedBox(height: 24),
                
                // Settings List
                Container(
                  decoration: AppTheme.cardDecoration,
                  child: Column(
                    children: [
                      _buildSettingItem(
                        Icons.lock_outline,
                        'Change Password',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.security,
                        'Two-Factor Authentication',
                        subtitle: _currentUser?.twoFactorEnabled == true
                            ? 'Enabled'
                            : 'Disabled',
                        onTap: () {
                          if (_currentUser != null) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TwoFactorScreen(user: _currentUser!),
                              ),
                            ).then((_) {
                              // Reload user data when returning
                              _loadUserData();
                            });
                          }
                        },
                      ),
                      _buildSettingItem(
                        Icons.notifications_outlined,
                        'Notifications',
                        hasSwitch: true,
                        switchValue: _userSettings?['notificationSettings']?['push'] ?? true,
                        onSwitchChanged: _toggleNotifications,
                      ),
                      _buildSettingItem(
                        Icons.email_outlined,
                        'Email Notifications',
                        hasSwitch: true,
                        switchValue: _userSettings?['notificationSettings']?['email'] ?? true,
                        onSwitchChanged: (value) async {
                          setState(() {
                            _userSettings?['notificationSettings']?['email'] = value;
                          });
                          await _authService.updateNotificationSettings(email: value);
                        },
                      ),
                      _buildSettingItem(
                        Icons.help_outline,
                        'Help & Support',
                        onTap: () {
                          // TODO: Navigate to help & support
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Contact support@redstone.com for assistance'),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.info_outline,
                        'About RedStone',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AboutRedStoneScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingItem(
                        Icons.logout,
                        'Logout',
                        isDestructive: true,
                        isLast: true,
                        onTap: () {
                          _showLogoutDialog();
                        },
                      ),
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
              context.push('/referrals');
              break;
            case 3:
              // Already on profile
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
  
  Widget _buildStatItem(String label, String value, {bool isEarnings = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.mediumColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isEarnings ? AppTheme.primaryColor : AppTheme.darkColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSettingItem(
    IconData icon,
    String title, {
    String? subtitle,
    bool hasSwitch = false,
    bool switchValue = false,
    ValueChanged<bool>? onSwitchChanged,
    VoidCallback? onTap,
    bool isDestructive = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: ListTile(
        onTap: hasSwitch ? null : onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.lightColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            color: AppTheme.mediumColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.red : AppTheme.darkColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: AppTheme.mediumColor,
                  fontSize: 12,
                ),
              )
            : null,
        trailing: hasSwitch
            ? Switch(
                value: switchValue,
                onChanged: onSwitchChanged,
                activeColor: AppTheme.primaryColor,
              )
            : const Icon(
                Icons.chevron_right,
                color: AppTheme.mediumColor,
              ),
      ),
    );
  }
  
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Perform logout and navigate to login
                context.go('/login');
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}