// Services screen — Interactive laundry service catalog with instant search,
// category filtering, responsive grid, dynamic free delivery meter, and live cart bar.
// Perfectly styled to the dark theme system (#070D1D, #17233A, #25BDF2).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/laundry_service.dart';
import '../core/constants.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/service_card.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Wash & Fold',
    'Ironing',
    'Dry Clean',
    'Special Care',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Services'),
        centerTitle: true,
        actions: [
          Consumer<OrderProvider>(
            builder: (context, provider, _) {
              if (provider.cartIsEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Clear Cart',
                icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.textSecondary),
                onPressed: () {
                  provider.clearCart();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Cart cleared.'),
                      backgroundColor: AppColors.cardElevated,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          final filteredServices = kServiceCatalog.where((svc) {
            final matchesQuery = svc.name.toLowerCase().contains(_searchQuery.toLowerCase());
            if (!matchesQuery) return false;

            if (_selectedCategory == 'All') return true;
            if (_selectedCategory == 'Wash & Fold') return svc.id == 'wash_fold' || svc.id == 'wash_iron';
            if (_selectedCategory == 'Ironing') return svc.id == 'ironing' || svc.id == 'wash_iron';
            if (_selectedCategory == 'Dry Clean') return svc.id == 'dry_clean';
            if (_selectedCategory == 'Special Care') return svc.id == 'blanket' || svc.id == 'shoe_clean';
            return true;
          }).toList();

          return Column(
            children: [
              // Search & Filter header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Column(
                  children: [
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search services (e.g. Ironing, Bedding)...',
                          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textMuted),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                  onPressed: () => setState(() => _searchQuery = ''),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category pills
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final cat = _categories[i];
                          final isSelected = _selectedCategory == cat;
                          return InkWell(
                            onTap: () => setState(() => _selectedCategory = cat),
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary : AppColors.card,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF070D1D) : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Service grid or empty search
              Expanded(
                child: filteredServices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: AppColors.card,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.search_off_rounded, size: 48, color: AppColors.primary),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No matching services found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Try searching for dry cleaning, bedding, or shoes',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : _ServiceGrid(
                        services: filteredServices,
                        provider: provider,
                      ),
              ),

              // Interactive sticky bottom bar with Free Delivery Tracker
              _StickyBottomBar(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  final List<LaundryService> services;
  final OrderProvider provider;
  const _ServiceGrid({required this.services, required this.provider});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 600
                ? 3
                : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            childAspectRatio: 0.72,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: services.length,
          itemBuilder: (context, i) {
            final svc = services[i];
            final qty = provider.cart[svc.id] ?? 0;
            return ServiceCard(
              service: svc,
              quantity: qty,
              onChanged: (q) => provider.setQuantity(svc.id, q),
            );
          },
        );
      },
    );
  }
}

class _StickyBottomBar extends StatelessWidget {
  final OrderProvider provider;
  const _StickyBottomBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.subtotal;
    final canContinue = !provider.cartIsEmpty;

    final totalItemsCount = provider.cart.values.fold<int>(0, (sum, q) => sum + q);
    final freeDeliveryNeeded = AppConstants.freeDeliveryMin - total;
    final isFreeDelivery = total >= AppConstants.freeDeliveryMin;

    return Container(
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Free delivery progress banner (only when cart has items)
              if (canContinue) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFreeDelivery
                        ? AppColors.success.withValues(alpha: 0.12)
                        : AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isFreeDelivery
                          ? AppColors.success.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isFreeDelivery ? Icons.check_circle_rounded : Icons.local_shipping_outlined,
                        size: 16,
                        color: isFreeDelivery ? AppColors.success : AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isFreeDelivery
                              ? '🎉 You unlocked FREE Delivery!'
                              : 'Add ₹${freeDeliveryNeeded.toStringAsFixed(0)} more for FREE Delivery',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isFreeDelivery ? AppColors.success : AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Total & Continue button
              Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Total Items: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$totalItemsCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: canContinue
                          ? () => Navigator.pushNamed(context, AppRoutes.schedule)
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: const Color(0xFF070D1D),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Continue', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
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
