// Abstract payment gateway — real app swaps in RazorpayGateway here.
// ---------------------------------------------------------------
// RAZORPAY PLUG-IN POINT:
//   class RazorpayGateway implements PaymentGateway {
//     final Razorpay _razorpay = Razorpay();
//     Future<PaymentResult> charge({...}) async {
//       _razorpay.open({'key': 'rzp_live_KEY', 'amount': amount * 100, ...});
//       // listen to _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, ...)
//     }
//   }
// ---------------------------------------------------------------

import '../models/enums.dart';

class PaymentResult {
  final bool success;
  final String? transactionId;
  final String? errorMessage;

  const PaymentResult({
    required this.success,
    this.transactionId,
    this.errorMessage,
  });
}

abstract class PaymentGateway {
  /// Attempt to charge [amount] using the given method and credentials.
  Future<PaymentResult> charge({
    required PaymentMethod method,
    required double amount,
    String? upiId,
    String? cardNumber,
    String? cardExpiry,
    String? cardCvv,
    String? cardName,
  });
}
