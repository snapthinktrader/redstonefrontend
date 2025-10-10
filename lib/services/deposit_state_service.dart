import 'dart:async';
import '../models/deposit.dart';

/// Service to manage deposit state across the app
/// Provides real-time updates when deposits are created, updated, or cancelled
class DepositStateService {
  static final DepositStateService _instance = DepositStateService._internal();
  factory DepositStateService() => _instance;
  DepositStateService._internal();

  // Stream controllers for different types of deposit events
  final StreamController<List<Deposit>> _depositsUpdatedController = 
      StreamController<List<Deposit>>.broadcast();
  final StreamController<Deposit> _depositCreatedController = 
      StreamController<Deposit>.broadcast();
  final StreamController<String> _depositCancelledController = 
      StreamController<String>.broadcast();
  final StreamController<Deposit> _depositStatusChangedController = 
      StreamController<Deposit>.broadcast();

  // Streams for external listening
  Stream<List<Deposit>> get depositsUpdated => _depositsUpdatedController.stream;
  Stream<Deposit> get depositCreated => _depositCreatedController.stream;
  Stream<String> get depositCancelled => _depositCancelledController.stream;
  Stream<Deposit> get depositStatusChanged => _depositStatusChangedController.stream;

  // Current deposits cache
  List<Deposit> _currentDeposits = [];
  List<Deposit> get currentDeposits => List.unmodifiable(_currentDeposits);

  /// Update the complete deposits list
  void updateDeposits(List<Deposit> deposits) {
    // Check for status changes
    for (final newDeposit in deposits) {
      final oldDeposit = _currentDeposits.firstWhere(
        (d) => d.id == newDeposit.id,
        orElse: () => newDeposit,
      );
      
      if (oldDeposit.id == newDeposit.id && oldDeposit.status != newDeposit.status) {
        _depositStatusChangedController.add(newDeposit);
      }
    }

    _currentDeposits = deposits;
    _depositsUpdatedController.add(deposits);
  }

  /// Notify that a new deposit was created
  void notifyDepositCreated(Deposit deposit) {
    _currentDeposits.insert(0, deposit);
    _depositCreatedController.add(deposit);
    _depositsUpdatedController.add(_currentDeposits);
  }

  /// Notify that a deposit was cancelled
  void notifyDepositCancelled(String depositId) {
    _currentDeposits.removeWhere((d) => d.id == depositId);
    _depositCancelledController.add(depositId);
    _depositsUpdatedController.add(_currentDeposits);
  }

  /// Get pending deposits
  List<Deposit> get pendingDeposits {
    return _currentDeposits.where((d) {
      final status = d.status.toUpperCase();
      return status == 'PENDING' || 
             status == 'CONFIRMED' || 
             status == 'PENDING_CONFIRMATIONS';
    }).toList();
  }

  /// Check if user has pending deposits
  bool get hasPendingDeposits => pendingDeposits.isNotEmpty;

  /// Clean up resources
  void dispose() {
    _depositsUpdatedController.close();
    _depositCreatedController.close();
    _depositCancelledController.close();
    _depositStatusChangedController.close();
  }
}