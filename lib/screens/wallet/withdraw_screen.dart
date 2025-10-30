import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _amountController = TextEditingController();
  final _walletController = TextEditingController();
  final _twoFactorController = TextEditingController();
  String _selectedCrypto = 'BTC';
  bool _isLoading = false;
  bool _isLoadingUser = true;
  User? _currentUser;
  Map<String, dynamic>? _withdrawalLimits;
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _amountController.addListener(() {
      setState(() {}); // Rebuild to update "You Will Receive" calculation
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getUser();
      final limits = await _apiService.getWithdrawalLimits();
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _withdrawalLimits = limits;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _walletController.dispose();
    _twoFactorController.dispose();
    super.dispose();
  }

  void _setPercentage(double percentage) {
    final balance = _currentUser?.walletBalance ?? 0.0;
    final amount = (balance * percentage).toStringAsFixed(2);
    _amountController.text = amount;
  }

  Future<void> _withdraw() async {
    if (_amountController.text.isEmpty || _walletController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final networkMap = {
        'BTC': 'tron',
        'USDT_ERC20': 'ethereum',
        'USDT_BEP20': 'bsc',
        'USDT_TRC20': 'tron',
        'USDT_POLYGON': 'polygon',
      };

      await _apiService.createWithdrawalNew(
        amount: amount,
        toAddress: _walletController.text.trim(),
        network: networkMap[_selectedCrypto] ?? 'bsc',
        userNotes: 'Withdrawal request from mobile app',
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Withdrawal request submitted successfully! Pending approval.'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Refresh user data
        await _loadUserData();
        
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkColor),
          onPressed: () => Navigator.of(context).canPop() 
              ? Navigator.of(context).pop() 
              : context.go('/dashboard'),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.attach_money,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'RedStone',
              style: TextStyle(
                color: AppTheme.darkColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: _isLoadingUser
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 768),
                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Withdraw Funds',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkColor,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: AppTheme.mediumColor,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _withdrawalLimits != null 
                                      ? 'Time: ${_withdrawalLimits!['processingTime']['text']}'
                                      : 'Time: 1-48 hours',
                                  style: TextStyle(
                                    color: AppTheme.mediumColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Tier Information
                        if (_withdrawalLimits != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor.withOpacity(0.1),
                                  AppTheme.secondaryColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.workspace_premium,
                                      color: AppTheme.primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_withdrawalLimits!['tierName']} Tier',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.darkColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_withdrawalLimits!['nextWithdrawal']['canWithdraw'])
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Withdrawal #${_withdrawalLimits!['nextWithdrawal']['number']}',
                                        style: TextStyle(
                                          color: AppTheme.mediumColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Max: \$${_withdrawalLimits!['nextWithdrawal']['maxAmount'].toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (!_withdrawalLimits!['nextWithdrawal']['canWithdraw'])
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.errorColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: AppTheme.errorColor,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _withdrawalLimits!['nextWithdrawal']['waitingMessage'] ?? 'Please wait',
                                            style: TextStyle(
                                              color: AppTheme.errorColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        
                        if (_withdrawalLimits != null) const SizedBox(height: 16),
                        
                        // Available Balance
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.lightColor.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Available Balance',
                                    style: TextStyle(
                                      color: AppTheme.mediumColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '\$${(_currentUser?.walletBalance ?? 0.0).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Equivalent in Crypto',
                                    style: TextStyle(
                                      color: AppTheme.mediumColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    '${((_currentUser?.walletBalance ?? 0.0) / 30000).toStringAsFixed(6)} BTC',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                  
                  const SizedBox(height: 24),
                  
                  // Amount Input
                  const Text(
                    'Amount to Withdraw',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.mediumColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              hintText: '0.00',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'USD',
                            style: TextStyle(
                              color: AppTheme.mediumColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildPercentageButton('25%', 0.25),
                          const SizedBox(width: 8),
                          _buildPercentageButton('50%', 0.50),
                          const SizedBox(width: 8),
                          _buildPercentageButton('75%', 0.75),
                          const SizedBox(width: 8),
                          _buildPercentageButton('MAX', 1.0, isMax: true),
                        ],
                      ),
                      Text(
                        _withdrawalLimits != null 
                            ? 'Min: \$${_withdrawalLimits!['minimumWithdrawal'].toStringAsFixed(2)}'
                            : 'Min: \$100.00',
                        style: TextStyle(
                          color: AppTheme.mediumColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Crypto Selection
                  const Text(
                    'Select Cryptocurrency',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.mediumColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCrypto,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'BTC', child: Text('Bitcoin (BTC)')),
                          DropdownMenuItem(value: 'USDT_ERC20', child: Text('ERC-20 (Ethereum) USDT')),
                          DropdownMenuItem(value: 'USDT_BEP20', child: Text('BEP-20 (BSC) USDT')),
                          DropdownMenuItem(value: 'USDT_TRC20', child: Text('TRC-20 (Tron) USDT')),
                          DropdownMenuItem(value: 'USDT_POLYGON', child: Text('Polygon USDT')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCrypto = value!;
                          });
                        },
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Wallet Address
                  const Text(
                    'Your Crypto Wallet Address',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.mediumColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextFormField(
                      controller: _walletController,
                      decoration: const InputDecoration(
                        hintText: 'Enter your wallet address',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Make sure this address is correct and supports the selected cryptocurrency.',
                    style: TextStyle(
                      color: AppTheme.mediumColor,
                      fontSize: 12,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Fee Information
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.lightColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Network Fee',
                              style: TextStyle(
                                color: AppTheme.mediumColor,
                              ),
                            ),
                            Text(
                              _withdrawalLimits != null 
                                  ? '\$${_withdrawalLimits!['networkFee'].toStringAsFixed(2)}'
                                  : '\$5.00',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'You Will Receive',
                              style: TextStyle(
                                color: AppTheme.mediumColor,
                              ),
                            ),
                            Text(
                              () {
                                final amount = double.tryParse(_amountController.text) ?? 0;
                                final fee = _withdrawalLimits?['networkFee'] ?? 5.0;
                                final netAmount = amount > fee ? amount - fee : 0;
                                return '\$${netAmount.toStringAsFixed(2)}';
                              }(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 2FA
                  const Text(
                    '2FA Code (if enabled)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.mediumColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextFormField(
                      controller: _twoFactorController,
                      maxLength: 6,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Enter 6-digit code',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        counterText: '',
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      text: 'Confirm Withdrawal',
                      onPressed: _withdraw,
                      isLoading: _isLoading,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Security Notice
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.3),
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      border: const Border(
                        left: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.security,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Security Notice',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.darkColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Withdrawals may require manual approval and can take up to 24 hours during high volume periods. You will receive an email confirmation once processed.',
                                style: TextStyle(
                                  color: AppTheme.mediumColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageButton(String text, double percentage, {bool isMax = false}) {
    return GestureDetector(
      onTap: () => _setPercentage(percentage),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isMax 
              ? AppTheme.primaryColor.withOpacity(0.1) 
              : AppTheme.lightColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMax ? AppTheme.primaryColor : AppTheme.mediumColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMax ? AppTheme.primaryColor : AppTheme.darkColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}