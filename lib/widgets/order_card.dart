// A modern, premium order summary card used in Dashboard "Recent Orders" and Orders screen.
// Styled according to the exact design specifications:
// Header with receipt icon, order ID, and status badge;
// Service breakdown with units; formatted date & time; bold price;
// Interactive [ ↻ Reorder ] and [ ↗ Track ] action buttons with hover animations.

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import 'status_chip.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  const OrderCard({super.key, required this.order});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final fmt = DateFormat('dd MMM yyyy • hh:mm a');

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -2.0 : 0.0, 0.0),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.cardElevated : AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.15),
              blurRadius: _isHovered ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Receipt Icon + Order ID + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '#${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 14),

              // Items breakdown list
              ...order.items.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.service.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•  ${item.quantity} ${item.service.unit}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),

              // Date/Time & Price Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        fmt.format(order.createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${order.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: 12),

              // Action Buttons Row: [ ↻ Reorder ] and [ ↗ Track ]
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<OrderProvider>().reorder(order);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${order.items.length} services added to cart!'),
                            action: SnackBarAction(
                              label: 'View Cart',
                              textColor: AppColors.primary,
                              onPressed: () => Navigator.pushNamed(context, AppRoutes.services),
                            ),
                            backgroundColor: AppColors.cardElevated,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                        Navigator.pushNamed(context, AppRoutes.services);
                      },
                      icon: const Icon(Icons.replay_rounded, size: 16),
                      label: const Text('Reorder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        foregroundColor: AppColors.textPrimary,
                        backgroundColor: AppColors.surfaceContainer,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRoutes.tracking,
                        arguments: order.id,
                      ),
                      icon: const Icon(Icons.arrow_outward_rounded, size: 16),
                      label: const Text('Track', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        backgroundColor: AppColors.primary.withValues(alpha: 0.16),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
