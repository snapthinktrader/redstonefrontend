class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String fullName;
  final bool isVerified;
  final String? referralCode;
  final String? referredBy;
  final int level;
  final double walletBalance;
  final double totalEarnings;
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
    required this.walletBalance,
    required this.totalEarnings,
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
      fullName: json['fullName'] ?? '${json['firstName'] ?? ''} ${json['lastName'] ?? ''}',
      isVerified: json['isVerified'] ?? false,
      referralCode: json['referralCode'],
      referredBy: json['referredBy'],
      level: json['level'] ?? 1,
      walletBalance: (json['walletBalance'] ?? 0.0).toDouble(),
      totalEarnings: (json['totalEarnings'] ?? 0.0).toDouble(),
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
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'name': name,
      'isVerified': isVerified,
      'referralCode': referralCode,
      'referredBy': referredBy,
      'level': level,
      'totalDeposit': totalDeposit,
      'walletBalance': walletBalance,
      'totalEarnings': totalEarnings,
      'currentLevel': currentLevel,
      'directReferrals': directReferrals,
      'twoFactorEnabled': twoFactorEnabled,
      'indirectReferrals': indirectReferrals,
      'nextBonusAmount': nextBonusAmount,
      'nextBonusTarget': nextBonusTarget,
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
    double? walletBalance,
    double? totalEarnings,
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
      walletBalance: walletBalance ?? this.walletBalance,
      totalEarnings: totalEarnings ?? this.totalEarnings,
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
  double get dailyEarnings => walletBalance * 0.02; // 2% daily return
  
  String get levelName {
    switch (level) {
      case 1:
        return 'Bronze';
      case 2:
        return 'Silver';
      case 3:
        return 'Gold';
      case 4:
        return 'Platinum';
      case 5:
        return 'Diamond';
      default:
        return 'Level $level';
    }
  }

  double get commissionRate {
    switch (level) {
      case 1:
        return 0.05; // 5%
      case 2:
        return 0.08; // 8%
      case 3:
        return 0.12; // 12%
      case 4:
        return 0.15; // 15%
      case 5:
        return 0.20; // 20%
      default:
        return 0.05;
    }
  }

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