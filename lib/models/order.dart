// The central data model — one customer laundry order.
// All business data lives here; Provider wraps a list of these.

import 'enums.dart';
import 'service_line_item.dart';
import 'address.dart';
import 'schedule.dart';
import 'payment.dart';

class Order {
  final String id;
  final List<ServiceLineItem> items;
  final Address address;
  final Schedule schedule;
  final String? promoCode;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double gst;
  final double total;
  OrderStatus status;
  Payment payment;
  final DateTime createdAt;

  // Timeline: each entry is {status, timestamp} so Tracking screen
  // can show the full history.
  final List<Map<String, dynamic>> statusHistory;

  Order({
    required this.id,
    required this.items,
    required this.address,
    required this.schedule,
    this.promoCode,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.gst,
    required this.total,
    required this.status,
    required this.payment,
    required this.createdAt,
    required this.statusHistory,
  });

  // ---- Serialisation ----

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((e) => e.toJson()).toList(),
        'address': address.toJson(),
        'schedule': schedule.toJson(),
        'promoCode': promoCode,
        'subtotal': subtotal,
        'discount': discount,
        'deliveryFee': deliveryFee,
        'gst': gst,
        'total': total,
        'status': status.name,
        'payment': payment.toJson(),
        'createdAt': createdAt.toIso8601String(),
        'statusHistory': statusHistory,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        items: (json['items'] as List)
            .map((e) => ServiceLineItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        address: Address.fromJson(json['address'] as Map<String, dynamic>),
        schedule: Schedule.fromJson(json['schedule'] as Map<String, dynamic>),
        promoCode: json['promoCode'] as String?,
        subtotal: (json['subtotal'] as num).toDouble(),
        discount: (json['discount'] as num).toDouble(),
        deliveryFee: (json['deliveryFee'] as num).toDouble(),
        gst: (json['gst'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        status: OrderStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => OrderStatus.placed,
        ),
        payment: Payment.fromJson(json['payment'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['createdAt'] as String),
        statusHistory:
            (json['statusHistory'] as List).cast<Map<String, dynamic>>(),
      );
}
