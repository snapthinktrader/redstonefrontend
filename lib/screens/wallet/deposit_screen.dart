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

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  final DepositStateService _depositStateService = DepositStateService();
  final TextEditingController _amountController = TextEditingController();
  
  bool _isLoading = false;
  bool _addressCopied = false;
  bool _isAutoRefreshing = false;
  String _selectedNetwork = 'tron'; // Default to Tron since that's where owner wallet is
  Deposit? _currentDeposit;
  List<Deposit> _pendingDeposits = []; // Add list for all pending deposits
  List<Deposit> _allDeposits = []; // Add list for all deposits history
  late StreamSubscription _depositsSubscription;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupStateListeners();
    _loadAllDeposits();
    _startAutoRefresh();
  }

  final Map<String, Map<String, String>> _networks = {
    'eth': {
      'name': 'ERC-20 (Ethereum)',
      'symbol': 'USDT',
      'color': '0xFF627EEA',
    },
    'bsc': {
      'name': 'BEP-20 (BSC)',
      'symbol': 'USDT',
      'color': '0xFFF3BA2F',
    },
    'polygon': {
      'name': 'Polygon (MATIC)',
      'symbol': 'USDT',
      'color': '0xFF8247E5',
    },
    'tron': {
      'name': 'TRC-20 (Tron)',
      'symbol': 'USDT',
      'color': '0xFFFF0013',
    },
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _setupStateListeners() {
    // Listen for real-time deposit updates
    _depositsSubscription = _depositStateService.depositsUpdated.listen((deposits) {
      if (mounted) {
        setState(() {
          _allDeposits = deposits;
          _pendingDeposits = _depositStateService.pendingDeposits;
        });
      }
    });
  }

  void _startAutoRefresh() {
    // Auto-refresh every 10 seconds when there are pending deposits
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (mounted && _pendingDeposits.isNotEmpty) {
        print('Auto-refreshing deposits... Found ${_pendingDeposits.length} pending');
        setState(() => _isAutoRefreshing = true);
        await _loadAllDeposits();
        if (mounted) setState(() => _isAutoRefreshing = false);
      } else if (mounted && _pendingDeposits.isEmpty) {
        // If no pending deposits, refresh less frequently (every 30 seconds)
        if (timer.tick % 3 == 0) {
          print('Auto-refreshing deposits (no pending)...');
          setState(() => _isAutoRefreshing = true);
          await _loadAllDeposits();
          if (mounted) setState(() => _isAutoRefreshing = false);
        }
      }
    });
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _depositsSubscription.cancel();
    _autoRefreshTimer?.cancel();
    _amountController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, restart auto-refresh and load deposits
      print('App resumed, restarting auto-refresh');
      _loadAllDeposits();
      _startAutoRefresh();
    } else if (state == AppLifecycleState.paused) {
      // App went to background, stop auto-refresh to save battery
      print('App paused, stopping auto-refresh');
      _stopAutoRefresh();
    }
  }

  Future<void> _loadAllDeposits() async {
    try {
      print('Loading all deposits...');
      final result = await _apiService.getMyDeposits();
      final depositsData = result['data'] as Map<String, dynamic>;
      final depositsList = depositsData['deposits'] as List<dynamic>;
      final deposits = depositsList.map((data) => Deposit.fromJson(data as Map<String, dynamic>)).toList();
      print('Loaded ${deposits.length} deposits');
      
      // Update the global state service
      _depositStateService.updateDeposits(deposits);
      
      if (mounted) {
        setState(() {
          _allDeposits = deposits; // Store all deposits for history
          _pendingDeposits = _depositStateService.pendingDeposits;
        });
        print('Found ${_pendingDeposits.length} pending/confirmed deposits');
        print('Pending deposit statuses: ${_pendingDeposits.map((d) => d.status).join(', ')}');
      }
    } catch (e) {
      print('Error loading deposits: $e');
      // Set empty list on error to avoid null issues
      if (mounted) {
        setState(() {
          _pendingDeposits = [];
        });
      }
    }
  }

  Future<void> _createDeposit() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if there are pending deposits first
    if (_pendingDeposits.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have ${_pendingDeposits.length} pending deposit(s). Please cancel them first.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: _showDepositsList,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final depositResponse = await _apiService.createDeposit(
        amount: double.parse(_amountController.text),
        network: _selectedNetwork,
      );
      
      print('Deposit API response: $depositResponse');
      
      final newDeposit = Deposit.fromJson(depositResponse);
      setState(() {
        _currentDeposit = newDeposit;
      });
      
      // Notify the state service about the new deposit
      _depositStateService.notifyDepositCreated(newDeposit);
      
      print('Deposit created successfully');
      
      // Reload all deposits to show the new one in pending section
      await _loadAllDeposits();
      
    } catch (e) {
      print('Error creating deposit: $e');
      setState(() {
        _isLoading = false;
      });
      
      String errorMessage = 'Error creating deposit';
      if (e.toString().contains('pending deposit')) {
        errorMessage = 'You have existing pending deposits. Please cancel them first or wait for completion.';
        // Reload deposits to show current state
        await _loadAllDeposits();
      } else if (e.toString().contains('Validation failed')) {
        errorMessage = 'Invalid input. Please check your amount and network selection.';
      } else {
        errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelDeposit() async {
    if (_currentDeposit == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final depositId = _currentDeposit!.id; // Store the ID before nulling
      final response = await _apiService.cancelDeposit(depositId);
      final success = response['success'] == true;
      
      setState(() {
        _currentDeposit = null;
        
        // Remove from pending deposits if it exists
        _pendingDeposits.removeWhere((d) => d.id == depositId);
      });
      
      // Trigger immediate refresh to update UI
      await _loadAllDeposits();
      
      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deposit cancelled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error cancelling deposit: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _copyAddress() {
    if (_currentDeposit?.address != null) {
      Clipboard.setData(ClipboardData(text: _currentDeposit!.address));
      setState(() {
        _addressCopied = true;
      });
      
      // Reset the copied state after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _addressCopied = false;
          });
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showDepositsList() {
    context.push('/pending-deposits');
  }

  @override
  Widget build(BuildContext context) {
    return SharedLayout(
      currentRoute: '/deposit',
      child: LoadingStateManager(
        isLoading: _isLoading,
        loadingText: 'Processing...',
        child: _buildDepositContent(),
      ),
    );
  }

  Widget _buildDepositContent() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Deposit'),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Auto-refresh indicator
          if (_isAutoRefreshing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                ),
              ),
            ),
          // Show pending deposits count if any exist
          if (_pendingDeposits.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.list),
                    onPressed: _showDepositsList,
                  ),
                  if (_pendingDeposits.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_pendingDeposits.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_currentDeposit == null) ...[
                _buildDepositForm(),
                const SizedBox(height: 24),
                _buildPendingDepositsSection(), // Always show for debugging
                const SizedBox(height: 24),
                _buildDepositHistorySection(), // Add deposit history section
              ] else ...[
                _buildDepositDetails(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepositForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New Deposit',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.darkColor,
          ),
        ),
        const SizedBox(height: 20),
        
        Text(
          'Select Network',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkColor,
          ),
        ),
        const SizedBox(height: 12),
        
        // Network Selection
        ..._networks.entries.map((entry) => _buildNetworkTile(
          entry.key,
          entry.value['name']!,
          entry.value['symbol']!,
          Color(int.parse(entry.value['color']!)),
        )),
        
        const SizedBox(height: 24),
        
        Text(
          'Amount',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.darkColor,
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter amount in ${_networks[_selectedNetwork]!['symbol']}',
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ),
        
        const SizedBox(height: 24),
        
        CustomButton(
          text: 'Create Deposit',
          onPressed: _createDeposit,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildNetworkTile(String key, String name, String symbol, Color color) {
    final isSelected = key == _selectedNetwork;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: () {
          setState(() {
            _selectedNetwork = key;
          });
        },
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              symbol[0],
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? AppTheme.primaryColor : AppTheme.darkColor,
          ),
        ),
        subtitle: Text(
          symbol,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : AppTheme.greyColor,
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: AppTheme.primaryColor)
            : Icon(Icons.radio_button_unchecked, color: Colors.grey[400]),
      ),
    );
  }

  Widget _buildDepositDetails() {
    if (_currentDeposit == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.qr_code, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Scan QR Code or Copy Address',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              Text(
                'Send exactly ${_currentDeposit!.amount} ${_networks[_currentDeposit!.network]!['symbol']} to:',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _currentDeposit!.address,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: _currentDeposit!.address,
                  version: QrVersions.auto,
                  size: 180,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                'Network: ${_networks[_currentDeposit!.network]!['name']}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Copy Address Button
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightColor,
                  border: Border.all(color: AppTheme.mediumColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _currentDeposit!.address,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.mediumColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _addressCopied ? Icons.check : Icons.copy,
                color: _addressCopied ? AppTheme.primaryColor : AppTheme.darkColor,
                size: 20,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Action Buttons
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                'Amount: ${_currentDeposit!.amount} ${_networks[_currentDeposit!.network]!['symbol']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Copy Address',
                onPressed: _copyAddress,
                backgroundColor: AppTheme.infoColor,
                height: 48,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Send only ${_networks[_currentDeposit!.network]!['symbol']} to this address. Other tokens will be lost permanently.',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // ✅ Only show Cancel Button if deposit is not CONFIRMED or COMPLETED
        if (_currentDeposit?.status != 'CONFIRMED' && _currentDeposit?.status != 'COMPLETED')
          CustomButton(
            text: 'Cancel Deposit',
            onPressed: _cancelDeposit,
            backgroundColor: Colors.red[100],
            textColor: Colors.red[700],
          ),
      ],
    );
  }

  Widget _buildPendingDepositsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _pendingDeposits.isEmpty ? Colors.green[50] : Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _pendingDeposits.isEmpty ? Icons.check_circle : Icons.pending,
                  color: _pendingDeposits.isEmpty ? Colors.green : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending Deposits',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.darkColor,
                      ),
                    ),
                    Text(
                      _pendingDeposits.isEmpty 
                          ? 'No pending deposits' 
                          : '${_pendingDeposits.length} deposit(s) pending',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.mediumColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_pendingDeposits.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_pendingDeposits.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_pendingDeposits.isEmpty) 
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green[600],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready to create deposit',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'You can create a new deposit now',
                    style: TextStyle(
                      color: Colors.green[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_rounded,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You have pending deposits that need to be completed or cancelled before creating new ones.',
                          style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'View Pending Deposits (${_pendingDeposits.length})',
                    onPressed: _showDepositsList,
                    backgroundColor: AppTheme.primaryColor,
                    height: 48,
                    icon: Icons.visibility,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDepositHistorySection() {
    final completedDeposits = _allDeposits.where((d) {
      final status = d.status.toUpperCase();
      return status == 'COMPLETED' || status == 'CANCELLED' || status == 'EXPIRED';
    }).toList();

    if (completedDeposits.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Deposit History (${completedDeposits.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...completedDeposits.map((deposit) => _buildHistoryDepositCard(deposit)),
        ],
      ),
    );
  }

  Widget _buildHistoryDepositCard(Deposit deposit) {
    Color statusColor;
    IconData statusIcon;
    String statusText = deposit.status.toUpperCase();

    switch (statusText) {
      case 'COMPLETED':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'CANCELLED':
        statusColor = Colors.orange;
        statusIcon = Icons.cancel;
        break;
      case 'EXPIRED':
        statusColor = Colors.red;
        statusIcon = Icons.access_time;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${deposit.amount} ${deposit.network.toUpperCase()}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                _formatDate(deposit.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          if (deposit.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              deposit.notes!,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}