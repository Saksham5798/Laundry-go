// Enums shared across the entire app.
// Forward-only status transitions are enforced in OrderProvider.

/// The lifecycle of a laundry order.
enum OrderStatus {
  placed,
  pickedUp,
  washing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}

/// Payment state of an order.
enum PaymentStatus {
  pending,  // COD or unpaid
  paid,
  failed,
  refunded, // cancelled after payment
}

/// How the customer wants to pay.
enum PaymentMethod {
  upi,
  card,
  cod,
}

/// Type of delivery/pickup address.
enum AddressType {
  home,
  office,
  other,
}

// ----- Helper extensions -----

extension OrderStatusExt on OrderStatus {
  /// Human-readable label shown in status chips and timeline.
  String get label {
    switch (this) {
      case OrderStatus.placed:        return 'Order Placed';
      case OrderStatus.pickedUp:      return 'Picked Up';
      case OrderStatus.washing:       return 'Washing';
      case OrderStatus.ready:         return 'Ready for Delivery';
      case OrderStatus.outForDelivery:return 'Out for Delivery';
      case OrderStatus.delivered:     return 'Delivered';
      case OrderStatus.cancelled:     return 'Cancelled';
    }
  }

  /// Returns the next status in the forward-only chain (null at terminal states).
  OrderStatus? get next {
    const chain = [
      OrderStatus.placed,
      OrderStatus.pickedUp,
      OrderStatus.washing,
      OrderStatus.ready,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];
    final idx = chain.indexOf(this);
    if (idx == -1 || idx == chain.length - 1) return null;
    return chain[idx + 1];
  }

  bool get isFinal => this == OrderStatus.delivered || this == OrderStatus.cancelled;
}

extension PaymentStatusExt on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.pending:  return 'Pending';
      case PaymentStatus.paid:     return 'Paid';
      case PaymentStatus.failed:   return 'Failed';
      case PaymentStatus.refunded: return 'Refunded';
    }
  }
}

extension AddressTypeExt on AddressType {
  String get label {
    switch (this) {
      case AddressType.home:   return 'Home';
      case AddressType.office: return 'Office';
      case AddressType.other:  return 'Other';
    }
  }
}
