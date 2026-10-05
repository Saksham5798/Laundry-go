// SchedulingService validates pickup/delivery slot rules.
// Rules (from spec):
//   - Pickup: today to +7 days; if today, time ≥ now+2h; 08:00–20:00.
//   - Delivery: ≥ pickup+24h, ≤ pickup+10 days.

class SlotError {
  final String message;
  const SlotError(this.message);
}

class SchedulingService {
  static const _open = 8;  // 08:00
  static const _close = 20; // 20:00

  /// Returns null on success, or a SlotError describing the problem.
  SlotError? validatePickup(DateTime pickup) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pickupDay = DateTime(pickup.year, pickup.month, pickup.day);

    // Must be within next 7 days.
    if (pickupDay.isBefore(today)) {
      return const SlotError('Pickup date cannot be in the past.');
    }
    if (pickupDay.isAfter(today.add(const Duration(days: 7)))) {
      return const SlotError('Pickup date must be within the next 7 days.');
    }

    // Working hours.
    if (pickup.hour < _open || pickup.hour >= _close) {
      return const SlotError('Pickup time must be between 08:00 and 20:00.');
    }

    // If today, must be ≥ 2h from now.
    if (pickupDay == today) {
      final earliest = now.add(const Duration(hours: 2));
      if (pickup.isBefore(earliest)) {
        return SlotError(
          'Pickup must be at least 2 hours from now (${_fmt(earliest)}).',
        );
      }
    }

    return null; // valid
  }

  /// Returns null on success.
  SlotError? validateDelivery(DateTime pickup, DateTime delivery) {
    // Must be at least 24 hours after pickup.
    final minDelivery = pickup.add(const Duration(hours: 24));
    if (delivery.isBefore(minDelivery)) {
      return const SlotError('Delivery must be at least 24 hours after pickup.');
    }

    // Must not exceed pickup + 10 days.
    final maxDelivery = pickup.add(const Duration(days: 10));
    if (delivery.isAfter(maxDelivery)) {
      return const SlotError('Delivery must be within 10 days of pickup.');
    }

    // Working hours.
    if (delivery.hour < _open || delivery.hour >= _close) {
      return const SlotError('Delivery time must be between 08:00 and 20:00.');
    }

    return null; // valid
  }

  String _fmt(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
