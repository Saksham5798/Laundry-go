// Mock payment gateway used in development / testing.
// Rules:
//   - Card 4000000000000002 always declines.
//   - Any other Luhn-valid card succeeds (e.g. 4242424242424242).
//   - UPI and COD always succeed.
//   - Simulated 2-second network delay.

import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/enums.dart';
import 'payment_gateway.dart';
import '../core/luhn.dart';

class MockPaymentGateway implements PaymentGateway {
  static const _declineCard = '4000000000000002';

  @override
  Future<PaymentResult> charge({
    required PaymentMethod method,
    required double amount,
    String? upiId,
    String? cardNumber,
    String? cardExpiry,
    String? cardCvv,
    String? cardName,
  }) async {
    // Simulate network round-trip.
    await Future.delayed(const Duration(seconds: 2));

    if (method == PaymentMethod.card) {
      final digits = (cardNumber ?? '').replaceAll(' ', '');
      if (digits == _declineCard) {
        return const PaymentResult(
          success: false,
          errorMessage: 'Card declined by bank. Please try another card.',
        );
      }
      if (!luhnCheck(digits)) {
        return const PaymentResult(
          success: false,
          errorMessage: 'Invalid card number.',
        );
      }
    }

    // UPI and COD always succeed in mock.
    return PaymentResult(
      success: true,
      transactionId: const Uuid().v4().substring(0, 12).toUpperCase(),
    );
  }
}
