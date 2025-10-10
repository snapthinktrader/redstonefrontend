class Deposit {
  final String id;
  final String userId;
  final String address;
  final String network;
  final double amount;
  final double expectedAmount;
  final double actualAmount;
  final String status;
  final String? transactionHash;
  final String? sweepTransactionHash;
  final String? fromAddress;
  final int? blockNumber;
  final int confirmations;
  final int requiredConfirmations;
  final int addressIndex;
  final String derivationPath;
  final String publicKey;
  final DateTime expiresAt;
  final DateTime? processedAt;
  final String notes;
  final DateTime? lastCheckedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DepositMetadata metadata;
  final bool isHDWallet;
  final String? ownerWallet;
  final String? referenceCode;

  Deposit({
    required this.id,
    required this.userId,
    required this.address,
    required this.network,
    required this.amount,
    required this.expectedAmount,
    required this.actualAmount,
    required this.status,
    this.transactionHash,
    this.sweepTransactionHash,
    this.fromAddress,
    this.blockNumber,
    required this.confirmations,
    required this.requiredConfirmations,
    required this.addressIndex,
    required this.derivationPath,
    required this.publicKey,
    required this.expiresAt,
    this.processedAt,
    required this.notes,
    this.lastCheckedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
    this.isHDWallet = false,
    this.ownerWallet,
    this.referenceCode,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    try {
      return Deposit(
        id: json['_id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        network: json['network']?.toString() ?? 'tron',
        amount: (json['amount'] ?? 0).toDouble(),
        expectedAmount: (json['expectedAmount'] ?? 0).toDouble(),
        actualAmount: (json['actualAmount'] ?? 0).toDouble(),
        status: json['status']?.toString() ?? 'PENDING',
        transactionHash: json['transactionHash']?.toString(),
        sweepTransactionHash: json['sweepTransactionHash']?.toString(),
        fromAddress: json['fromAddress']?.toString(),
        blockNumber: json['blockNumber'],
        confirmations: json['confirmations'] ?? 0,
        requiredConfirmations: json['requiredConfirmations'] ?? 15,
        addressIndex: json['addressIndex'] ?? 0,
        derivationPath: json['derivationPath']?.toString() ?? '',
        publicKey: json['publicKey']?.toString() ?? '',
        expiresAt: json['expiresAt'] != null 
            ? DateTime.parse(json['expiresAt'].toString())
            : DateTime.now().add(const Duration(hours: 1)),
        processedAt: json['processedAt'] != null 
            ? DateTime.parse(json['processedAt'].toString()) 
            : null,
        notes: json['notes']?.toString() ?? '',
        lastCheckedAt: json['lastCheckedAt'] != null 
            ? DateTime.parse(json['lastCheckedAt'].toString()) 
            : null,
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'].toString())
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'].toString())
            : DateTime.now(),
        metadata: DepositMetadata.fromJson(json['metadata'] ?? {}),
        isHDWallet: json['isHDWallet'] ?? false,
        ownerWallet: json['ownerWallet']?.toString(),
        referenceCode: json['referenceCode']?.toString(),
      );
    } catch (e) {
      print('Error parsing Deposit from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'address': address,
      'network': network,
      'amount': amount,
      'expectedAmount': expectedAmount,
      'actualAmount': actualAmount,
      'status': status,
      'transactionHash': transactionHash,
      'fromAddress': fromAddress,
      'blockNumber': blockNumber,
      'confirmations': confirmations,
      'requiredConfirmations': requiredConfirmations,
      'addressIndex': addressIndex,
      'derivationPath': derivationPath,
      'publicKey': publicKey,
      'expiresAt': expiresAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'notes': notes,
      'lastCheckedAt': lastCheckedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata.toJson(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isConfirmed => status == 'CONFIRMED';
  bool get isPending => status == 'PENDING' || status == 'PENDING_CONFIRMATIONS';
  bool get hasTransaction => transactionHash != null && transactionHash!.isNotEmpty;

  String get displayStatus {
    switch (status) {
      case 'PENDING':
        return 'Waiting for payment';
      case 'PENDING_CONFIRMATIONS':
        return 'Confirming ($confirmations/$requiredConfirmations)';
      case 'CONFIRMED':
        return 'Completed';
      case 'EXPIRED':
        return 'Expired';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get networkDisplayName {
    switch (network.toLowerCase()) {
      case 'ethereum':
        return 'Ethereum';
      case 'bsc':
        return 'Binance Smart Chain';
      case 'polygon':
        return 'Polygon';
      case 'tron':
        return 'Tron';
      default:
        return network.toUpperCase();
    }
  }
}

class DepositMetadata {
  final NetworkDetails networkDetails;
  final String usdtContract;

  DepositMetadata({
    required this.networkDetails,
    required this.usdtContract,
  });

  factory DepositMetadata.fromJson(Map<String, dynamic> json) {
    return DepositMetadata(
      networkDetails: NetworkDetails.fromJson(json['networkDetails'] ?? {}),
      usdtContract: json['usdtContract'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'networkDetails': networkDetails.toJson(),
      'usdtContract': usdtContract,
    };
  }
}

class NetworkDetails {
  final String name;
  final String symbol;
  final int chainId;
  final String rpcUrl;

  NetworkDetails({
    required this.name,
    required this.symbol,
    required this.chainId,
    required this.rpcUrl,
  });

  factory NetworkDetails.fromJson(Map<String, dynamic> json) {
    return NetworkDetails(
      name: json['name'] ?? '',
      symbol: json['symbol'] ?? '',
      chainId: json['chainId'] ?? 0,
      rpcUrl: json['rpcUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'symbol': symbol,
      'chainId': chainId,
      'rpcUrl': rpcUrl,
    };
  }
}