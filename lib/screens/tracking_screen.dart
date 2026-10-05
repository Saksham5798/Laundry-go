// Tracking screen — Professional live order tracker.
// Features search/enter order ID, responsive 2-column layout (timeline + summary),
// vertical progress timeline with active pulse node, and viva stage simulation.
// Styled to the dark theme system (#070D1D, #17233A, #25BDF2).

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/index.dart';
import '../core/theme.dart';
import '../core/routes.dart';
import '../widgets/status_chip.dart';
import '../widgets/centered_content.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final routeArg = ModalRoute.of(context)?.settings.arguments as String?;
      if (routeArg != null) {
        setState(() {
          _selectedOrderId = routeArg;
          _searchCtrl.text = routeArg;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final routeArg = ModalRoute.of(context)?.settings.arguments as String?;
    if (routeArg != null && _selectedOrderId != routeArg) {
      _selectedOrderId = routeArg;
      _searchCtrl.text = routeArg;
    }
  }

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
            final orders = provider.orders;

            // Pick selected order, or latest active, or first available
            Order? currentOrder;
            if (_selectedOrderId != null) {
              final found = orders.where((o) =>
                  o.id.toLowerCase() == _selectedOrderId!.toLowerCase().replaceAll('#', '') ||
                  o.id.toLowerCase() == _selectedOrderId!.toLowerCase());
              if (found.isNotEmpty) {
                currentOrder = found.first;
              }
            }
            currentOrder ??= provider.latestActiveOrder ?? (orders.isNotEmpty ? orders.first : null);

            return CenteredContent(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Page Title & Subtitle
                    const Text(
                      'Track Your Order',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.6,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Follow your laundry from pickup to delivery.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search / Enter Order ID Bar
                    _buildSearchBar(orders),
                    const SizedBox(height: 24),

                    if (currentOrder == null)
                      _buildNoOrderPlaceholder(context)
                    else ...[
                      // Quick Order Pill Selector (if multiple orders exist)
                      if (orders.length > 1) ...[
                        _buildQuickOrderPills(orders, currentOrder),
                        const SizedBox(height: 20),
                      ],

                      // Responsive Main Layout: 2-column on desktop, stacked on mobile
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 840;

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Vertical Timeline & Valet Card (flex: 6)
                                Expanded(
                                  flex: 6,
                                  child: Column(
                                    children: [
                                      _VerticalTimelineCard(order: currentOrder!),
                                      const SizedBox(height: 18),
                                      if (currentOrder.status != OrderStatus.cancelled) ...[
                                        _DeliveryValetCard(order: currentOrder),
                                        const SizedBox(height: 18),
                                      ],
                                      _StageAdvanceCard(order: currentOrder, provider: provider),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),

                                // Right Column: Order Summary Card (flex: 5)
                                Expanded(
                                  flex: 5,
                                  child: _RightOrderSummaryCard(order: currentOrder, provider: provider),
                                ),
                              ],
                            );
                          }

                          // Mobile Stacked Layout
                          return Column(
                            children: [
                              _RightOrderSummaryCard(order: currentOrder!, provider: provider),
                              const SizedBox(height: 18),
                              _VerticalTimelineCard(order: currentOrder),
                              const SizedBox(height: 18),
                              if (currentOrder.status != OrderStatus.cancelled) ...[
                                _DeliveryValetCard(order: currentOrder),
                                const SizedBox(height: 18),
                              ],
                              _StageAdvanceCard(order: currentOrder, provider: provider),
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(List<Order> orders) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Search or enter Order ID (e.g. #F88CD2E1)...',
                hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  setState(() => _selectedOrderId = val.trim());
                }
              },
            ),
          ),
          if (_searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _selectedOrderId = null);
              },
            ),
          const SizedBox(width: 6),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF070D1D),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_searchCtrl.text.trim().isNotEmpty) {
                setState(() => _selectedOrderId = _searchCtrl.text.trim());
              }
            },
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Track Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, size: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickOrderPills(List<Order> orders, Order currentOrder) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          const Text(
            'Your Orders: ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          ...orders.map((o) {
            final isSel = o.id == currentOrder.id;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: isSel,
                label: Text(
                  '#${o.id}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel ? const Color(0xFF070D1D) : AppColors.textSecondary,
                  ),
                ),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.card,
                side: BorderSide(
                  color: isSel ? AppColors.primary : AppColors.border,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onSelected: (_) {
                  setState(() {
                    _selectedOrderId = o.id;
                    _searchCtrl.text = o.id;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNoOrderPlaceholder(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text(
            'No Order Found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Check the order ID or book a new pickup service.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF070D1D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.services),
            child: const Text('Book a Pickup', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Vertical Timeline Card with Status Progression
// ---------------------------------------------------------------------------
class _VerticalTimelineCard extends StatelessWidget {
  final Order order;
  const _VerticalTimelineCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final stages = [
      (
        title: 'Order Placed',
        subtitle: 'Your order has been received',
        status: OrderStatus.placed,
      ),
      (
        title: 'Pickup Scheduled',
        subtitle: 'Our valet rider is on the way',
        status: OrderStatus.placed, // intermediary
      ),
      (
        title: 'Picked Up',
        subtitle: 'Laundry collected successfully',
        status: OrderStatus.pickedUp,
      ),
      (
        title: 'Cleaning & Care',
        subtitle: 'Your clothes are being cleaned & treated',
        status: OrderStatus.washing,
      ),
      (
        title: 'Ready for Delivery',
        subtitle: 'Garments ironed, inspected & packed',
        status: OrderStatus.outForDelivery,
      ),
      (
        title: 'Delivered',
        subtitle: 'Delivered fresh to your doorstep',
        status: OrderStatus.delivered,
      ),
    ];

    final currentIdx = _getOrderStageIndex(order.status);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.timeline_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Order Progress',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              OrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 24),

          // Timeline Step Nodes
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stages.length,
            itemBuilder: (context, i) {
              final stage = stages[i];
              final isCompleted = i < currentIdx;
              final isCurrent = i == currentIdx;
              final isLast = i == stages.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Node & Connecting Line
                    Column(
                      children: [
                        if (isCurrent)
                          _CurrentPulsingNode()
                        else if (isCompleted)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 16, color: Color(0xFF070D1D)),
                          )
                        else
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainer,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border, width: 2),
                            ),
                            child: Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.textMuted,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: isCompleted ? AppColors.success : AppColors.border,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // Stage Title & Subtitle
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stage.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                                color: isCurrent
                                    ? AppColors.primary
                                    : (isCompleted ? AppColors.textPrimary : AppColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              stage.subtitle,
                              style: TextStyle(
                                fontSize: 12,
                                color: isCurrent
                                    ? AppColors.textPrimary
                                    : (isCompleted ? AppColors.textSecondary : AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int _getOrderStageIndex(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 1;
      case OrderStatus.pickedUp:
        return 2;
      case OrderStatus.washing:
        return 3;
      case OrderStatus.ready:
      case OrderStatus.outForDelivery:
        return 4;
      case OrderStatus.delivered:
        return 5;
      case OrderStatus.cancelled:
        return 0;
    }
  }
}

// ---------------------------------------------------------------------------
// Animated Current Step Pulsing Node
// ---------------------------------------------------------------------------
class _CurrentPulsingNode extends StatefulWidget {
  @override
  State<_CurrentPulsingNode> createState() => _CurrentPulsingNodeState();
}

class _CurrentPulsingNodeState extends State<_CurrentPulsingNode> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) => Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5 * _anim.value),
              blurRadius: 10 * _anim.value,
              spreadRadius: 2 * _anim.value,
            ),
          ],
        ),
        child: const Icon(Icons.radio_button_checked, size: 18, color: Color(0xFF070D1D)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Right Side Order Summary Card
// ---------------------------------------------------------------------------
class _RightOrderSummaryCard extends StatelessWidget {
  final Order order;
  final OrderProvider provider;

  const _RightOrderSummaryCard({required this.order, required this.provider});

  @override
  Widget build(BuildContext context) {
    final fmtDate = DateFormat('dd MMM yyyy • hh:mm a');

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_outlined, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order ID',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                      Text(
                        '#${order.id}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              OrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // Services Breakdown
          const Text(
            'Services & Quantity',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
          ),
          const SizedBox(height: 8),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${item.service.name} (${item.quantity} ${item.service.unit})',
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '₹${item.lineTotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // Pickup & Estimated Delivery Timings
          _buildInfoRow(
            'Pickup Date',
            fmtDate.format(order.schedule.pickupDateTime),
            Icons.outbox_rounded,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Estimated Delivery',
            fmtDate.format(order.schedule.deliveryDateTime),
            Icons.move_to_inbox_rounded,
          ),
          const SizedBox(height: 10),
          _buildInfoRow(
            'Delivery Address',
            '${order.address.addressLine} (${order.address.type.name.toUpperCase()})',
            Icons.pin_drop_outlined,
          ),

          const SizedBox(height: 18),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),

          // Total Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
              ),
              Text(
                '₹${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Reorder Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF070D1D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                provider.reorder(order);
                Navigator.pushNamed(context, AppRoutes.summary);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reorder This Basket', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text(
                value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Delivery Partner Valet Card (Rahul Sharma)
// ---------------------------------------------------------------------------
class _DeliveryValetCard extends StatelessWidget {
  final Order order;
  const _DeliveryValetCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: const Icon(Icons.delivery_dining_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Rahul Sharma',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                    Text(
                      '4.9',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.amber),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Text(
                  'Assigned Laundry Valet • Electric Scooter',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.call, size: 18, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling Rahul Sharma (+91 98765 00123)...'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceContainer,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message sent to Valet: "Rider on the way."'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Viva Stage Simulation Card
// ---------------------------------------------------------------------------
class _StageAdvanceCard extends StatelessWidget {
  final Order order;
  final OrderProvider provider;

  const _StageAdvanceCard({required this.order, required this.provider});

  @override
  Widget build(BuildContext context) {
    if (order.status.isFinal) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Presentation / Viva Demo Tool:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
              ),
            ],
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            onPressed: () => provider.advanceStatus(order.id),
            icon: const Icon(Icons.fast_forward_rounded, size: 16),
            label: const Text('Simulate Next Stage →'),
          ),
        ],
      ),
    );
  }
}
