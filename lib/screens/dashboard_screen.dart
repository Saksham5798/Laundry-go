// Dashboard screen — Redesigned according to the exact core design direction:
// Hero area with dynamic greeting, LaundryGo branding, floating bubbles, animated pickup pill;
// Primary "Book a Pickup" CTA with hover arrow animation and cyan glow;
// 10% OFF promotion card with purple/indigo gradient;
// 3 interactive mini feature cards (24h Express, Eco-Friendly, 100% Care);
// 4 service cards with descriptions and hover lift;
// Live active order tracker and recent orders list.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/index.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../widgets/order_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/centered_content.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Consumer<OrderProvider>(
          builder: (context, provider, _) {
            final active = provider.latestActiveOrder;
            final recents = provider.orders.take(5).toList();

            return CustomScrollView(
              slivers: [
                // ---- Hero Section ----
                SliverToBoxAdapter(
                  child: _HeroSection(greeting: _greeting()),
                ),

                // ---- Main Body Content ----
                SliverToBoxAdapter(
                  child: CenteredContent(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Primary CTA: Book a Pickup
                          const _BookPickupButton(),
                          const SizedBox(height: 20),

                          // Promotional Banner (10% OFF FIRST ORDER)
                          _PromotionCard(provider: provider),
                          const SizedBox(height: 24),

                          // Service Benefits (3 Mini Feature Cards)
                          const _ServiceBenefitsRow(),
                          const SizedBox(height: 28),

                          // Active Order Live Tracker (if present)
                          if (active != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const _SectionHeading(title: 'Active Order'),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _PulsingDot(color: AppColors.primary),
                                      SizedBox(width: 6),
                                      Text(
                                        'Live Tracker',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _ActiveOrderCard(order: active, provider: provider),
                            const SizedBox(height: 28),
                          ],

                          // Services Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const _SectionHeading(title: 'Our Services'),
                              _ViewAllButton(
                                onTap: () => Navigator.pushNamed(context, AppRoutes.services),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const _ServicesGrid(),
                          const SizedBox(height: 28),

                          // Fresh Clothes Zero Effort Promo Banner (Wider visual promotional section)
                          const _FreshClothesPromoBanner(),
                          const SizedBox(height: 32),

                          // Recent Orders Section
                          const _SectionHeading(title: 'Recent Orders'),
                          const SizedBox(height: 12),
                          if (recents.isEmpty)
                            const _EmptyRecentOrders()
                          else
                            ...recents.map((o) => OrderCard(order: o)),

                          const SizedBox(height: 36),
                        ],
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, 🌅';
    if (hour < 17) return 'Good afternoon, ☀️';
    return 'Good evening, 🌙';
  }
}

// ---- Hero Section ----
class _HeroSection extends StatelessWidget {
  final String greeting;
  const _HeroSection({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F1B35),
            AppColors.background,
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Stack(
        children: [
          // Background abstract laundry bubbles
          Positioned(
            top: -20,
            right: 40,
            child: CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary.withValues(alpha: 0.04),
            ),
          ),
          Positioned(
            top: 40,
            right: -10,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.secondary.withValues(alpha: 0.05),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Status pill + User avatar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status Pill with animated live green dot
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _PulsingDot(color: AppColors.success),
                          SizedBox(width: 8),
                          Text(
                            'Pickup available in 30 mins',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // User Profile Avatar
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.cardElevated,
                      child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Greeting
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: 4),

                // Headline
                const Text(
                  'Ready for Fresh Clothes? ✨',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),

                // Supporting text
                const Text(
                  'Fresh laundry, picked up and delivered to your door.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Pulsing Live Dot Animation ----
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.5 * _anim.value),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Primary CTA: Book a Pickup Button with Hover Arrow Animation ----
class _BookPickupButton extends StatefulWidget {
  const _BookPickupButton();

  @override
  State<_BookPickupButton> createState() => _BookPickupButtonState();
}

class _BookPickupButtonState extends State<_BookPickupButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -2.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isHovered
                ? [const Color(0xFF38BDF8), const Color(0xFF0284C7)]
                : [AppColors.primary, const Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: _isHovered ? 0.45 : 0.3),
              blurRadius: _isHovered ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.pushNamed(context, AppRoutes.services),
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.local_laundry_service_rounded, size: 24, color: Color(0xFF070D1D)),
                      SizedBox(width: 14),
                      Text(
                        'Book a Pickup',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                          color: Color(0xFF070D1D),
                        ),
                      ),
                    ],
                  ),
                  AnimatedPadding(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.only(left: _isHovered ? 6 : 0),
                    child: const Icon(Icons.arrow_forward_rounded, size: 22, color: Color(0xFF070D1D)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Promotion Card (10% OFF FIRST ORDER) ----
class _PromotionCard extends StatefulWidget {
  final OrderProvider provider;
  const _PromotionCard({required this.provider});

  @override
  State<_PromotionCard> createState() => _PromotionCardState();
}

class _PromotionCardState extends State<_PromotionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B46F6), Color(0xFF7C5CFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withValues(alpha: _isHovered ? 0.45 : 0.28),
              blurRadius: _isHovered ? 18 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.confirmation_num_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '10% OFF FIRST ORDER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Use coupon LAUNDRY10 at checkout',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () {
                widget.provider.applyPromo('LAUNDRY10');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('🎉 Coupon LAUNDRY10 applied to your order!'),
                    backgroundColor: const Color(0xFF4338CA),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4F46E5),
                minimumSize: const Size(72, 38),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Service Benefits (3 Mini Feature Cards) ----
class _ServiceBenefitsRow extends StatelessWidget {
  const _ServiceBenefitsRow();

  @override
  Widget build(BuildContext context) {
    final benefits = [
      (
        icon: Icons.bolt_rounded,
        title: '24h Express',
        subtitle: 'Fast turnaround',
        color: AppColors.warning,
      ),
      (
        icon: Icons.eco_rounded,
        title: 'Eco-Friendly',
        subtitle: 'Gentle on clothes',
        color: AppColors.success,
      ),
      (
        icon: Icons.verified_user_rounded,
        title: '100% Care',
        subtitle: 'Handled with care',
        color: AppColors.primary,
      ),
    ];

    return Row(
      children: benefits.map((b) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _BenefitCard(
              icon: b.icon,
              title: b.title,
              subtitle: b.subtitle,
              color: b.color,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BenefitCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  State<_BenefitCard> createState() => _BenefitCardState();
}

class _BenefitCardState extends State<_BenefitCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -2.0 : 0.0, 0.0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.cardElevated : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered ? widget.color.withValues(alpha: 0.5) : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.3 : 0.1),
              blurRadius: _isHovered ? 10 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(widget.icon, size: 20, color: widget.color),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Services Grid (4 Featured Services with Visual Accents & Popular Badge) ----
class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid();

  @override
  Widget build(BuildContext context) {
    final services = [
      (
        id: 'wash_fold',
        name: 'Wash & Fold',
        desc: 'Fresh, folded & ready',
        imageAsset: 'assets/images/services/wash_fold.jpg',
        icon: Icons.local_laundry_service_outlined,
        color: AppColors.primary,
        isPopular: true,
        priceHint: 'From ₹60/kg',
      ),
      (
        id: 'wash_iron',
        name: 'Wash & Iron',
        desc: 'Clean & wrinkle-free',
        imageAsset: 'assets/images/services/wash_iron.jpg',
        icon: Icons.iron_outlined,
        color: const Color(0xFF0D9488),
        isPopular: false,
        priceHint: 'From ₹80/kg',
      ),
      (
        id: 'dry_clean',
        name: 'Dry Cleaning',
        desc: 'Premium garment care',
        imageAsset: 'assets/images/services/dry_cleaning.jpg',
        icon: Icons.dry_cleaning_outlined,
        color: AppColors.secondary,
        isPopular: false,
        priceHint: 'From ₹150/item',
      ),
      (
        id: 'ironing',
        name: 'Ironing',
        desc: 'Sharp & perfectly pressed',
        imageAsset: 'assets/images/services/ironing.jpg',
        icon: Icons.straighten_outlined,
        color: AppColors.warning,
        isPopular: false,
        priceHint: 'From ₹15/item',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final int crossAxisCount = w >= 860 ? 4 : (w >= 480 ? 2 : 1);
        final double childAspectRatio = w >= 860 ? 1.05 : (w >= 480 ? 1.25 : 1.8);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: services.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, i) {
            final s = services[i];
            return _ServiceItemCard(
              id: s.id,
              name: s.name,
              desc: s.desc,
              imageAsset: s.imageAsset,
              icon: s.icon,
              color: s.color,
              isPopular: s.isPopular,
              priceHint: s.priceHint,
            );
          },
        );
      },
    );
  }
}

class _ServiceItemCard extends StatefulWidget {
  final String id;
  final String name;
  final String desc;
  final String imageAsset;
  final IconData icon;
  final Color color;
  final bool isPopular;
  final String priceHint;

  const _ServiceItemCard({
    required this.id,
    required this.name,
    required this.desc,
    required this.imageAsset,
    required this.icon,
    required this.color,
    this.isPopular = false,
    this.priceHint = '',
  });

  @override
  State<_ServiceItemCard> createState() => _ServiceItemCardState();
}

class _ServiceItemCardState extends State<_ServiceItemCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0.0, _isHovered ? -3.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.cardElevated : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered
                ? widget.color.withValues(alpha: 0.6)
                : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: _isHovered ? 0.20 : 0.05),
              blurRadius: _isHovered ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              context.read<OrderProvider>().setQuantity(widget.id, 1);
              Navigator.pushNamed(context, AppRoutes.services);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Compact Image Thumbnail & POPULAR badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Compact 3D Visual Thumbnail (42x42)
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isHovered
                                ? widget.color.withValues(alpha: 0.6)
                                : AppColors.border,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: AnimatedScale(
                            scale: _isHovered ? 1.08 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            child: Image.asset(
                              widget.imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: widget.color.withValues(alpha: 0.15),
                                child: Icon(widget.icon, color: widget.color, size: 20),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Optional POPULAR Badge on top right
                      if (widget.isPopular)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0284C7), AppColors.primary],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF070D1D),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const Spacer(),

                  // Service Name
                  Text(
                    widget.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Subtitle Description
                  Text(
                    widget.desc,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Bottom Action Row: Price Hint + Animated Arrow
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.priceHint,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.color,
                        ),
                      ),
                      AnimatedPadding(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.only(left: _isHovered ? 4 : 0),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: _isHovered ? widget.color : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Wider Visual Promotional Section ("FRESH CLOTHES. ZERO EFFORT.") ----
class _FreshClothesPromoBanner extends StatefulWidget {
  const _FreshClothesPromoBanner();

  @override
  State<_FreshClothesPromoBanner> createState() => _FreshClothesPromoBannerState();
}

class _FreshClothesPromoBannerState extends State<_FreshClothesPromoBanner> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 640;

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isHovered
                    ? [const Color(0xFF162540), const Color(0xFF1B2E4F)]
                    : [const Color(0xFF131D31), const Color(0xFF17243B)],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: _isHovered ? 0.12 : 0.04),
                  blurRadius: _isHovered ? 16 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: wide
                  ? Row(
                      children: [
                        // Left: Copy & CTA
                        Expanded(
                          flex: 6,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                            child: _buildTextAndCta(context),
                          ),
                        ),

                        // Right: Visual graphic
                        Expanded(
                          flex: 5,
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: [
                              Image.asset(
                                'assets/images/branding/promo_banner.jpg',
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        _isHovered ? const Color(0xFF162540) : const Color(0xFF131D31),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.45],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: Image.asset(
                            'assets/images/branding/promo_banner.jpg',
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: _buildTextAndCta(context),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextAndCta(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt, size: 12, color: AppColors.primary),
              SizedBox(width: 4),
              Text(
                'DOORSTEP SERVICE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'FRESH CLOTHES.\nZERO EFFORT.',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'We pick up. We clean. We deliver fresh.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.pushNamed(context, AppRoutes.services),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF0284C7)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Book a Pickup',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF070D1D),
                  ),
                ),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 15, color: Color(0xFF070D1D)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ---- View All Button with Hover Animation ----
class _ViewAllButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ViewAllButton({required this.onTap});

  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Text(
                'View all',
                style: TextStyle(
                  color: _isHovered ? AppColors.primaryLight : AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedPadding(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.only(left: _isHovered ? 4 : 0),
                child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Active Order Card ----
class _ActiveOrderCard extends StatelessWidget {
  final Order order;
  final OrderProvider provider;
  const _ActiveOrderCard({required this.order, required this.provider});

  @override
  Widget build(BuildContext context) {
    final totalSteps = 6;
    final step = OrderStatus.values.indexOf(order.status) + 1;
    final progress = (step / totalSteps).clamp(0.0, 1.0);
    final canAdvance = order.status.next != null && order.status != OrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.id.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Stage $step of $totalSteps: ${order.status.label}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              OrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceContainer,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons: Track Live + Simulate Stage
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.tracking,
                    arguments: order.id,
                  ),
                  icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                  label: const Text('Track Order', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(42),
                    backgroundColor: AppColors.primary,
                    foregroundColor: const Color(0xFF070D1D),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (canAdvance) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      provider.advanceStatus(order.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Simulated next stage: ${order.status.next?.label}'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.fast_forward_rounded, size: 16),
                    label: const Text('Next Stage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Section Heading ----
class _SectionHeading extends StatelessWidget {
  final String title;
  const _SectionHeading({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// ---- Empty Recent Orders ----
class _EmptyRecentOrders extends StatelessWidget {
  const _EmptyRecentOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.card,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.inbox_outlined, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: 12),
            const Text(
              'No orders yet.\nTap "Book a Pickup" to get clean, fresh laundry!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
