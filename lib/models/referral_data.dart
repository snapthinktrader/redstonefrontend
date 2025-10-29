/// Model class for referral data received from deep links
class ReferralData {
  final String referralCode;
  final String? referrerName;
  final String targetScreen;
  final DateTime timestamp;

  ReferralData({
    required this.referralCode,
    this.referrerName,
    required this.targetScreen,
    required this.timestamp,
  });

  /// Create from JSON
  factory ReferralData.fromJson(Map<String, dynamic> json) {
    return ReferralData(
      referralCode: json['referralCode'] ?? '',
      referrerName: json['referrerName'],
      targetScreen: json['targetScreen'] ?? 'signup',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'referralCode': referralCode,
      if (referrerName != null) 'referrerName': referrerName,
      'targetScreen': targetScreen,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Check if referral data is valid
  bool get isValid => referralCode.isNotEmpty;

  /// Get display message for UI
  String get displayMessage {
    if (referrerName != null && referrerName!.isNotEmpty) {
      return 'You were referred by $referrerName';
    }
    return 'Referral code applied: $referralCode';
  }

  @override
  String toString() {
    return 'ReferralData(code: $referralCode, name: $referrerName, screen: $targetScreen)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReferralData && other.referralCode == referralCode;
  }

  @override
  int get hashCode => referralCode.hashCode;
}
