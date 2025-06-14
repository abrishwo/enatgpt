import 'package:cloud_firestore/cloud_firestore.dart';

class UserCredit {
  final String userId;
  final double balance;
  final Timestamp? lastFreeCreditClaimedTimestamp;

  UserCredit({
    required this.userId,
    required this.balance,
    this.lastFreeCreditClaimedTimestamp,
  });

  UserCredit copyWith({
    String? userId,
    double? balance,
    Timestamp? lastFreeCreditClaimedTimestamp,
  }) {
    return UserCredit(
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      lastFreeCreditClaimedTimestamp:
          lastFreeCreditClaimedTimestamp ?? this.lastFreeCreditClaimedTimestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'balance': balance,
      'lastFreeCreditClaimedTimestamp': lastFreeCreditClaimedTimestamp,
    };
  }

  factory UserCredit.fromJson(Map<String, dynamic> json) {
    return UserCredit(
      userId: json['userId'] as String,
      balance: (json['balance'] as num).toDouble(),
      lastFreeCreditClaimedTimestamp:
          json['lastFreeCreditClaimedTimestamp'] as Timestamp?,
    );
  }
}
