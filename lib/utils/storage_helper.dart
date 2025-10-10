import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class StorageHelper {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _biometricKey = 'biometric_enabled';
  static const String _pinKey = 'app_pin';
  static const String _themeKey = 'app_theme';
  static const String _notificationKey = 'notifications_enabled';
  static const String _fingerprintKey = 'fingerprint_enabled';
  
  static const String _secureBoxName = 'secure_storage';
  static const String _cacheBoxName = 'cache_storage';

  late SharedPreferences _prefs;
  late Box _secureBox;
  late Box _cacheBox;
  
  static StorageHelper? _instance;
  
  StorageHelper._internal();
  
  factory StorageHelper() {
    _instance ??= StorageHelper._internal();
    return _instance!;
  }

  /// Initialize storage systems
  Future<void> init() async {
    await Hive.initFlutter();
    _prefs = await SharedPreferences.getInstance();
    
    // Initialize Hive boxes
    _secureBox = await Hive.openBox(_secureBoxName);
    _cacheBox = await Hive.openBox(_cacheBoxName);
  }

  // Token Management
  Future<void> saveToken(String token) async {
    await _secureBox.put(_tokenKey, _encryptData(token));
  }

  Future<String?> getToken() async {
    try {
      final encryptedToken = _secureBox.get(_tokenKey);
      if (encryptedToken != null) {
        return _decryptData(encryptedToken);
      }
      return null;
    } catch (e) {
      // Storage not initialized or error accessing storage
      return null;
    }
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _secureBox.put(_refreshTokenKey, _encryptData(refreshToken));
  }

  Future<String?> getRefreshToken() async {
    try {
      final encryptedToken = _secureBox.get(_refreshTokenKey);
      if (encryptedToken != null) {
        return _decryptData(encryptedToken);
      }
      return null;
    } catch (e) {
      // Storage not initialized or error accessing storage
      return null;
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await saveToken(accessToken);
    await saveRefreshToken(refreshToken);
  }

  // User Data Management
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final userDataString = json.encode(userData);
    await _secureBox.put(_userKey, _encryptData(userDataString));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final encryptedData = _secureBox.get(_userKey);
    if (encryptedData != null) {
      final userDataString = _decryptData(encryptedData);
      return json.decode(userDataString);
    }
    return null;
  }

  // Authentication State
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearAuthData() async {
    await _secureBox.delete(_tokenKey);
    await _secureBox.delete(_refreshTokenKey);
    await _secureBox.delete(_userKey);
  }

  // Security Settings
  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(_biometricKey, enabled);
  }

  bool isBiometricEnabled() {
    return _prefs.getBool(_biometricKey) ?? false;
  }

  Future<void> setAppPin(String pin) async {
    final hashedPin = _hashPin(pin);
    await _secureBox.put(_pinKey, hashedPin);
  }

  Future<bool> verifyAppPin(String pin) async {
    final storedHash = _secureBox.get(_pinKey);
    if (storedHash == null) return false;
    
    final inputHash = _hashPin(pin);
    return storedHash == inputHash;
  }

  Future<bool> hasAppPin() async {
    return _secureBox.containsKey(_pinKey);
  }

  Future<void> removeAppPin() async {
    await _secureBox.delete(_pinKey);
  }

  // App Settings
  Future<void> setThemeMode(String theme) async {
    await _prefs.setString(_themeKey, theme);
  }

  String getThemeMode() {
    return _prefs.getString(_themeKey) ?? 'system';
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_notificationKey, enabled);
  }

  bool areNotificationsEnabled() {
    return _prefs.getBool(_notificationKey) ?? true;
  }

  Future<void> setFingerprintEnabled(bool enabled) async {
    await _prefs.setBool(_fingerprintKey, enabled);
  }

  bool isFingerprintEnabled() {
    return _prefs.getBool(_fingerprintKey) ?? false;
  }

  // Cache Management
  Future<void> cacheData(String key, dynamic data) async {
    final dataString = json.encode({
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await _cacheBox.put(key, dataString);
  }

  Future<T?> getCachedData<T>(String key, {Duration? maxAge}) async {
    final cachedString = _cacheBox.get(key);
    if (cachedString == null) return null;

    try {
      final cached = json.decode(cachedString);
      final timestamp = cached['timestamp'] as int;
      final data = cached['data'];

      if (maxAge != null) {
        final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        if (now.difference(cacheTime) > maxAge) {
          await _cacheBox.delete(key);
          return null;
        }
      }

      return data as T;
    } catch (e) {
      await _cacheBox.delete(key);
      return null;
    }
  }

  Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  Future<void> deleteCacheKey(String key) async {
    await _cacheBox.delete(key);
  }

  // Utility Methods
  Future<void> clearAllData() async {
    await _secureBox.clear();
    await _cacheBox.clear();
    await _prefs.clear();
  }

  Future<Map<String, dynamic>> getStorageInfo() async {
    return {
      'secureBoxKeys': _secureBox.keys.length,
      'cacheBoxKeys': _cacheBox.keys.length,
      'prefsKeys': _prefs.getKeys().length,
      'isLoggedIn': await isLoggedIn(),
      'biometricEnabled': isBiometricEnabled(),
      'hasPin': await hasAppPin(),
      'theme': getThemeMode(),
      'notificationsEnabled': areNotificationsEnabled(),
    };
  }

  // Private Methods
  String _encryptData(String data) {
    // Simple XOR encryption with device-specific key
    // In production, use a more secure encryption method
    final key = _getDeviceKey();
    final bytes = utf8.encode(data);
    final keyBytes = utf8.encode(key);
    
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] ^= keyBytes[i % keyBytes.length];
    }
    
    return base64.encode(bytes);
  }

  String _decryptData(String encryptedData) {
    try {
      final key = _getDeviceKey();
      final bytes = base64.decode(encryptedData);
      final keyBytes = utf8.encode(key);
      
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] ^= keyBytes[i % keyBytes.length];
      }
      
      return utf8.decode(bytes);
    } catch (e) {
      return '';
    }
  }

  String _getDeviceKey() {
    // Generate a device-specific key
    // In production, use device ID or other device-specific data
    return 'redstone_crypto_key_2024';
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin + _getDeviceKey());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Migration helper for app updates
  Future<void> migrateIfNeeded() async {
    const String versionKey = 'storage_version';
    const int currentVersion = 1;
    
    final storedVersion = _prefs.getInt(versionKey) ?? 0;
    
    if (storedVersion < currentVersion) {
      // Perform migration tasks here
      await _performMigration(storedVersion, currentVersion);
      await _prefs.setInt(versionKey, currentVersion);
    }
  }

  Future<void> _performMigration(int fromVersion, int toVersion) async {
    // Add migration logic here for future versions
    if (fromVersion < 1) {
      // Migration from version 0 to 1
      // Example: Clear old cache format
      await clearCache();
    }
  }
}

// Storage keys constants for consistency
class StorageKeys {
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String userData = 'user_data';
  static const String biometricEnabled = 'biometric_enabled';
  static const String appPin = 'app_pin';
  static const String themeMode = 'app_theme';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String fingerprintEnabled = 'fingerprint_enabled';
  
  // Cache keys
  static const String userStats = 'user_stats';
  static const String transactions = 'transactions';
  static const String referralStats = 'referral_stats';
  static const String cryptoPrices = 'crypto_prices';
  static const String exchangeRates = 'exchange_rates';
}

// Storage exceptions
class StorageException implements Exception {
  final String message;
  final String? code;
  
  StorageException(this.message, {this.code});
  
  @override
  String toString() => 'StorageException: $message${code != null ? ' ($code)' : ''}';
}