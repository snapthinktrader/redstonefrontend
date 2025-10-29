import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../utils/app_theme.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../services/dynamic_link_service.dart';
import '../../models/referral_data.dart';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String? _referrerName;
  StreamSubscription<ReferralData>? _referralSubscription;
  late AuthService _authService;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _setupDeepLinkListener();
    _checkFingerprintMatch();
  }

  Future<void> _checkFingerprintMatch() async {
    try {
      final fingerprint = await _collectFingerprint();
      
      // Check if this fingerprint matches any existing referrer
      final response = await http.post(
        Uri.parse('https://redstonebackend.onrender.com/api/referral/find-match'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'fingerprint': fingerprint}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['match_found'] == true) {
          if (mounted) {
            setState(() {
              _referralCodeController.text = data['referral_code'] ?? '';
              _referrerName = data['referrer_name'];
            });
            
            debugPrint('✅ Fingerprint match found! Confidence: ${data['confidence']}%');
            debugPrint('   Referral Code: ${data['referral_code']}');
            debugPrint('   Referrer: ${data['referrer_name']}');
          }
        } else {
          debugPrint('ℹ️ No fingerprint match found');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking fingerprint match: $e');
      // Silently fail - user can still enter referral code manually
    }
  }

  // Collect device fingerprint (optimized per fingerprintchat.txt)
  Future<Map<String, dynamic>> _collectFingerprint() async {
    final Map<String, dynamic> fingerprint = {};
    
    try {
      // PRIORITY 1: Platform/OS (Most Reliable) - fingerprintchat.txt
      fingerprint['platform'] = 'android'; // Explicit platform identification
      
      // Enhanced User Agent with Android identifier
      final osVersion = Platform.operatingSystemVersion;
      fingerprint['user_agent'] = 'Mozilla/5.0 (Linux; Android $osVersion) RedStone Mobile App';
      
      // PRIORITY 2: Timezone (Extremely Stable) - fingerprintchat.txt
      // Use proper IANA timezone format
      try {
        fingerprint['timezone'] = DateTime.now().timeZoneName; // Should give IANA format
        debugPrint('🌍 Timezone (IANA): ${fingerprint['timezone']}');
      } catch (e) {
        fingerprint['timezone'] = 'Asia/Kolkata'; // Fallback for India
        debugPrint('⚠️ Timezone fallback: ${fingerprint['timezone']}');
      }
      
      // PRIORITY 3: Language Primary Code (Stable) - fingerprintchat.txt  
      // Ensure consistent format for comparison
      try {
        final locale = Platform.localeName; // e.g., "en_IN" or "hi_IN"
        fingerprint['language'] = locale.replaceAll('_', '-'); // Convert en_IN → en-IN
        debugPrint('🗣️ Language (normalized): ${fingerprint['language']}');
      } catch (e) {
        fingerprint['language'] = 'en-US'; // Fallback
        debugPrint('⚠️ Language fallback: ${fingerprint['language']}');
      }
      
      // DEVICE: Collect device id/name/model/manufacturer (important for short-circuit)
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final info = await deviceInfo.androidInfo;
          fingerprint['device_id'] = info.id ?? info.fingerprint ?? null;
          fingerprint['device_name'] = info.device ?? info.product ?? info.model ?? null;
          fingerprint['device_model'] = info.model ?? null;
          fingerprint['device_manufacturer'] = info.manufacturer ?? null;
          fingerprint['product'] = info.product ?? null;
          fingerprint['os_version'] = info.version.release ?? null;
          debugPrint('📱 Device (Android): ${fingerprint['device_name']} / ${fingerprint['device_model']}');
        } else if (Platform.isIOS) {
          final info = await deviceInfo.iosInfo;
          fingerprint['device_id'] = info.identifierForVendor ?? null;
          fingerprint['device_name'] = info.name ?? info.model ?? null;
          fingerprint['device_model'] = info.model ?? null;
          fingerprint['device_manufacturer'] = 'Apple';
          fingerprint['product'] = info.utsname.machine ?? null;
          fingerprint['os_version'] = info.systemVersion ?? null;
          debugPrint('📱 Device (iOS): ${fingerprint['device_name']} / ${fingerprint['device_model']}');
        }
      } catch (e) {
        debugPrint('⚠️ Could not collect device info: $e');
      }

      // LOW PRIORITY: IP Address (Bonus only) - fingerprintchat.txt
      try {
        final ipResponse = await http.get(Uri.parse('https://api.ipify.org?format=json'));
        if (ipResponse.statusCode == 200) {
          final ipData = json.decode(ipResponse.body);
          fingerprint['ip'] = ipData['ip'];
          debugPrint('📡 IP Address: ${ipData['ip']}');
        }
      } catch (e) {
        debugPrint('⚠️ Could not fetch IP: $e');
        fingerprint['ip'] = 'unknown';
      }
      
      // IGNORED (per fingerprintchat.txt):
      // ❌ GPU: "Browser and native app report this differently" 
      // ❌ Screen Resolution: "Browser viewport ≠ mobile screen"
      // These are not included to avoid false negatives
      
      debugPrint('🔍 ENHANCED Fingerprint Collection (fingerprintchat.txt optimized):');
      debugPrint('   ✅ Platform: ${fingerprint['platform']} (Most Reliable)');
      debugPrint('   ✅ User Agent: ${fingerprint['user_agent']}');
      debugPrint('   ✅ Timezone: ${fingerprint['timezone']} (Extremely Stable)');
      debugPrint('   ✅ Language: ${fingerprint['language']} (Stable)');
      debugPrint('   ⚡ IP: ${fingerprint['ip']} (Bonus only)');
      debugPrint('   🚫 GPU/Resolution: Ignored (unreliable between web/mobile)');
      
    } catch (e) {
      debugPrint('❌ Error collecting fingerprint: $e');
    }
    
    return fingerprint;
  }

  void _setupDeepLinkListener() {
    // Listen for referral data from deep links
    _referralSubscription = DynamicLinkService.instance.referralDataStream.listen(
      (referralData) {
        if (referralData.isValid && mounted) {
          setState(() {
            _referralCodeController.text = referralData.referralCode;
            _referrerName = referralData.referrerName;
          });
          
          // Show a snackbar to inform user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(referralData.displayMessage),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 3),
            ),
          );
          
          print('✅ Referral code auto-filled: ${referralData.referralCode}');
        }
      },
      onError: (error) {
        print('❌ Error receiving referral data: $error');
      },
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralCodeController.dispose();
    _referralSubscription?.cancel();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signup(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        referralCode: _referralCodeController.text.trim().isEmpty
            ? null
            : _referralCodeController.text.trim(),
      );

      if (mounted) {
        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppTheme.successColor,
            ),
          );
          context.go('/email-verification/${_emailController.text.trim()}');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textPrimary),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // First Name Field
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _firstNameController,
                        labelText: 'First Name',
                        prefixIcon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    CustomTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textPrimary.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Confirm Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppTheme.textPrimary.withOpacity(0.6),
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Referral Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Referral Code (Optional)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      if (_referrerName != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: AppTheme.successColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Referred by $_referrerName',
                                style: const TextStyle(
                                  color: AppTheme.successColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      CustomTextField(
                        controller: _referralCodeController,
                        label: 'Enter referral code',
                        prefixIcon: const Icon(Icons.card_giftcard),
                        enabled: _referrerName == null, // Disable if auto-filled from deep link
                        validator: (value) {
                          // Referral code is optional
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Terms and Conditions
                Row(
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      onChanged: (value) {
                        setState(() {
                          _acceptedTerms = value ?? false;
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptedTerms = !_acceptedTerms;
                          });
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: const TextStyle(color: AppTheme.textPrimary),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Sign Up Button
                CustomButton(
                  text: 'Create Account',
                  onPressed: _isLoading ? null : _signup,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 24),
                
                // Already have account
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        'Sign In',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}