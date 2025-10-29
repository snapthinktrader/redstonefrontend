import 'package:shared_preferences/shared_preferences.dart';

class Config {
  // Backend URL - Using stable production domain that never changes!
  static const String _newDeploymentUrl = 'https://red-stone-backend.vercel.app/api';
  static const String _fallbackUrl = 'https://redstonebackend-6to7wmy13-snaps-projects-656f28bb.vercel.app/api';
  static const String _configKey = 'cached_backend_url';
  static const String _lastUpdateKey = 'config_last_update';
  
  static String? _cachedUrl;
  
  /// Get backend URL with smart fallback
  static Future<String> getBaseUrl() async {
    // Return cached URL if available
    if (_cachedUrl != null) {
      return _cachedUrl!;
    }
    
    // Check build-time environment variable first
    const buildTimeUrl = String.fromEnvironment('API_BASE_URL');
    if (buildTimeUrl.isNotEmpty) {
      _cachedUrl = buildTimeUrl;
      return buildTimeUrl;
    }
    
    // Try to get cached URL from local storage
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString(_configKey);
    
    if (cachedUrl != null) {
      _cachedUrl = cachedUrl;
      return cachedUrl;
    }
    
    // Use the latest deployment URL first, then fallback
    _cachedUrl = _newDeploymentUrl;
    return _newDeploymentUrl;
  }
  
  /// Legacy sync method for backward compatibility - now uses stable URL!
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://red-stone-backend.vercel.app/api',
  );
  
  /// Update backend URL at runtime (for future use)
  static Future<void> updateBackendUrl(String newUrl) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, newUrl);
    await prefs.setInt(_lastUpdateKey, DateTime.now().millisecondsSinceEpoch);
    _cachedUrl = newUrl;
  }
  
  /// Get current configuration status
  static Future<Map<String, dynamic>> getConfigStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString(_configKey);
    final lastUpdate = prefs.getInt(_lastUpdateKey);
    
    return {
      'current_url': await getBaseUrl(),
      'cached_url': cachedUrl,
      'fallback_url': _fallbackUrl,
      'build_time_url': String.fromEnvironment('API_BASE_URL'),
      'last_update': lastUpdate != null ? DateTime.fromMillisecondsSinceEpoch(lastUpdate) : null,
    };
  }
  
  // App configuration
  static const String appName = 'RedStone Investment';
  static const String appVersion = '1.0.0';
  
  // API endpoints
  static const String authLogin = '/auth/login';
  static const String authSignup = '/auth/signup';
  static const String authRefresh = '/auth/refresh-token';
  static const String userProfile = '/user/profile';
  static const String userDashboard = '/user/dashboard';
  static const String transactions = '/transaction';
  static const String referrals = '/referral';
  
  // For development/debugging
  static bool get isProduction => baseUrl.contains('vercel.app');
  static bool get isDevelopment => !isProduction;
}