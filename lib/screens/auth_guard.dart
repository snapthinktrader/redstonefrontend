import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/storage_helper.dart';
import '../services/api_service.dart';
import '../widgets/loading_state_manager.dart';

class AuthGuard extends StatefulWidget {
  final Widget child;
  
  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  static bool _isFirstCheck = true;
  static bool? _cachedAuthState;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      // Use cached state for faster subsequent checks
      if (!_isFirstCheck && _cachedAuthState != null) {
        setState(() {
          _isAuthenticated = _cachedAuthState!;
          _isLoading = false;
        });
        
        if (!_isAuthenticated && mounted) {
          context.go('/login');
        }
        return;
      }

      final storageHelper = StorageHelper();
      final token = await storageHelper.getToken();
      
      if (token != null && token.isNotEmpty) {
        // Skip API validation on subsequent checks to speed up navigation
        if (!_isFirstCheck) {
          setState(() {
            _isAuthenticated = true;
            _isLoading = false;
          });
          _cachedAuthState = true;
          return;
        }

        // Only validate token on first check
        final apiService = ApiService();
        try {
          await apiService.getCurrentUser();
          setState(() {
            _isAuthenticated = true;
            _isLoading = false;
          });
          _cachedAuthState = true;
          _isFirstCheck = false;
          return;
        } catch (e) {
          // Token is invalid, clear cache and redirect
          _cachedAuthState = false;
          await storageHelper.clearAuthData();
        }
      }
      
      // No valid token, redirect to login
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
      _cachedAuthState = false;
      
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
      _cachedAuthState = false;
      
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: LoadingStateManager(
          isLoading: true,
          loadingText: 'Authenticating...',
          child: Container(),
        ),
      );
    }

    if (!_isAuthenticated) {
      return Scaffold(
        body: LoadingStateManager(
          isLoading: true,
          loadingText: 'Redirecting to login...',
          child: Container(),
        ),
      );
    }

    return widget.child;
  }
}