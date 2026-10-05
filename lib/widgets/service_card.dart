// Reusable service card shown on the Services screen and Dashboard.
// Features attractive icon, name, descriptive tag, price per unit,
// animated quantity stepper, tactile tap state, and hover lift elevation.

import 'package:flutter/material.dart';
import '../models/laundry_service.dart';
import '../core/theme.dart';

// Maps the string icon name stored in LaundryService to a Material icon.
IconData _resolveIcon(String name) {
  const map = {
    'local_laundry_service': Icons.local_laundry_service_outlined,
    'iron':                  Icons.iron_outlined,
    'dry_cleaning':          Icons.dry_cleaning_outlined,
    'straighten':            Icons.straighten_outlined,
    'cleaning_services':     Icons.cleaning_services_outlined,
    'hotel':                 Icons.hotel_outlined,
  };
  return map[name] ?? Icons.local_laundry_service_outlined;
}

String _getServiceSubtitle(String id) {
  switch (id) {
    case 'wash_fold':  return 'Fresh, folded & ready';
    case 'wash_iron':  return 'Clean and wrinkle-free';
    case 'dry_clean':  return 'Premium garment care';
    case 'ironing':    return 'Sharp & perfectly pressed';
    case 'shoe_clean': return 'Deep sanitized cleaning';
    case 'blanket':    return 'Heavy quilt & bedding care';
    default:           return 'Professional cleaning';
  }
}

String? _getServiceTag(String id) {
  switch (id) {
    case 'wash_fold':  return 'Bestseller';
    case 'dry_clean':  return 'Premium';
    case 'ironing':    return 'Fast 24h';
    case 'blanket':    return 'Heavy Care';
    case 'shoe_clean': return 'Delicate';
    default:           return null;
  }
}

String _getServiceImageAsset(String id) {
  switch (id) {
    case 'wash_fold':  return 'assets/images/services/wash_fold.jpg';
    case 'wash_iron':  return 'assets/images/services/wash_iron.jpg';
    case 'dry_clean':  return 'assets/images/services/dry_cleaning.jpg';
    case 'ironing':    return 'assets/images/services/ironing.jpg';
    case 'shoe_clean': return 'assets/images/services/shoe_clean.jpg';
    case 'blanket':    return 'assets/images/services/blanket.jpg';
    default:           return 'assets/images/services/wash_fold.jpg';
  }
}

class ServiceCard extends StatefulWidget {
  final LaundryService service;
  final int quantity;                // current quantity from cart (0 = not selected)
  final ValueChanged<int> onChanged; // called with new qty

  const ServiceCard({
    super.key,
    required this.service,
    required this.quantity,
    required this.onChanged,
  });

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final quantity = widget.quantity;
    final onChanged = widget.onChanged;
    final selected = quantity > 0;
    final tag = _getServiceTag(service.id);
    final subtitle = _getServiceSubtitle(service.id);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Semantics(
        label: '${service.name}, ₹${service.pricePerUnit.toStringAsFixed(0)} per ${service.unit}',
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0.0, _isHovered ? -3.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF102A44)
                : (_isHovered ? AppColors.cardElevated : AppColors.card),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (_isHovered ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: _isHovered ? 0.35 : 0.15),
                blurRadius: _isHovered || selected ? 14 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: quantity == 0 ? () => onChanged(1) : null,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top: Icon avatar & optional category tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : (_isHovered
                                      ? AppColors.primary.withValues(alpha: 0.5)
                                      : AppColors.border),
                              width: selected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: selected
                                    ? AppColors.primary.withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.2),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: AnimatedScale(
                              scale: _isHovered ? 1.08 : 1.0,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              child: Image.asset(
                                _getServiceImageAsset(service.id),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFF1E2E4A),
                                  child: Icon(
                                    _resolveIcon(service.iconAsset),
                                    size: 24,
                                    color: selected ? const Color(0xFF070D1D) : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (tag != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary.withValues(alpha: 0.4)
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: selected ? AppColors.primaryLight : AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),

                    // Middle: Service Name, Subtitle, & Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Text(
                              '₹${service.pricePerUnit.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              ' / ${service.unit}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom: Interactive Stepper
                    _Stepper(
                      quantity: quantity,
                      onChanged: onChanged,
                      selected: selected,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  final bool selected;

  const _Stepper({
    required this.quantity,
    required this.onChanged,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return SizedBox(
        height: 38,
        child: FilledButton.tonal(
          onPressed: () => onChanged(1),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.surfaceContainer,
            foregroundColor: AppColors.textPrimary,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.border),
            ),
            elevation: 0,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 16, color: AppColors.primary),
              SizedBox(width: 4),
              Text('Add', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StepBtn(
            icon: Icons.remove,
            onTap: () => onChanged(quantity - 1),
            color: AppColors.primary,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Text(
              '$quantity',
              key: ValueKey<int>(quantity),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          _StepBtn(
            icon: Icons.add,
            onTap: quantity >= 50 ? null : () => onChanged(quantity + 1),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  const _StepBtn({required this.icon, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: onTap == null ? Colors.transparent : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Icon(
            icon,
            size: 16,
            color: onTap == null ? AppColors.textMuted : color,
          ),
        ),
      ),
    );
  }
}
