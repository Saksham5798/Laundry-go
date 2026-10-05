# LaundryGo

An on-demand laundry pickup and delivery Flutter app built for a B.Tech CSE exam project.

## Prerequisites

- Flutter 3.47+ (`flutter --version`)
- Chrome (for web), or Android emulator/device

## Run Steps

```bash
# 1. Get dependencies
flutter pub get

# 2. Run on Chrome (web)
flutter run -d chrome

# 3. Run on Android emulator (list devices first)
flutter devices
flutter run -d <device-id>

# 4. Analyze
flutter analyze          # should report: No issues found!

# 5. Tests
flutter test             # should report: 29/29 tests passed
```

## Project Structure

```
lib/
├── main.dart            # Entry point, wires Provider
├── app.dart             # MaterialApp, routes, AppShell (nav)
├── core/
│   ├── constants.dart   # Spacing, pricing, promo codes
│   ├── luhn.dart        # Luhn algorithm for card validation
│   ├── routes.dart      # Named route constants
│   └── theme.dart       # Material 3 light+dark theme
├── models/
│   ├── enums.dart       # OrderStatus, PaymentStatus, etc.
│   ├── laundry_service.dart # Service catalog
│   ├── service_line_item.dart
│   ├── address.dart
│   ├── schedule.dart
│   ├── payment.dart
│   └── order.dart
├── data/
│   ├── order_repository.dart       # Abstract interface
│   ├── local_order_repository.dart # SharedPreferences impl
│   ├── payment_gateway.dart        # Abstract interface
│   ├── mock_payment_gateway.dart   # Mock with Luhn + decline card
│   └── scheduling_service.dart     # Slot validation logic
├── providers/
│   └── order_provider.dart # ChangeNotifier, all business logic
├── screens/
│   ├── dashboard_screen.dart
│   ├── services_screen.dart
│   ├── schedule_screen.dart
│   ├── summary_screen.dart
│   ├── payment_screen.dart
│   ├── tracking_screen.dart
│   └── orders_screen.dart
└── widgets/
    ├── service_card.dart
    ├── status_chip.dart
    ├── order_card.dart
    └── centered_content.dart

test/
└── widget_test.dart     # 29 unit tests
docs/
├── FIGMA_FLOW.md
└── VIVA_NOTES.md
```

## Demo Credentials

| Method | Details |
|--------|---------|
| UPI | `test@upi` |
| Card (Success) | `4242 4242 4242 4242`, any future expiry, any CVV |
| Card (Decline) | `4000 0000 0000 0002` |
| Cash on Delivery | No details needed |

Promo code: **LAUNDRY10** (10% off)
