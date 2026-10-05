// One line in the cart: a service + how many units the customer wants.

import 'laundry_service.dart';

class ServiceLineItem {
  final LaundryService service;
  final int quantity; // 1–50

  const ServiceLineItem({
    required this.service,
    required this.quantity,
  });

  /// Cost for this line only.
  double get lineTotal => service.pricePerUnit * quantity;

  // JSON helpers so the cart can be serialised into an Order.
  Map<String, dynamic> toJson() => {
        'serviceId': service.id,
        'serviceName': service.name,
        'pricePerUnit': service.pricePerUnit,
        'unit': service.unit,
        'quantity': quantity,
      };

  factory ServiceLineItem.fromJson(Map<String, dynamic> json) {
    // Reconstruct without the full catalog — sufficient for display/storage.
    final svc = LaundryService(
      id: json['serviceId'] as String,
      name: json['serviceName'] as String,
      pricePerUnit: (json['pricePerUnit'] as num).toDouble(),
      unit: json['unit'] as String,
      iconAsset: 'local_laundry_service', // icon not stored; fallback
    );
    return ServiceLineItem(
      service: svc,
      quantity: json['quantity'] as int,
    );
  }
}
