import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/storage_helper.dart';

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final StorageHelper _storageHelper;

  AuthNotifier(this._apiService, this._storageHelper) : super(const AuthState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final token = await _storageHelper.getToken();
      if (token != null) {
        final user = await _apiService.getCurrentUser();
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (error) {
      await _storageHelper.clearAuthData();
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.register(
        name: name,
        email: email,
        password: password,
        referralCode: referralCode,
      );
      
      // If registration requires email verification, don't set as authenticated
      if (response['requiresEmailVerification'] == true) {
        state = state.copyWith(
          isLoading: false,
          error: null,
        );
        return true; // Success but needs verification
      }
      
      // If registration includes tokens (auto-login), save them
      if (response['tokens'] != null) {
        await _storageHelper.saveTokens(
          response['tokens']['accessToken'],
          response['tokens']['refreshToken'],
        );
        
        final userData = response['user'];
        final user = User.fromJson(userData);
        
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
      }
      
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _apiService.login(
        email: email,
        password: password,
      );
      
      // Check if email verification is required
      if (response['requiresEmailVerification'] == true) {
        state = state.copyWith(
          isLoading: false,
          error: 'Please verify your email address before logging in.',
        );
        return false;
      }
      
      await _storageHelper.saveTokens(
        response['tokens']['accessToken'],
        response['tokens']['refreshToken'],
      );
      
      final userData = response['user'];
      final user = User.fromJson(userData);
      
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      );
      
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    
    try {
      final refreshToken = await _storageHelper.getRefreshToken();
      if (refreshToken != null) {
        await _apiService.logout(refreshToken);
      }
    } catch (error) {
      // Continue with logout even if API call fails
    }
    
    await _storageHelper.clearAuthData();
    state = const AuthState();
  }

  Future<bool> resendVerificationEmail(String email) async {
    try {
      await _apiService.resendVerificationEmail(email);
      return true;
    } catch (error) {
      throw error.toString();
    }
  }

  Future<bool> verifyEmail(String token) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _apiService.verifyEmail(token);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _apiService.forgotPassword(email);
      return true;
    } catch (error) {
      throw error.toString();
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _apiService.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      return true;
    } catch (error) {
      throw error.toString();
    }
  }

  Future<void> refreshUser() async {
    if (!state.isAuthenticated) return;
    
    try {
      final user = await _apiService.getCurrentUser();
      state = state.copyWith(user: user);
    } catch (error) {
      // If refresh fails, user might need to login again
      await signOut();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final storageHelperProvider = Provider<StorageHelper>((ref) => StorageHelper());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final storageHelper = ref.read(storageHelperProvider);
  return AuthNotifier(apiService, storageHelper);
});