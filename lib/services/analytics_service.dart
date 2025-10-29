import 'package:flutter/foundation.dart';

/// AnalyticsService - Lightweight stub that replaces FirebaseService
/// Provides the same API surface but does not depend on Firebase.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  static AnalyticsService get instance => _instance;
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Initialize the analytics service (no-op)
  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint('AnalyticsService: initialize (no-op)');
    _isInitialized = true;
  }

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    debugPrint('Analytics event: $name, params: ${parameters ?? {}}');
  }

  Future<void> logScreenView(String screenName) async {
    debugPrint('Screen view: $screenName');
  }

  Future<void> logSignup({required String method, String? referralCode}) async {
    await logEvent('sign_up', parameters: {
      'method': method,
      if (referralCode != null) 'referral_code': referralCode,
    });
  }

  Future<void> logLogin({required String method}) async {
    await logEvent('login', parameters: {'method': method});
  }

  Future<void> logReferralShare({required String method, required String referralCode}) async {
    await logEvent('share_referral', parameters: {
      'method': method,
      'referral_code': referralCode,
    });
  }

  Future<void> logReferralConversion({required String referralCode, required String newUserId}) async {
    await logEvent('referral_conversion', parameters: {
      'referral_code': referralCode,
      'new_user_id': newUserId,
    });
  }

  Future<void> setUserProperties({required String userId, String? userLevel, double? totalEarnings}) async {
    debugPrint('Set user properties for $userId: level=$userLevel earnings=$totalEarnings');
  }
}
