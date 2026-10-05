// Payment record attached to every order.

import 'enums.dart';

class Payment {
  final PaymentMethod method;
  PaymentStatus status;
  final String? transactionId; // set on success
  final double amount;

  Payment({
    required this.method,
    required this.status,
    required this.amount,
    this.transactionId,
  });

  Map<String, dynamic> toJson() => {
        'method': method.name,
        'status': status.name,
        'transactionId': transactionId,
        'amount': amount,
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        method: PaymentMethod.values.firstWhere(
          (e) => e.name == json['method'],
          orElse: () => PaymentMethod.cod,
        ),
        status: PaymentStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => PaymentStatus.pending,
        ),
        amount: (json['amount'] as num).toDouble(),
        transactionId: json['transactionId'] as String?,
      );
}
