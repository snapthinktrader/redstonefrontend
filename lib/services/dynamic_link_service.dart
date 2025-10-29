import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../models/referral_data.dart';
import 'analytics_service.dart';

/// Dynamic Link Service - Handles referral link generation and sharing
/// Now uses direct URLs to admin panel instead of Firebase Dynamic Links
class DynamicLinkService {
  static final DynamicLinkService _instance = DynamicLinkService._internal();
  static DynamicLinkService get instance => _instance;
  factory DynamicLinkService() => _instance;
  DynamicLinkService._internal();

  // Landing page URL where users will be directed
  static const String _landingPageUrl = 'https://redstone-admin.vercel.app';
  
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  
  // Stream controller for deep link data
  final StreamController<ReferralData> _referralDataController = 
      StreamController<ReferralData>.broadcast();
  
  /// Stream of referral data from deep links
  Stream<ReferralData> get referralDataStream => _referralDataController.stream;

  /// Initialize service (no-op now that Firebase is removed)
  Future<void> initialize() async {
    debugPrint('✅ DynamicLinkService initialized (direct URL mode)');
    await _analyticsService.initialize();
  }

  /// Dispose stream controller
  void dispose() {
    _referralDataController.close();
  }

  /// Generate referral link pointing to admin panel homepage
  Future<String> generateReferralLink({
    required String referralCode,
    required String referrerName,
  }) async {
    try {
      debugPrint('🔗 Generating referral link for: $referralCode');

      // Create direct URL to admin panel homepage with referral parameters
      final String url = '$_landingPageUrl?'
          'ref_code=$referralCode&'
          'referrer_name=${Uri.encodeComponent(referrerName)}&'
          'screen=signup';

      debugPrint('✅ Generated referral link: $url');

      // Log analytics
      await _analyticsService.logEvent('referral_link_generated', parameters: {
        'referral_code': referralCode,
        'referrer_name': referrerName,
      });

      return url;
    } catch (e) {
      debugPrint('❌ Error generating referral link: $e');
      
      // Fallback to basic URL
      final fallbackUrl = '$_landingPageUrl?'
          'ref_code=$referralCode&'
          'referrer_name=${Uri.encodeComponent(referrerName)}&'
          'screen=signup';
      
      debugPrint('Using fallback URL: $fallbackUrl');
      return fallbackUrl;
    }
  }

  /// Share referral link via system share dialog
  Future<void> shareReferralLink({
    required String referralCode,
    required String referrerName,
  }) async {
    try {
      debugPrint('📤 Sharing referral link...');

      // Generate the link
      final String link = await generateReferralLink(
        referralCode: referralCode,
        referrerName: referrerName,
      );

      // Create share message
      final String message = 
          '🚀 Join me on RedStone and earn 2% daily returns!\n\n'
          'I\'m $referrerName and I\'ve been earning consistently. '
          'Use my referral code: $referralCode\n\n'
          'Download the app here:\n$link';

      // Share using system share dialog
      await Share.share(
        message,
        subject: 'Join RedStone - Referral from $referrerName',
      );

      // Log share event
      await _analyticsService.logReferralShare(
        method: 'system_share',
        referralCode: referralCode,
      );
      debugPrint('✅ Referral link shared successfully');
    } catch (e) {
      debugPrint('❌ Error sharing referral link: $e');
      rethrow;
    }
  }

  /// Copy referral link to clipboard
  Future<String> getReferralLinkForCopy({
    required String referralCode,
    required String referrerName,
  }) async {
    return await generateReferralLink(
      referralCode: referralCode,
      referrerName: referrerName,
    );
  }
}
