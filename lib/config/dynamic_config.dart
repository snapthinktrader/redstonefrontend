import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DynamicConfig {
  static const String _configKey = 'backend_config';
  static const String _lastUpdateKey = 'config_last_update';
  
  // Fallback URL if dynamic config fails
  static const String fallbackUrl = 'https://redstonebackend-qzyfnbktn-snaps-projects-656f28bb.vercel.app/api';
  
  // Configuration server URL (this could be a stable URL or GitHub raw file)
  static const String configUrl = 'https://raw.githubusercontent.com/yourusername/redstone-config/main/config.json';
  
  static String? _cachedBaseUrl;
  
  /// Get the current backend URL
  static Future<String> getBaseUrl() async {
    // Return cached URL if available
    if (_cachedBaseUrl != null) {
      return _cachedBaseUrl!;
    }
    
    // Try to get from local storage first
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString(_configKey);
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    // If cached and less than 1 hour old, use it
    if (cachedUrl != null && (now - lastUpdate) < 3600000) {
      _cachedBaseUrl = cachedUrl;
      return cachedUrl;
    }
    
    // Try to fetch latest config
    try {
      final url = await _fetchLatestConfig();
      if (url != null) {
        // Cache the new URL
        await prefs.setString(_configKey, url);
        await prefs.setInt(_lastUpdateKey, now);
        _cachedBaseUrl = url;
        return url;
      }
    } catch (e) {
      print('Failed to fetch latest config: $e');
    }
    
    // Return cached URL if available, otherwise fallback
    if (cachedUrl != null) {
      _cachedBaseUrl = cachedUrl;
      return cachedUrl;
    }
    
    _cachedBaseUrl = fallbackUrl;
    return fallbackUrl;
  }
  
  /// Fetch latest configuration from remote source
  static Future<String?> _fetchLatestConfig() async {
    try {
      final response = await http.get(
        Uri.parse(configUrl),
        headers: {'Cache-Control': 'no-cache'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        return config['backend_url'] as String?;
      }
    } catch (e) {
      print('Error fetching config: $e');
    }
    return null;
  }
  
  /// Force refresh the configuration
  static Future<void> refreshConfig() async {
    _cachedBaseUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
    await prefs.remove(_lastUpdateKey);
    await getBaseUrl(); // This will fetch fresh config
  }
  
  /// Get configuration status
  static Future<Map<String, dynamic>> getConfigStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString(_configKey);
    final lastUpdate = prefs.getInt(_lastUpdateKey) ?? 0;
    final currentUrl = await getBaseUrl();
    
    return {
      'current_url': currentUrl,
      'cached_url': cachedUrl,
      'last_update': DateTime.fromMillisecondsSinceEpoch(lastUpdate),
      'is_cached': _cachedBaseUrl != null,
      'fallback_url': fallbackUrl,
    };
  }
}