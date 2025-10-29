import 'dart:async';
import '../models/user.dart';

/// Service to calculate real-time earnings that update every second
/// This creates the "ticking" effect where users see their balance grow in real-time
class RealTimeEarningsService {
  Timer? _timer;
  final Duration updateInterval = const Duration(seconds: 1);
  
  // Store the last server update time
  DateTime? _lastServerUpdate;
  double? _baseBalance;
  double? _basePendingCommission;
  double? _basePendingIndirectCommission;
  double? _dailyEarningRate;
  double? _dailyCommissionRate;
  double? _dailyIndirectCommissionRate;
  
  /// Calculate real-time balance that updates every second
  /// 
  /// Formula: New Balance = Base Balance + (Seconds Elapsed × Per-Second Rate)
  double calculateRealTimeBalance(User user) {
    if (_lastServerUpdate == null || _baseBalance == null) {
      _initializeBaseValues(user);
    }
    
    final now = DateTime.now();
    final secondsElapsed = now.difference(_lastServerUpdate!).inSeconds;
    
    // Calculate per-second earning rate
    const secondsPerDay = 86400;
    final perSecondRate = _dailyEarningRate! / secondsPerDay;
    
    // Real-time balance = base + (seconds × rate × balance)
    final additionalEarnings = _baseBalance! * perSecondRate * secondsElapsed;
    
    return _baseBalance! + additionalEarnings;
  }
  
  /// Calculate real-time commission that updates every second
  double calculateRealTimeCommission(User user) {
    if (_lastServerUpdate == null || _basePendingCommission == null) {
      _initializeBaseValues(user);
    }
    
    final now = DateTime.now();
    final secondsElapsed = now.difference(_lastServerUpdate!).inSeconds;
    
    // Calculate per-second commission rate
    const secondsPerDay = 86400;
    final perSecondCommissionRate = (_dailyCommissionRate ?? 0) / secondsPerDay;
    
    // Real-time commission = base + (seconds × daily rate / seconds per day)
    final additionalCommission = perSecondCommissionRate * secondsElapsed;
    
    return _basePendingCommission! + additionalCommission;
  }
  
  /// Calculate real-time indirect commission
  double calculateRealTimeIndirectCommission(User user) {
    if (_lastServerUpdate == null || _basePendingIndirectCommission == null) {
      _initializeBaseValues(user);
    }
    
    final now = DateTime.now();
    final secondsElapsed = now.difference(_lastServerUpdate!).inSeconds;
    
    // Calculate per-second indirect commission rate
    const secondsPerDay = 86400;
    final perSecondIndirectRate = (_dailyIndirectCommissionRate ?? 0) / secondsPerDay;
    
    // Real-time indirect commission = base + (seconds × daily rate / seconds per day)
    final additionalIndirectCommission = perSecondIndirectRate * secondsElapsed;
    
    return _basePendingIndirectCommission! + additionalIndirectCommission;
  }
  
  /// Calculate total real-time earnings (own earnings + commissions)
  double calculateTotalRealTimeEarnings(User user) {
    final balance = calculateRealTimeBalance(user);
    final commission = calculateRealTimeCommission(user);
    final indirectCommission = calculateRealTimeIndirectCommission(user);
    
    // Total real-time earnings = current balance + pending commissions
    return balance + commission + indirectCommission;
  }
  
  /// Initialize base values from server response
  void _initializeBaseValues(User user) {
    _lastServerUpdate = DateTime.now();
    _baseBalance = user.walletBalance;
    _basePendingCommission = user.pendingReferralCommission;
    _basePendingIndirectCommission = user.pendingIndirectCommission;
    _dailyEarningRate = user.dailyEarningRate;
    _dailyCommissionRate = user.dailyEarningRate; // This should come from backend
    _dailyIndirectCommissionRate = 0.0; // This should come from backend
  }
  
  /// Update base values when fresh data is received from server
  void updateFromServer(User user, {
    double? dailyCommissionRate,
    double? dailyIndirectCommissionRate,
  }) {
    _lastServerUpdate = DateTime.now();
    _baseBalance = user.walletBalance;
    _basePendingCommission = user.pendingReferralCommission;
    _basePendingIndirectCommission = user.pendingIndirectCommission;
    _dailyEarningRate = user.dailyEarningRate;
    
    // Update commission rates if provided
    if (dailyCommissionRate != null) {
      _dailyCommissionRate = dailyCommissionRate;
    }
    if (dailyIndirectCommissionRate != null) {
      _dailyIndirectCommissionRate = dailyIndirectCommissionRate;
    }
  }
  
  /// Start a periodic timer that calls the update callback every second
  /// Use this in your UI to update the displayed values every second
  void startRealtimeUpdates(Function(double balance, double commission, double indirectCommission) onUpdate, User user) {
    _timer?.cancel();
    _initializeBaseValues(user);
    
    _timer = Timer.periodic(updateInterval, (timer) {
      final balance = calculateRealTimeBalance(user);
      final commission = calculateRealTimeCommission(user);
      final indirectCommission = calculateRealTimeIndirectCommission(user);
      
      onUpdate(balance, commission, indirectCommission);
    });
  }
  
  /// Stop the periodic timer
  void stopRealtimeUpdates() {
    _timer?.cancel();
    _timer = null;
  }
  
  /// Cleanup resources
  void dispose() {
    stopRealtimeUpdates();
  }
}
