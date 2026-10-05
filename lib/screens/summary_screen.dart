// Summary screen — Modern invoice checkout view with detailed service breakdown,
// visual pickup-to-delivery journey, 1-tap coupon chips, and secure payment CTA.
// Styled to the dark theme system (#070D1D, #17233A, #25BDF2).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/index.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/centered_content.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _promoCtrl = TextEditingController();

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Order Summary'),
        centerTitle: true,
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          final schedule = provider.draftSchedule!;
          final address = provider.draftAddress!;

          return Column(
            children: [
              Expanded(
                child: CenteredContent(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    children: [
                      // ---- 1. Items Summary Card ----
                      _ModernCard(
                        title: '🧺 Selected Items',
                        child: Column(
                          children: provider.cart.entries.map((e) {
                            final svc = kServiceCatalog.firstWhere((s) => s.id == e.key);
                            final itemTotal = svc.pricePerUnit * e.value;
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${e.value}x',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        svc.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '₹${itemTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---- 2. Pickup & Delivery Route Journey ----
                      _ModernCard(
                        title: '📅 Pickup & Delivery Schedule',
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainer,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _SchedulePoint(
                                icon: Icons.upload_rounded,
                                iconColor: AppColors.primary,
                                label: 'Pickup from address',
                                time: fmt.format(schedule.pickupDateTime),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 17),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    height: 22,
                                    width: 2,
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                  ),
                                ),
                              ),
                              _SchedulePoint(
                                icon: Icons.download_rounded,
                                iconColor: AppColors.success,
                                label: 'Doorstep Delivery',
                                time: fmt.format(schedule.deliveryDateTime),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---- 3. Delivery Address ----
                      _ModernCard(
                        title: '📍 Delivery Address',
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.location_on, size: 20, color: AppColors.warning),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        address.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainer,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Text(
                                          address.type.label,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+91 ${address.phone}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    address.addressLine,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (address.instructions != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Note: "${address.instructions}"',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---- 4. Interactive Promo Code Card ----
                      _ModernCard(
                        title: '🎁 Offers & Coupons',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: TextField(
                                      controller: _promoCtrl,
                                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                      decoration: InputDecoration(
                                        hintText: 'Enter promo code (e.g. LAUNDRY10)',
                                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorText: provider.promoError,
                                      ),
                                      textCapitalization: TextCapitalization.characters,
                                      onSubmitted: (_) => provider.applyPromo(_promoCtrl.text),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                FilledButton(
                                  onPressed: () {
                                    if (provider.promoCode != null) {
                                      provider.clearPromo();
                                      _promoCtrl.clear();
                                    } else {
                                      provider.applyPromo(_promoCtrl.text);
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: provider.promoCode != null ? AppColors.surfaceContainer : AppColors.primary,
                                    foregroundColor: provider.promoCode != null ? AppColors.textPrimary : const Color(0xFF070D1D),
                                    minimumSize: const Size(82, 44),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(
                                    provider.promoCode != null ? 'Remove' : 'Apply',
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Quick 1-tap coupon chip
                            Row(
                              children: [
                                const Text('Available:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                                const SizedBox(width: 8),
                                ActionChip(
                                  avatar: const Icon(Icons.stars_rounded, size: 16, color: AppColors.secondaryLight),
                                  label: const Text('LAUNDRY10 (10% OFF)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                                  backgroundColor: AppColors.surfaceContainer,
                                  side: const BorderSide(color: AppColors.border),
                                  onPressed: () {
                                    _promoCtrl.text = 'LAUNDRY10';
                                    provider.applyPromo('LAUNDRY10');
                                  },
                                ),
                              ],
                            ),

                            if (provider.promoCode != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Coupon "${provider.promoCode}" applied! You save ₹${provider.discount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ---- 5. Bill Details / Price Breakdown ----
                      _ModernCard(
                        title: '💳 Bill Details',
                        child: Column(
                          children: [
                            _PriceRow(label: 'Item Subtotal', value: '₹${provider.subtotal.toStringAsFixed(2)}'),
                            if (provider.discount > 0)
                              _PriceRow(
                                label: 'Coupon Discount (${provider.promoCode})',
                                value: '-₹${provider.discount.toStringAsFixed(2)}',
                                isGreen: true,
                              ),
                            _PriceRow(
                              label: 'Delivery Fee',
                              value: provider.deliveryFee == 0
                                  ? 'FREE (₹0.00)'
                                  : '₹${provider.deliveryFee.toStringAsFixed(2)}',
                              isGreen: provider.deliveryFee == 0,
                            ),
                            _PriceRow(label: 'Taxes & GST (5%)', value: '₹${provider.gst.toStringAsFixed(2)}'),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1, color: AppColors.borderSubtle),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'To Pay',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  '₹${provider.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // ---- Sticky Proceed to Payment CTA ----
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Grand Total',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                          ),
                          Text(
                            '₹${provider.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.payment),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            backgroundColor: AppColors.primary,
                            foregroundColor: const Color(0xFF070D1D),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Proceed to Payment',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ModernCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SchedulePoint extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String time;

  const _SchedulePoint({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              time,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isGreen;

  const _PriceRow({
    required this.label,
    required this.value,
    this.isGreen = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isGreen ? AppColors.success : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
