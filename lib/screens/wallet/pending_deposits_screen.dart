import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:async';
import '../../services/api_service.dart';
import '../../services/deposit_state_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/shared_layout.dart';
import '../../widgets/loading_state_manager.dart';
import '../../models/deposit.dart';

class PendingDepositsScreen extends StatefulWidget {
  const PendingDepositsScreen({super.key});

  @override
  State<PendingDepositsScreen> createState() => _PendingDepositsScreenState();
}

class _PendingDepositsScreenState extends State<PendingDepositsScreen> {
  final ApiService _apiService = ApiService();
  final DepositStateService _depositStateService = DepositStateService();
  List<Deposit> _pendingDeposits = [];
  bool _isLoading = true;
  Deposit? _selectedDeposit;
  Timer? _autoRefreshTimer;
  DateTime? _lastRefresh;
  late StreamSubscription _depositsSubscription;
  late StreamSubscription _statusChangeSubscription;
  late StreamSubscription _cancelledSubscription;

  // Auto-refresh every 30 seconds for pending deposits
  static const Duration _autoRefreshInterval = Duration(seconds: 30);

  final Map<String, Map<String, String>> _networks = {
    'eth': {
      'name': 'Ethereum',
      'symbol': 'ETH',
      'color': '0xFF627EEA',
    },
    'bsc': {
      'name': 'BSC',
      'symbol': 'BNB',
      'color': '0xFFF3BA2F',
    },
    'polygon': {
      'name': 'Polygon',
      'symbol': 'MATIC',
      'color': '0xFF8247E5',
    },
    'tron': {
      'name': 'Tron',
      'symbol': 'TRX',
      'color': '0xFFFF0013',
    },
  };

  @override
  void initState() {
    super.initState();
    _loadPendingDeposits();
    _startAutoRefresh();
    _setupStateListeners();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _depositsSubscription.cancel();
    _statusChangeSubscription.cancel();
    _cancelledSubscription.cancel();
    super.dispose();
  }

