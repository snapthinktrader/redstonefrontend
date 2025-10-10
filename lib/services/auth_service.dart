import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/transaction.dart';
import '../models/referral.dart';
import '../config/config.dart';
import '../utils/storage_helper.dart';

class AuthService {
  static String get baseUrl => Config.baseUrl;
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Register new user (alias for signup)
  Future<Map<String, dynamic>> signup({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final fullName = '$firstName $lastName';
    return await register(
      fullName: fullName,
      email: email,
      password: password,
      referralCode: referralCode,
    );
  }

  // Register new user
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'name': fullName,
        'email': email,
        'password': password,
      };
      
      // Only add referralCode if it's not null and not empty
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        requestBody['referralCode'] = referralCode.trim();
      }
      
      print('DEBUG: Sending registration request to: $baseUrl/auth/register');
      print('DEBUG: Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body: ${response.body}');
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'user': data['data']['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      print('DEBUG: Exception in register: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save tokens and user data
        final accessToken = data['data']['accessToken'];
        final refreshToken = data['data']['refreshToken'] ?? '';
        final user = data['data']['user'];
        
        await _saveAuthData(accessToken, refreshToken, user);
        
        return {
          'success': true,
          'message': 'Login successful',
          'user': user,
          'token': accessToken,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Verify email with OTP
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Email verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Resend verification email
  Future<Map<String, dynamic>> resendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to resend verification email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'No authentication token found',
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get user profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user transactions
  Future<List<Transaction>> getUserTransactions() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> transactionsJson = data['data']['transactions'] ?? [];
        return transactionsJson.map((json) => Transaction.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to get transactions');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Get user referrals
  Future<List<Referral>> getUserReferrals() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/referral/user-referrals'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> referralsJson = data['data']['referrals'] ?? [];
        return referralsJson.map((json) => Referral.fromJson(json)).toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to get referrals');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }

  // Logout user
  Future<void> logout() async {
    final storageHelper = StorageHelper();
    await storageHelper.clearAuthData();
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final storageHelper = StorageHelper();
    final token = await storageHelper.getToken();
    return token != null && token.isNotEmpty;
  }

  // Get stored auth token
  Future<String?> getToken() async {
    final storageHelper = StorageHelper();
    return await storageHelper.getToken();
  }

  // Get stored user data
  Future<User?> getUser() async {
    final storageHelper = StorageHelper();
    final userData = await storageHelper.getUserData();
    if (userData != null) {
      return User.fromJson(userData);
    }
    return null;
  }

  // Save auth data to local storage
  Future<void> _saveAuthData(String accessToken, String refreshToken, Map<String, dynamic> userData) async {
    final storageHelper = StorageHelper();
    await storageHelper.saveToken(accessToken);
    if (refreshToken.isNotEmpty) {
      await storageHelper.saveRefreshToken(refreshToken);
    }
    await storageHelper.saveUserData(userData);
  }
}