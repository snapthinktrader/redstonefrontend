class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final bool isVerified;
  final String? referralCode;
  final String? referredBy;
  final int level; // Deposit-based level (1-8)
  final int referralLevel; // Referral-based level (1-9)
  final double walletBalance;
  final double totalEarnings;
  final double pendingEarnings;
  final double pendingReferralCommission; // Real-time commission earnings
  final double pendingIndirectCommission; // Real-time indirect commission
  final int directReferrals;
  final int indirectReferrals;
  final double nextBonusAmount;
  final int nextBonusTarget;
  final double totalDeposit;
  final bool twoFactorEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  String get name => fullName;
  int get currentLevel => level;
  
  // Get actual total earnings (database + pending)
  double get actualTotalEarnings => totalEarnings + pendingEarnings;
  
  // Get total commission earnings (direct + indirect)
  double get totalCommission => pendingReferralCommission + pendingIndirectCommission;

    const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.isVerified,
    this.referralCode,
    this.referredBy,
    required this.level,
    required this.referralLevel,
    required this.walletBalance,
    required this.totalEarnings,
    required this.pendingEarnings,
    this.pendingReferralCommission = 0.0,
    this.pendingIndirectCommission = 0.0,
    required this.directReferrals,
    required this.indirectReferrals,
    required this.nextBonusAmount,
    required this.nextBonusTarget,
    required this.totalDeposit,
    required this.twoFactorEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      fullName: json['fullName'] ?? json['name'] ?? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}',
      isVerified: json['isVerified'] ?? false,
      referralCode: json['referralCode'],
      referredBy: json['referredBy'],
      level: json['currentLevel'] ?? json['level'] ?? 1,  // Deposit-based level
      referralLevel: json['referralLevel'] ?? 1,  // Referral-based level
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
      pendingEarnings: (json['pendingEarnings'] ?? 0.0).toDouble(),
      pendingReferralCommission: (json['pendingReferralCommission'] ?? 0.0).toDouble(),
      pendingIndirectCommission: (json['pendingIndirectCommission'] ?? 0.0).toDouble(),
      directReferrals: json['directReferrals'] ?? 0,
      indirectReferrals: json['indirectReferrals'] ?? 0,
      nextBonusAmount: (json['nextBonusAmount'] ?? 100.0).toDouble(),
      nextBonusTarget: json['nextBonusTarget'] ?? 10,
      totalDeposit: (json['totalDeposit'] ?? 0.0).toDouble(),
      twoFactorEnabled: json['twoFactorEnabled'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'isVerified': isVerified,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'level': level,
      'referralLevel': referralLevel,
      'walletBalance': walletBalance,
      'totalEarnings': totalEarnings,
      'pendingEarnings': pendingEarnings,
      'pendingReferralCommission': pendingReferralCommission,
      'pendingIndirectCommission': pendingIndirectCommission,
      'directReferrals': directReferrals,
      'indirectReferrals': indirectReferrals,
      'nextBonusAmount': nextBonusAmount,
      'nextBonusTarget': nextBonusTarget,
      'totalDeposit': totalDeposit,
      'twoFactorEnabled': twoFactorEnabled,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? fullName,
    bool? isVerified,
    String? referralCode,
    String? referredBy,
    int? level,
    int? referralLevel,
    double? walletBalance,
    double? totalEarnings,
    double? pendingEarnings,
    double? pendingReferralCommission,
    double? pendingIndirectCommission,
    int? directReferrals,
    int? indirectReferrals,
    double? nextBonusAmount,
    int? nextBonusTarget,
    double? totalDeposit,
    bool? twoFactorEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      isVerified: isVerified ?? this.isVerified,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      level: level ?? this.level,
      referralLevel: referralLevel ?? this.referralLevel,
      walletBalance: walletBalance ?? this.walletBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      pendingEarnings: pendingEarnings ?? this.pendingEarnings,
      pendingReferralCommission: pendingReferralCommission ?? this.pendingReferralCommission,
      pendingIndirectCommission: pendingIndirectCommission ?? this.pendingIndirectCommission,
      directReferrals: directReferrals ?? this.directReferrals,
      indirectReferrals: indirectReferrals ?? this.indirectReferrals,
      nextBonusAmount: nextBonusAmount ?? this.nextBonusAmount,
      nextBonusTarget: nextBonusTarget ?? this.nextBonusTarget,
      totalDeposit: totalDeposit ?? this.totalDeposit,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods
  
  // Daily earning rate based on deposit level
  double get dailyEarningRate {
    const rates = {
      1: 0.02,  // Basic: 2%
      2: 0.02,  // Bronze: 2%
      3: 0.025, // Silver: 2.5%
      4: 0.03,  // Gold: 3%
      5: 0.035, // Platinum: 3.5%
      6: 0.04,  // Diamond: 4%
      7: 0.045, // Ascendant: 4.5%
      8: 0.05,  // Radiant: 5%
    };
    return rates[level] ?? 0.02;
  }
  
  // Daily earnings based on deposit level rate
  double get dailyEarnings => walletBalance * dailyEarningRate;
  
  // Deposit level name
  String get levelName {
    const levels = {
      1: 'Basic',
      2: 'Bronze',
      3: 'Silver',
      4: 'Gold',
      5: 'Platinum',
      6: 'Diamond',
      7: 'Ascendant',
      8: 'Radiant',
    };
    return levels[level] ?? 'Level $level';
  }

  // Direct commission rate based on referral level
  double get commissionRate {
    const rates = {
      1: 0.00,  // Level 1: 0% (no commission)
      2: 0.15,  // Level 2: 15%
      3: 0.20,  // Level 3: 20%
      4: 0.25,  // Level 4: 25%
      5: 0.30,  // Level 5: 30%
      6: 0.35,  // Level 6: 35%
      7: 0.40,  // Level 7: 40%
      8: 0.45,  // Level 8: 45%
      9: 0.50,  // Level 9: 50%
    };
    return rates[referralLevel] ?? 0.00;
  }

  // Indirect commission rate based on referral level
  double get indirectCommissionRate {
    const rates = {
      1: 0.00,  // Level 1: 0% (no commission)
      2: 0.02,  // Level 2: 2%
      3: 0.03,  // Level 3: 3%
      4: 0.04,  // Level 4: 4%
      5: 0.05,  // Level 5: 5%
      6: 0.06,  // Level 6: 6%
      7: 0.07,  // Level 7: 7%
      8: 0.08,  // Level 8: 8%
      9: 0.10,  // Level 9: 10%
    };
    return rates[referralLevel] ?? 0.00;
  }
  
  // Referral level name
  String get referralLevelName => 'Level $referralLevel';

  int get totalReferrals => directReferrals + indirectReferrals;

  String get joinedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}