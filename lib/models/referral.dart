class Referral {
  final String id;
  final String referrerId;
  final String refereeId;
  final String refereeName;
  final String refereeEmail;
  final double commissionEarned;
  final int level; // 1 for direct, 2 for indirect
  final DateTime joinedAt;
  final double refereeDeposit;
  final bool isActive;
  final double dailyEarnings; // Referral's daily earnings
  final double myDailyCommission; // Your daily commission from this referral
  final double realTimeBalance; // Their real-time balance with pending earnings
  final double pendingEarnings; // Their pending earnings since last update
  final double actualEarningsPerSecond; // Their actual $ per second earnings
  final double myLifetimeEarnings; // Total lifetime earnings from this referral
  final String track; // 'lower' or 'upper' track
  final String trackLabel; // 'Bronze' or 'Bronze Plus'
  final String? levelName; // Their level name (Bronze, Silver, etc.)

  const Referral({
    required this.id,
    required this.referrerId,
    required this.refereeId,
    required this.refereeName,
    required this.refereeEmail,
    required this.commissionEarned,
    required this.level,
    required this.joinedAt,
    required this.refereeDeposit,
    this.isActive = true,
    this.dailyEarnings = 0.0,
    this.myDailyCommission = 0.0,
    this.realTimeBalance = 0.0,
    this.pendingEarnings = 0.0,
    this.actualEarningsPerSecond = 0.0,
    this.myLifetimeEarnings = 0.0,
    this.track = 'lower',
    this.trackLabel = 'Bronze',
    this.levelName,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'],
      referrerId: json['referrerId'],
      refereeId: json['refereeId'],
      refereeName: json['refereeName'],
      refereeEmail: json['refereeEmail'],
      commissionEarned: json['commissionEarned']?.toDouble() ?? 0.0,
      level: json['level'] ?? 1,
      joinedAt: DateTime.parse(json['joinedAt']),
      refereeDeposit: json['refereeDeposit']?.toDouble() ?? 0.0,
      isActive: json['isActive'] ?? true,
      dailyEarnings: json['dailyEarnings']?.toDouble() ?? 0.0,
      myDailyCommission: json['myDailyCommission']?.toDouble() ?? 0.0,
      realTimeBalance: json['realTimeBalance']?.toDouble() ?? 0.0,
      pendingEarnings: json['pendingEarnings']?.toDouble() ?? 0.0,
      actualEarningsPerSecond: json['actualEarningsPerSecond']?.toDouble() ?? 0.0,
      myLifetimeEarnings: json['myEarningsFromThisUser']?['total']?.toDouble() ?? json['commissionEarned']?.toDouble() ?? 0.0,
      track: json['track'] ?? 'lower',
      trackLabel: json['trackLabel'] ?? 'Bronze',
      levelName: json['levelName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrerId': referrerId,
      'refereeId': refereeId,
      'refereeName': refereeName,
      'refereeEmail': refereeEmail,
      'commissionEarned': commissionEarned,
      'level': level,
      'joinedAt': joinedAt.toIso8601String(),
      'refereeDeposit': refereeDeposit,
      'isActive': isActive,
      'dailyEarnings': dailyEarnings,
      'myDailyCommission': myDailyCommission,
    };
  }

  String get levelDisplayName {
    switch (level) {
      case 1:
        return 'Direct Referral';
      case 2:
        return 'Indirect Referral';
      default:
        return 'Level $level Referral';
    }
  }

  String get joinedTimeAgo {
    final now = DateTime.now();
    final difference = now.difference(joinedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  // Add missing getters for compatibility
  String get fullName => refereeName;
  double get earnings => commissionEarned;
  double get totalDeposit => refereeDeposit;
}

class ReferralStats {
  final int directReferrals;
  final int indirectReferrals;
  final double totalCommissions;
  final double monthlyCommissions;
  final int nextMilestoneTarget;
  final double nextMilestoneBonus;
  final int progressToMilestone;

  const ReferralStats({
    required this.directReferrals,
    required this.indirectReferrals,
    required this.totalCommissions,
    required this.monthlyCommissions,
    required this.nextMilestoneTarget,
    required this.nextMilestoneBonus,
    required this.progressToMilestone,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      directReferrals: json['directReferrals'] ?? 0,
      indirectReferrals: json['indirectReferrals'] ?? 0,
      totalCommissions: json['totalCommissions']?.toDouble() ?? 0.0,
      monthlyCommissions: json['monthlyCommissions']?.toDouble() ?? 0.0,
      nextMilestoneTarget: json['nextMilestoneTarget'] ?? 10,
      nextMilestoneBonus: json['nextMilestoneBonus']?.toDouble() ?? 100.0,
      progressToMilestone: json['progressToMilestone'] ?? 0,
    );
  }

  int get totalReferrals => directReferrals + indirectReferrals;
  
  double get milestoneProgress => 
      progressToMilestone / nextMilestoneTarget;
}