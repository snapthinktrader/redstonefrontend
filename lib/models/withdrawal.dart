class Withdrawal {
  final String id;
  final String userId;
  final String toAddress;
  final String network;
  final double amount;
  final String status;
  final String? transactionHash;
  final String? fromAddress;
  final int? blockNumber;
  final String? userNotes;
  final String? adminNotes;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final WithdrawalMetadata metadata;

  Withdrawal({
    required this.id,
    required this.userId,
    required this.toAddress,
    required this.network,
    required this.amount,
    required this.status,
    this.transactionHash,
    this.fromAddress,
    this.blockNumber,
    this.userNotes,
    this.adminNotes,
    this.approvedAt,
    this.approvedBy,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['_id'] ?? '',
      userId: json['userId'] ?? '',
      toAddress: json['toAddress'] ?? '',
      network: json['network'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'PENDING_APPROVAL',
      transactionHash: json['transactionHash'],
      fromAddress: json['fromAddress'],
      blockNumber: json['blockNumber'],
      userNotes: json['userNotes'],
      adminNotes: json['adminNotes'],
      approvedAt: json['approvedAt'] != null 
          ? DateTime.parse(json['approvedAt']) 
          : null,
      approvedBy: json['approvedBy'],
      processedAt: json['processedAt'] != null 
          ? DateTime.parse(json['processedAt']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      metadata: WithdrawalMetadata.fromJson(json['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'toAddress': toAddress,
      'network': network,
      'amount': amount,
      'status': status,
      'transactionHash': transactionHash,
      'fromAddress': fromAddress,
      'blockNumber': blockNumber,
      'userNotes': userNotes,
      'adminNotes': adminNotes,
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'processedAt': processedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata.toJson(),
    };
  }

  bool get isPending => status == 'PENDING_APPROVAL';
  bool get isApproved => status == 'APPROVED';
  bool get isProcessing => status == 'PROCESSING';
  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
  bool get isRejected => status == 'REJECTED';

  String get displayStatus {
    switch (status) {
      case 'PENDING_APPROVAL':
        return 'Pending Approval';
      case 'APPROVED':
        return 'Approved';
      case 'PROCESSING':
        return 'Processing';
      case 'COMPLETED':
        return 'Completed';
      case 'FAILED':
        return 'Failed';
      case 'REJECTED':
        return 'Rejected';
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

class WithdrawalMetadata {
  final NetworkDetails networkDetails;
  final String usdtContract;
  final double? estimatedGasFee;

  WithdrawalMetadata({
    required this.networkDetails,
    required this.usdtContract,
    this.estimatedGasFee,
  });

  factory WithdrawalMetadata.fromJson(Map<String, dynamic> json) {
    return WithdrawalMetadata(
      networkDetails: NetworkDetails.fromJson(json['networkDetails'] ?? {}),
      usdtContract: json['usdtContract'] ?? '',
      estimatedGasFee: json['estimatedGasFee']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'networkDetails': networkDetails.toJson(),
      'usdtContract': usdtContract,
      'estimatedGasFee': estimatedGasFee,
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