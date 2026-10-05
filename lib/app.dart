// app.dart — root widget.
// Features a custom, premium desktop sidebar with LaundryGo branding, active glows,
// live order badges, user profile area, and responsive mobile navigation bar.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/order_provider.dart';
import 'core/theme.dart';
import 'core/routes.dart';
import 'core/constants.dart';
import 'screens/dashboard_screen.dart';
import 'screens/services_screen.dart';
import 'screens/schedule_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/tracking_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/settings_screen.dart';

class LaundryGoApp extends StatelessWidget {
  const LaundryGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaundryGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.home,
      routes: {
        AppRoutes.home:     (_) => const AppShell(selectedIndex: 0),
        AppRoutes.orders:   (_) => const AppShell(selectedIndex: 1),
        AppRoutes.tracking: (_) => const AppShell(selectedIndex: 2),
        AppRoutes.settings: (_) => const AppShell(selectedIndex: 3),
        AppRoutes.services: (_) => const ServicesScreen(),
        AppRoutes.schedule: (_) => const ScheduleScreen(),
        AppRoutes.summary:  (_) => const SummaryScreen(),
        AppRoutes.payment:  (_) => const PaymentScreen(),
      },
    );
  }
}

// -----------------------------------------------------------------------
// AppShell: the persistent responsive navigation host.
// On desktop/tablet (width >= 800 pt): Custom premium sidebar on the left.
// On mobile (< 800 pt): Sleek bottom NavigationBar with live active badge.
// -----------------------------------------------------------------------
class AppShell extends StatelessWidget {
  final int selectedIndex;
  const AppShell({super.key, required this.selectedIndex});

  static const _screens = [
    DashboardScreen(),
    OrdersScreen(),
    TrackingScreen(),
    SettingsScreen(),
  ];

  void _onTap(BuildContext context, int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
    } else if (index == 1) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.orders, (r) => false);
    } else if (index == 2) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.tracking, (r) => false);
    } else if (index == 3) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.settings, (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrdersCount = context.watch<OrderProvider>().activeOrders.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppConstants.railBreakpoint;

        if (wide) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                _DesktopSidebar(
                  selectedIndex: selectedIndex,
                  activeOrdersCount: activeOrdersCount,
                  onSelect: (i) => _onTap(context, i),
                ),
                Container(
                  width: 1,
                  color: AppColors.border,
                ),
                Expanded(child: _screens[selectedIndex]),
              ],
            ),
          );
        }

        return Scaffold(
          body: _screens[selectedIndex],
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border, width: 1)),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              selectedIndex: selectedIndex,
              onDestinationSelected: (i) => _onTap(context, i),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home, color: AppColors.primary),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: activeOrdersCount > 0,
                    label: Text('$activeOrdersCount'),
                    backgroundColor: AppColors.primary,
                    textColor: const Color(0xFF070D1D),
                    child: const Icon(Icons.receipt_long_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: activeOrdersCount > 0,
                    label: Text('$activeOrdersCount'),
                    backgroundColor: AppColors.primary,
                    textColor: const Color(0xFF070D1D),
                    child: const Icon(Icons.receipt_long, color: AppColors.primary),
                  ),
                  label: 'Orders',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.location_on_outlined),
                  selectedIcon: Icon(Icons.location_on, color: AppColors.primary),
                  label: 'Tracking',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings, color: AppColors.primary),
                  label: 'Settings',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---- Custom Premium Desktop Sidebar ----
class _DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final int activeOrdersCount;
  final ValueChanged<int> onSelect;

  const _DesktopSidebar({
    required this.selectedIndex,
    required this.activeOrdersCount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo & Branding
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF0284C7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_laundry_service_rounded, color: Color(0xFF070D1D), size: 24),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LaundryGo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'PREMIUM CARE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 36),

          // Navigation Links
          _SidebarNavItem(
            icon: Icons.home_outlined,
            selectedIcon: Icons.home_rounded,
            label: 'Home',
            isSelected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          const SizedBox(height: 8),
          _SidebarNavItem(
            icon: Icons.receipt_long_outlined,
            selectedIcon: Icons.receipt_long_rounded,
            label: 'Orders',
            badgeCount: activeOrdersCount,
            isSelected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),

          const SizedBox(height: 8),
          _SidebarNavItem(
            icon: Icons.location_on_outlined,
            selectedIcon: Icons.location_on_rounded,
            label: 'Tracking',
            isSelected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
          const SizedBox(height: 8),
          _SidebarNavItem(
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings_rounded,
            label: 'Settings',
            isSelected: selectedIndex == 3,
            onTap: () => onSelect(3),
          ),

          const Spacer(),

          // Bottom User Profile Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.surfaceContainer,
                      child: Icon(Icons.person, color: AppColors.primary, size: 20),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.card, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Demo Customer',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Premium Member',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
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

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int badgeCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.16)
                : (_isHovered ? AppColors.surfaceContainer : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? widget.selectedIcon : widget.icon,
                size: 20,
                color: isSelected ? AppColors.primary : (_isHovered ? AppColors.textPrimary : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? AppColors.textPrimary : (_isHovered ? AppColors.textPrimary : AppColors.textSecondary),
                  ),
                ),
              ),
              if (widget.badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.badgeCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF070D1D),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

