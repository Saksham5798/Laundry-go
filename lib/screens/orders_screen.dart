// Orders screen — Modern order-management screen with title, supporting subtitle,
// glowing search input, smooth animated filter chips, empty state illustration, and responsive order list.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/enums.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/order_card.dart';
import '../widgets/centered_content.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  final List<String> _filters = ['All', 'In Progress', 'Delivered', 'Cancelled'];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            final allOrders = provider.orders;

            // Filter by status tab & search query
            final filtered = allOrders.where((order) {
              bool matchesTab = true;
              if (_selectedFilter == 'In Progress') {
                matchesTab = !order.status.isFinal;
              } else if (_selectedFilter == 'Delivered') {
                matchesTab = order.status == OrderStatus.delivered;
              } else if (_selectedFilter == 'Cancelled') {
                matchesTab = order.status == OrderStatus.cancelled;
              }

              if (!matchesTab) return false;

              if (_searchQuery.isNotEmpty) {
                final query = _searchQuery.toLowerCase();
                final matchesId = order.id.toLowerCase().contains(query);
                final matchesItems = order.items.any((i) => i.service.name.toLowerCase().contains(query));
                return matchesId || matchesItems;
              }

              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Section
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'My Orders',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Track and manage all your laundry orders',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Modern Search Bar
                      _ModernSearchBar(
                        controller: _searchCtrl,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        onClear: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                      const SizedBox(height: 14),

                      // Filter Tabs Row
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, i) {
                            final f = _filters[i];
                            final isSelected = _selectedFilter == f;

                            int count = 0;
                            if (f == 'All') {
                              count = allOrders.length;
                            } else if (f == 'In Progress') {
                              count = allOrders.where((o) => !o.status.isFinal).length;
                            } else if (f == 'Delivered') {
                              count = allOrders.where((o) => o.status == OrderStatus.delivered).length;
                            } else if (f == 'Cancelled') {
                              count = allOrders.where((o) => o.status == OrderStatus.cancelled).length;
                            }

                            return _FilterChip(
                              label: '$f ($count)',
                              isSelected: isSelected,
                              onTap: () => setState(() => _selectedFilter = f),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1, color: AppColors.borderSubtle),

                // Orders List or Animated Empty State
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: filtered.isEmpty
                        ? _EmptyOrdersView(filter: _selectedFilter)
                        : CenteredContent(
                            key: ValueKey<String>('$_selectedFilter-$_searchQuery-${filtered.length}'),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) => OrderCard(order: filtered[i]),
                            ),
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---- Modern Search Bar with Focus Glow ----
class _ModernSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ModernSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  State<_ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<_ModernSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? AppColors.primary : AppColors.border,
          width: _isFocused ? 1.5 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search orders by ID or service name...',
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20,
            color: _isFocused ? AppColors.primary : AppColors.textMuted,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                  onPressed: widget.onClear,
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ---- Filter Chip with Smooth Animation ----
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? const Color(0xFF070D1D) : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Empty Orders View ----
class _EmptyOrdersView extends StatelessWidget {
  final String filter;
  const _EmptyOrdersView({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.cardElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_laundry_service_outlined,
                size: 54,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              filter == 'All' ? 'No orders yet' : 'No $filter orders',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your freshly cleaned clothes will appear here.\nReady for clean clothes?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.services),
              icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
              label: const Text('Book a Pickup'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF070D1D),
                minimumSize: const Size(180, 46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
