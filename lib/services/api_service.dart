import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/transaction.dart';
import '../utils/storage_helper.dart';
import '../config/config.dart';

class ApiService {
  static String get baseUrl => Config.baseUrl;
  late final Dio _dio;
  final StorageHelper _storageHelper = StorageHelper();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Add interceptor for adding auth token
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storageHelper.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, try to refresh
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry original request
            final token = await _storageHelper.getToken();
            error.requestOptions.headers['Authorization'] = 'Bearer $token';
            final response = await _dio.fetch(error.requestOptions);
            handler.resolve(response);
            return;
          } else {
            // Refresh failed, clear auth data
            await _storageHelper.clearAuthData();
          }
        }
        handler.next(error);
      },
    ));
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storageHelper.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        await _storageHelper.saveToken(data['accessToken']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Auth Methods
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'name': name,
        'email': email,
        'password': password,
        if (referralCode != null && referralCode.isNotEmpty) 'referralCode': referralCode,
      });

      if (response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Registration failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response!.data['message'] ?? 'Registration failed';
        throw Exception(message);
      } else {
        throw Exception('Network error during registration');
      }
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final message = e.response!.data['message'] ?? 'Login failed';
        final requiresVerification = e.response!.data['requiresEmailVerification'] ?? false;
        
        if (requiresVerification) {
          throw Exception('EMAIL_VERIFICATION_REQUIRED');
        }
        
        throw Exception(message);
      } else {
        throw Exception('Network error during login');
      }
    }
  }

  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/auth/logout', data: {
        'refreshToken': refreshToken,
      });
    } catch (e) {
      // Ignore logout errors
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200) {
        return User.fromJson(response.data['data']['user']);
      } else {
        throw Exception('Failed to get user data');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to get user data');
      } else {
        throw Exception('Network error while fetching user data');
      }
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      final response = await _dio.post('/auth/verify-email', data: {
        'token': token,
      });

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Email verification failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Email verification failed');
      } else {
        throw Exception('Network error during email verification');
      }
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      final response = await _dio.post('/auth/resend-verification', data: {
        'email': email,
      });

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to send verification email');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to send verification email');
      } else {
        throw Exception('Network error while sending verification email');
      }
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post('/auth/forgot-password', data: {
        'email': email,
      });

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Failed to send password reset email');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to send password reset email');
      } else {
        throw Exception('Network error while sending password reset email');
      }
    }
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post('/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });

      if (response.statusCode != 200) {
        throw Exception(response.data['message'] ?? 'Password reset failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Password reset failed');
      } else {
        throw Exception('Network error during password reset');
      }
    }
  }

  // Transaction Methods
  Future<List<Transaction>> getTransactions({
    int page = 1,
    int limit = 20,
    String? type,
    String? status,
  }) async {
    try {
      final response = await _dio.get('/transactions', queryParameters: {
        'page': page,
        'limit': limit,
        if (type != null) 'type': type,
        if (status != null) 'status': status,
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data']['transactions'];
        return data.map((item) => Transaction.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch transactions');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to fetch transactions');
      } else {
        throw Exception('Network error while fetching transactions');
      }
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final response = await _dio.get('/users/stats');
      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch user stats');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to fetch user stats');
      } else {
        throw Exception('Network error while fetching user stats');
      }
    }
  }

  Future<Map<String, dynamic>> createDeposit({
    required double amount,
    required String cryptocurrency,
    required String paymentMethod,
  }) async {
    try {
      final response = await _dio.post('/transactions/deposit', data: {
        'amount': amount,
        'cryptocurrency': cryptocurrency,
        'paymentMethod': paymentMethod,
      });

      if (response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Deposit creation failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Deposit creation failed');
      } else {
        throw Exception('Network error during deposit creation');
      }
    }
  }

  Future<Map<String, dynamic>> createWithdrawal({
    required double amount,
    required String cryptocurrency,
    required String walletAddress,
  }) async {
    try {
      final response = await _dio.post('/transactions/withdrawal', data: {
        'amount': amount,
        'cryptocurrency': cryptocurrency,
        'walletAddress': walletAddress,
      });

      if (response.statusCode == 201) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Withdrawal creation failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Withdrawal creation failed');
      } else {
        throw Exception('Network error during withdrawal creation');
      }
    }
  }

  // Referral Methods
  Future<Map<String, dynamic>> getReferralStats() async {
    try {
      final response = await _dio.get('/referrals/stats');
      if (response.statusCode == 200) {
        return response.data['data'];
      } else {
        throw Exception('Failed to fetch referral stats');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to fetch referral stats');
      } else {
        throw Exception('Network error while fetching referral stats');
      }
    }
  }

  Future<List<Map<String, dynamic>>> getReferrals({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get('/referrals', queryParameters: {
        'page': page,
        'limit': limit,
      });

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['data']['referrals']);
      } else {
        throw Exception('Failed to fetch referrals');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response!.data['message'] ?? 'Failed to fetch referrals');
      } else {
        throw Exception('Network error while fetching referrals');
      }
    }
  }
}