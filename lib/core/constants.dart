// App-wide constants: spacing, border-radius, promo codes, delivery fee, GST.

class AppConstants {
  AppConstants._();

  // Spacing scale (multiples of 8pt)
  static const double spaceXS = 4;
  static const double spaceS  = 8;
  static const double spaceM  = 16;
  static const double spaceL  = 24;
  static const double spaceXL = 32;

  // Card radius
  static const double radius = 16;

  // Pricing
  static const double deliveryFee     = 40;
  static const double freeDeliveryMin = 500; // free if subtotal >= this
  static const double gstRate         = 0.05; // 5%

  // Promo codes
  static const Map<String, double> promoCodes = {
    'LAUNDRY10': 0.10, // 10 % off
  };

  // Maximum content width on wide screens
  static const double maxContentWidth = 640;

  // Navigation breakpoint
  static const double railBreakpoint = 800;
}
