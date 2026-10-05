// Unit tests for:
//   1. Pricing calculator (subtotal, discount, delivery fee, GST, total)
//   2. Promo code logic
//   3. Schedule validation (pickup & delivery rules)
//   4. Order status transitions (forward-only)
//   5. Luhn algorithm

import 'package:flutter_test/flutter_test.dart';
import 'package:laundrygo/core/luhn.dart';
import 'package:laundrygo/core/constants.dart';
import 'package:laundrygo/data/local_order_repository.dart';
import 'package:laundrygo/data/mock_payment_gateway.dart';
import 'package:laundrygo/data/scheduling_service.dart';
import 'package:laundrygo/models/index.dart';
import 'package:laundrygo/providers/order_provider.dart';

// ---- Helper: build a provider with no persisted data ----
OrderProvider _makeProvider() => OrderProvider(
      repo: LocalOrderRepository(),
      gateway: MockPaymentGateway(),
    );

void main() {
  // ===========================================================
  // 1. Pricing
  // ===========================================================
  group('Pricing', () {
    late OrderProvider p;
    setUp(() => p = _makeProvider());

    test('subtotal is zero for empty cart', () {
      expect(p.subtotal, 0);
    });

    test('subtotal sums price × qty for each service', () {
      p.setQuantity('wash_fold', 2); // 2 × 60 = 120
      p.setQuantity('ironing',   5); // 5 × 15 = 75
      expect(p.subtotal, closeTo(195, 0.001));
    });

    test('delivery fee is 40 when subtotal < 500', () {
      p.setQuantity('wash_fold', 1); // 60
      expect(p.deliveryFee, AppConstants.deliveryFee);
    });

    test('delivery fee is free when subtotal >= 500', () {
      p.setQuantity('wash_fold', 9); // 540
      expect(p.deliveryFee, 0);
    });

    test('GST is 5% on (subtotal - discount)', () {
      p.setQuantity('wash_fold', 2); // 120
      // no promo → gst = 120 * 0.05 = 6
      expect(p.gst, closeTo(6, 0.001));
    });

    test('total rounds to 2 decimals', () {
      p.setQuantity('dry_clean', 1); // 150
      // subtotal=150, fee=40, gst=7.5, total=197.5
      expect(p.total, closeTo(197.5, 0.001));
    });
  });

  // ===========================================================
  // 2. Promo code
  // ===========================================================
  group('Promo code', () {
    late OrderProvider p;
    setUp(() {
      p = _makeProvider();
      p.setQuantity('wash_fold', 2); // subtotal = 120
    });

    test('LAUNDRY10 gives 10% discount', () {
      p.applyPromo('LAUNDRY10');
      expect(p.discount, closeTo(12, 0.001)); // 10% of 120
      expect(p.promoCode, 'LAUNDRY10');
      expect(p.promoError, isNull);
    });

    test('invalid code sets promoError', () {
      p.applyPromo('BADCODE');
      expect(p.promoCode, isNull);
      expect(p.promoError, isNotNull);
    });

    test('promo code is case-insensitive', () {
      p.applyPromo('laundry10');
      expect(p.promoCode, 'LAUNDRY10');
    });

    test('clearPromo resets state', () {
      p.applyPromo('LAUNDRY10');
      p.clearPromo();
      expect(p.promoCode, isNull);
      expect(p.discount, 0);
    });

    test('discount reduces GST base', () {
      p.applyPromo('LAUNDRY10'); // discount=12
      // gst = (120 - 12) * 0.05 = 5.4
      expect(p.gst, closeTo(5.4, 0.001));
    });
  });

  // ===========================================================
  // 3. Schedule validation
  // ===========================================================
  group('SchedulingService', () {
    final svc = SchedulingService();

    test('pickup in past is invalid', () {
      final past = DateTime.now().subtract(const Duration(hours: 3));
      expect(svc.validatePickup(past), isNotNull);
    });

    test('pickup more than 7 days ahead is invalid', () {
      final far = DateTime.now().add(const Duration(days: 8, hours: 10));
      expect(svc.validatePickup(far), isNotNull);
    });

    test('pickup outside working hours is invalid', () {
      final early = DateTime.now()
          .add(const Duration(days: 1))
          .copyWith(hour: 7, minute: 0);
      expect(svc.validatePickup(early), isNotNull);
    });

    test('valid pickup returns null', () {
      final valid = DateTime.now()
          .add(const Duration(days: 1))
          .copyWith(hour: 10, minute: 0);
      expect(svc.validatePickup(valid), isNull);
    });

    test('delivery < 24h after pickup is invalid', () {
      final pickup   = DateTime.now().add(const Duration(days: 1, hours: 10));
      final delivery = pickup.add(const Duration(hours: 12)); // only 12h
      expect(svc.validateDelivery(pickup, delivery), isNotNull);
    });

    test('delivery > 10 days after pickup is invalid', () {
      final pickup   = DateTime.now().add(const Duration(days: 1, hours: 10));
      final delivery = pickup.add(const Duration(days: 11));
      expect(svc.validateDelivery(pickup, delivery), isNotNull);
    });

    test('valid delivery returns null', () {
      final pickup   = DateTime.now().add(const Duration(days: 1)).copyWith(hour: 10);
      final delivery = pickup.add(const Duration(days: 2));
      expect(svc.validateDelivery(pickup, delivery), isNull);
    });
  });

  // ===========================================================
  // 4. Order status transitions
  // ===========================================================
  group('OrderStatus transitions', () {
    test('placed → pickedUp is the first forward step', () {
      expect(OrderStatus.placed.next, OrderStatus.pickedUp);
    });

    test('delivered has no next step (terminal)', () {
      expect(OrderStatus.delivered.next, isNull);
    });

    test('cancelled has no next step', () {
      expect(OrderStatus.cancelled.next, isNull);
    });

    test('isFinal is true for delivered and cancelled', () {
      expect(OrderStatus.delivered.isFinal, isTrue);
      expect(OrderStatus.cancelled.isFinal, isTrue);
      expect(OrderStatus.placed.isFinal, isFalse);
    });

    test('full chain is correct', () {
      final chain = <OrderStatus>[];
      var cur = OrderStatus.placed;
      chain.add(cur);
      while (cur.next != null) {
        cur = cur.next!;
        chain.add(cur);
      }
      expect(chain, [
        OrderStatus.placed,
        OrderStatus.pickedUp,
        OrderStatus.washing,
        OrderStatus.ready,
        OrderStatus.outForDelivery,
        OrderStatus.delivered,
      ]);
    });
  });

  // ===========================================================
  // 5. Luhn algorithm
  // ===========================================================
  group('Luhn', () {
    test('4242424242424242 passes', () {
      expect(luhnCheck('4242424242424242'), isTrue);
    });

    test('4000000000000002 passes Luhn (declines at gateway level)', () {
      expect(luhnCheck('4000000000000002'), isTrue);
    });

    test('5500005555555559 passes (Mastercard test)', () {
      expect(luhnCheck('5500005555555559'), isTrue);
    });

    test('1234567890123456 fails', () {
      expect(luhnCheck('1234567890123456'), isFalse);
    });

    test('empty string fails', () {
      expect(luhnCheck(''), isFalse);
    });

    test('non-digit characters fail', () {
      expect(luhnCheck('4242 4242 4242 4242'), isFalse); // spaces
    });
  });
}

// Extension needed for test helper: copyWith on DateTime
extension _DateTimeCopyWith on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
  }) =>
      DateTime(
        year ?? this.year,
        month ?? this.month,
        day ?? this.day,
        hour ?? this.hour,
        minute ?? this.minute,
        second ?? this.second,
      );
}
