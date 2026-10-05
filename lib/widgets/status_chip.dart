// Status chip: icon + text + colour. Never colour alone (accessibility rule).
// Modernized with pill badges, dark container backgrounds, and vibrant functional accents.

import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../core/theme.dart';

class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, IconData) _style(OrderStatus s) {
    switch (s) {
      case OrderStatus.placed:          return (AppColors.primary, Icons.receipt_long);
      case OrderStatus.pickedUp:        return (AppColors.warning, Icons.local_shipping_outlined);
      case OrderStatus.washing:         return (AppColors.primary, Icons.water_drop_outlined);
      case OrderStatus.ready:           return (AppColors.secondaryLight, Icons.check_circle_outline);
      case OrderStatus.outForDelivery:  return (const Color(0xFFFB923C), Icons.directions_bike);
      case OrderStatus.delivered:       return (AppColors.success, Icons.done_all);
      case OrderStatus.cancelled:       return (AppColors.error, Icons.cancel_outlined);
    }
  }
}

class PaymentStatusChip extends StatelessWidget {
  final PaymentStatus status;
  const PaymentStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _style(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, IconData) _style(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.pending:  return (AppColors.warning, Icons.hourglass_empty);
      case PaymentStatus.paid:     return (AppColors.success, Icons.verified_outlined);
      case PaymentStatus.failed:   return (AppColors.error, Icons.error_outline);
      case PaymentStatus.refunded: return (AppColors.primary, Icons.currency_rupee);
    }
  }
}
