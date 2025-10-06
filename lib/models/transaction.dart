import 'package:flutter/material.dart';

class Transaction {
  final String id;
  final String userId;
  final String type;
  final double amount;
  final String status;
  final String description;
  final String? txHash;
  final String? walletAddress;
  final String? cryptocurrency;
  final double networkFee;
  final DateTime createdAt;
  final DateTime? processedAt;

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.status,
    required this.description,
    this.txHash,
    this.walletAddress,
    this.cryptocurrency,
    required this.networkFee,
    required this.createdAt,
    this.processedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      type: json['type'],
      amount: json['amount']?.toDouble() ?? 0.0,
      status: json['status'],
      description: json['description'] ?? '',
      txHash: json['txHash'],
      walletAddress: json['walletAddress'],
      cryptocurrency: json['cryptocurrency'],
      networkFee: json['networkFee']?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt']),
      processedAt: json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'status': status,
      'description': description,
      'txHash': txHash,
      'walletAddress': walletAddress,
      'cryptocurrency': cryptocurrency,
      'networkFee': networkFee,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
    };
  }

  // Helper methods
  bool get isIncoming => ['DEPOSIT', 'DAILY_EARNING', 'REFERRAL_COMMISSION', 'MILESTONE_BONUS'].contains(type);
  
  String get formattedAmount {
    final sign = isIncoming ? '+' : '-';
    return '$sign\$${amount.toStringAsFixed(2)}';
  }

  String get typeDisplayName {
    switch (type) {
      case 'DEPOSIT':
        return 'Deposit';
      case 'WITHDRAWAL':
        return 'Withdrawal';
      case 'DAILY_EARNING':
        return 'Daily Earnings';
      case 'REFERRAL_COMMISSION':
        return 'Referral Bonus';
      case 'MILESTONE_BONUS':
        return 'Milestone Bonus';
      default:
        return type;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'COMPLETED':
        return 'Completed';
      case 'FAILED':
        return 'Failed';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String get formattedDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final transactionDate = DateTime(createdAt.year, createdAt.month, createdAt.day);

    if (transactionDate == today) {
      return 'Today, ${_formatTime(createdAt)}';
    } else if (transactionDate == yesterday) {
      return 'Yesterday, ${_formatTime(createdAt)}';
    } else {
      return timeAgo;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0 ? 12 : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }

  IconData get icon {
    switch (type) {
      case 'DEPOSIT':
        return Icons.arrow_downward;
      case 'WITHDRAWAL':
        return Icons.arrow_upward;
      case 'REFERRAL_COMMISSION':
        return Icons.group;
      case 'MILESTONE_BONUS':
        return Icons.card_giftcard;
      case 'DAILY_EARNING':
        return Icons.attach_money;
      default:
        return Icons.receipt;
    }
  }

  bool get isCredit {
    return isIncoming;
  }
}