  void _setupStateListeners() {
    // Listen for deposits list updates
    _depositsSubscription = _depositStateService.depositsUpdated.listen((deposits) {
      if (mounted) {
        final newPendingDeposits = deposits.where((d) {
          final status = d.status.toUpperCase();
          return status == 'PENDING' || 
                 status == 'CONFIRMED' || 
                 status == 'PENDING_CONFIRMATIONS';
        }).toList();

        setState(() {
          _pendingDeposits = newPendingDeposits;
          _lastRefresh = DateTime.now();
        });

        // Update selected deposit if it exists
        if (_selectedDeposit != null) {
          final updatedSelected = _pendingDeposits.firstWhere(
            (d) => d.id == _selectedDeposit!.id,
            orElse: () => _selectedDeposit!,
          );
          if (updatedSelected.id == _selectedDeposit!.id) {
            setState(() {
              _selectedDeposit = updatedSelected;
            });
          }
        }
      }
    });

    // Listen for status changes
    _statusChangeSubscription = _depositStateService.depositStatusChanged.listen((deposit) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deposit status updated: ${deposit.displayStatus}'),
            backgroundColor: _getStatusColor(deposit.status),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    // Listen for cancelled deposits
    _cancelledSubscription = _depositStateService.depositCancelled.listen((depositId) {
      if (mounted && _selectedDeposit?.id == depositId) {
        setState(() => _selectedDeposit = null);
      }
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (timer) {
      if (mounted && _pendingDeposits.isNotEmpty) {
        _loadPendingDeposits(silent: true);
      }
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
  }

  Future<void> _loadPendingDeposits({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() => _isLoading = true);
      }
      
      final result = await _apiService.getMyDeposits();
      final depositsData = result['data'] as Map<String, dynamic>;
      final depositsList = depositsData['deposits'] as List<dynamic>;
      final allDeposits = depositsList.map((data) => Deposit.fromJson(data as Map<String, dynamic>)).toList();
      
      // Update the global state service
      _depositStateService.updateDeposits(allDeposits);
      
      setState(() {
        _lastRefresh = DateTime.now();
        if (!silent) {
          _isLoading = false;
        }
      });
    } catch (e) {
      setState(() {
        _pendingDeposits = [];
        if (!silent) {
          _isLoading = false;
        }
      });
    }
  }

  Future<void> _cancelDeposit(String depositId) async {
    try {
      setState(() => _isLoading = true);
      
      final response = await _apiService.cancelDeposit(depositId);
      final success = response['success'] == true;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Notify the state service about the cancellation
        _depositStateService.notifyDepositCancelled(depositId);
        
        // Reset selected deposit if it was the cancelled one
        if (_selectedDeposit?.id == depositId) {
          setState(() => _selectedDeposit = null);
        }
        
        // Immediately refresh to show updated status
        await _loadPendingDeposits();
        
        // Restart auto-refresh timer
        _startAutoRefresh();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling deposit: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _copyAddress(String address) {
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showDepositDetails(Deposit deposit) {
    setState(() {
      _selectedDeposit = deposit;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SharedLayout(
      currentRoute: '/pending-deposits',
      child: LoadingStateManager(
        isLoading: _isLoading,
        loadingText: 'Loading deposits...',
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pending Deposits'),
            if (_lastRefresh != null)
              Text(
                'Updated ${_formatRefreshTime(_lastRefresh!)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _loadPendingDeposits(),
              ),
              if (_autoRefreshTimer?.isActive == true)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'toggle_auto_refresh':
                  if (_autoRefreshTimer?.isActive == true) {
                    _stopAutoRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Auto-refresh disabled')),
                    );
                  } else {
                    _startAutoRefresh();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Auto-refresh enabled')),
                    );
                  }
                  setState(() {});
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_auto_refresh',
                child: Row(
                  children: [
                    Icon(
                      _autoRefreshTimer?.isActive == true ? Icons.pause : Icons.play_arrow,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(_autoRefreshTimer?.isActive == true ? 'Pause Auto-refresh' : 'Enable Auto-refresh'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _selectedDeposit != null 
          ? _buildDepositDetails() 
          : _buildDepositsList(),
    );
  }

  Widget _buildDepositsList() {
    if (_pendingDeposits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Pending Deposits',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.darkColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have any pending deposits.\nYou can create a new one.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mediumColor,
              ),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Create New Deposit',
              onPressed: () => context.go('/deposit'),
              backgroundColor: AppTheme.primaryColor,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingDeposits,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _pendingDeposits.length,
        itemBuilder: (context, index) {
          final deposit = _pendingDeposits[index];
          return _buildDepositCard(deposit);
        },
      ),
    );
  }

  Widget _buildDepositCard(Deposit deposit) {
    final networkInfo = _networks[deposit.network]!;
    final statusColor = _getStatusColor(deposit.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDepositDetails(deposit),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(int.parse(networkInfo['color']!)).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        networkInfo['symbol']![0],
                        style: TextStyle(
                          color: Color(int.parse(networkInfo['color']!)),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${deposit.amount} ${networkInfo['symbol']}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.darkColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          networkInfo['name']!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mediumColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      deposit.displayStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 16,
                      color: AppTheme.mediumColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${deposit.address.substring(0, 10)}...${deposit.address.substring(deposit.address.length - 6)}',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppTheme.darkColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _copyAddress(deposit.address),
                      icon: Icon(
                        Icons.copy,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDepositDetails(deposit),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cancelDeposit(deposit.id),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[50],
                        foregroundColor: Colors.red[700],
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepositDetails() {
    final deposit = _selectedDeposit!;
    final networkInfo = _networks[deposit.network]!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() => _selectedDeposit = null),
                icon: const Icon(Icons.arrow_back),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.lightColor,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Deposit Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.darkColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // QR Code and Address Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: deposit.address,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Send exactly ${deposit.amount} ${networkInfo['symbol']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Network: ${networkInfo['name']}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Address Copy Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deposit Address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.darkColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.lightColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.mediumColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        deposit.address,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      CustomButton(
                        text: 'Copy Address',
                        onPressed: () => _copyAddress(deposit.address),
                        backgroundColor: AppTheme.primaryColor,
                        height: 40,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Status and Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Status: ',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(deposit.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        deposit.displayStatus,
                        style: TextStyle(
                          color: _getStatusColor(deposit.status),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Created: ${deposit.createdAt}',
                  style: TextStyle(
                    color: AppTheme.mediumColor,
                    fontSize: 14,
                  ),
                ),
                if (deposit.expiresAt.isAfter(DateTime.now())) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Expires: ${deposit.expiresAt}',
                    style: TextStyle(
                      color: Colors.orange[700],
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Refresh Status',
                        onPressed: _loadPendingDeposits,
                        backgroundColor: AppTheme.infoColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Cancel Deposit',
                        onPressed: () => _cancelDeposit(deposit.id),
                        backgroundColor: Colors.red[100]!,
                        textColor: Colors.red[700]!,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRefreshTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'PENDING_CONFIRMATIONS':
        return Colors.blue;
      case 'CONFIRMED':
        return Colors.green;
      case 'EXPIRED':
        return Colors.red;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return AppTheme.mediumColor;
    }
  }
}