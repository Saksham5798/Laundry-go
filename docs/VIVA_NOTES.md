# LaundryGo — Viva Notes

Plain-English answers for your B.Tech viva. Read this and you can answer any question the examiner asks.

---

## Architecture Overview

```
UI (Screens + Widgets)
       │  context.read / context.watch
       ▼
OrderProvider (ChangeNotifier)   ← single brain of the app
  ├── Cart (Map<serviceId, qty>)
  ├── Pricing (pure methods: subtotal, discount, gst, total)
  ├── Order lifecycle (place, pay, advance, cancel)
  └── Delegates to ↓
         ├── OrderRepository ← abstract interface
         │       └── LocalOrderRepository (SharedPreferences)
         │                 [or Firebase would plug in here]
         ├── PaymentGateway ← abstract interface
         │       └── MockPaymentGateway (Luhn + 2s delay)
         │                 [or Razorpay would plug in here]
         └── SchedulingService (pure validation functions)
```

---

## What Each Folder Does

| Folder | Purpose |
|--------|---------|
| `lib/core/` | App-wide constants, Luhn algorithm, route names, Material 3 theme |
| `lib/models/` | Pure Dart data classes — no Flutter imports. Each has `toJson`/`fromJson` for persistence |
| `lib/data/` | Persistence (SharedPreferences), mock payment, slot validation. Abstract interfaces separate UI from implementation |
| `lib/providers/` | `OrderProvider` — the single ChangeNotifier. Contains all business logic. UI can only read state from here, never writes directly to models |
| `lib/screens/` | One file per screen. Reads from Provider using `Consumer<OrderProvider>` or `context.read`. No business logic |
| `lib/widgets/` | Reusable components: `ServiceCard`, `StatusChip`, `OrderCard`, `CenteredContent` |

---

## Data Flow of One Complete Order

1. **User opens Services screen** → reads `provider.cart` → `ServiceCard` shows qty
2. **User taps + / −** → calls `provider.setQuantity(id, qty)` → `notifyListeners()` → ServiceCard rebuilds
3. **User taps Continue** → navigates to ScheduleScreen
4. **User fills form** → taps Continue → calls `provider.setDraftSchedule()` and `provider.setDraftAddress()` → navigates to SummaryScreen
5. **Summary renders** → reads `provider.subtotal`, `discount`, `gst`, `total`, `draftAddress`, `draftSchedule` — all pure getters
6. **User applies promo** → `provider.applyPromo('LAUNDRY10')` → checks `AppConstants.promoCodes` map → sets `_promoCode` → discount recalculates
7. **User taps Confirm** → navigates to PaymentScreen
8. **User fills UPI / Card details, taps Pay** →
   - `provider.placeOrder(method)` creates an `Order` object (Pending payment status), saves to `LocalOrderRepository` → persisted to SharedPreferences
   - `provider.processPayment(orderId, ...)` calls `MockPaymentGateway.charge()` → waits 2 seconds (fake delay)
   - On success → `order.payment.status = Paid`, saves again, `_paymentState = success`
   - Success dialog shows transaction ID
9. **User taps Track Order** → `TrackingScreen` receives `orderId` as route argument, finds order in `provider.orders`, renders timeline
10. **User taps Simulate Next Stage** → `provider.advanceStatus(id)` → finds next status in the enum chain → appends new entry to `statusHistory` → saves → rebuilds

---

## Key Flutter Concepts Used

| Concept | Where Used |
|---------|-----------|
| **ChangeNotifier + Provider** | `OrderProvider` — reactive state, no setState in business logic |
| **Consumer\<T\>** | Every screen rebuilds only when Provider calls `notifyListeners()` |
| **Named Routes** | `MaterialApp.routes` + `Navigator.pushNamed` — clean navigation |
| **Abstract Classes / Interfaces** | `OrderRepository`, `PaymentGateway` — swap implementations without changing UI |
| **LayoutBuilder** | Services grid (2/3/4 columns), AppShell (BottomNav vs NavigationRail) |
| **Form + GlobalKey\<FormState\>** | ScheduleScreen address section, PaymentScreen card form — inline validation |
| **TextInputFormatter** | Card number (4×4 groups), expiry (MM/YY auto-slash) |
| **SliverAppBar + CustomScrollView** | Dashboard — collapsing hero header |
| **SharedPreferences** | Persisting JSON-serialised orders across app restarts |
| **async/await** | All repository reads/writes and payment charging |
| **showDatePicker / showTimePicker** | Schedule screen — platform-native pickers |
| **Semantics** | ServiceCard has `Semantics(label: ...)` for screen readers |

---

## 10 Likely Viva Questions (with Short Answers)

### Q1: Why did you use Provider instead of setState?
**A:** `setState` only rebuilds the widget that calls it. Provider's `ChangeNotifier` lets multiple screens and widgets subscribe to the same state and rebuild automatically when it changes — without passing data through constructors.

### Q2: What is the Luhn algorithm and why do you need it?
**A:** Luhn is a simple checksum formula to validate credit card numbers. It catches typos before sending the number to a payment gateway. We apply it client-side so the user gets an immediate "invalid card number" error instead of a server round-trip.

### Q3: Explain the abstract interface pattern you used (OrderRepository, PaymentGateway).
**A:** The UI talks only to the abstract interface. The concrete class (LocalOrderRepository, MockPaymentGateway) is injected in `main.dart`. To switch to Firebase or Razorpay, we write a new class implementing the interface and change one line in `main.dart` — no screens need to change. This is the **Dependency Inversion Principle**.

### Q4: How does pricing work?
**A:** `subtotal = Σ price × qty` for each cart item. `discount = subtotal × promo_rate`. `deliveryFee = 0 if subtotal ≥ 500, else 40`. `gst = (subtotal − discount) × 0.05`. `total = subtotal − discount + deliveryFee + gst`, rounded to 2 decimals.

### Q5: How do you make the UI responsive?
**A:** We wrap layouts in `LayoutBuilder` which gives us the available `maxWidth`. Under 800 pt: `BottomNavigationBar`, 2-column grid. At 600+ pt: 3 columns. At 800+ pt: `NavigationRail` on the left. `CenteredContent` constrains max width to 640 pt on very wide screens.

### Q6: What happens if the payment gateway is down?
**A:** `MockPaymentGateway` always returns a result (success or failure). In production, we'd catch exceptions, show the failure dialog, and set `PaymentStatus.Failed` on the order. The Order object is already saved as "Placed" with "Pending" payment, so the order is not lost.

### Q7: How do you prevent double-submitting the payment form?
**A:** The `_submitting` boolean flag is set to `true` before the async call starts and back to `false` after the dialog closes. The Pay button is disabled (`onPressed: null`) when `_submitting` is true. The Provider also checks `if (_paymentState == processing) return;`.

### Q8: What is SharedPreferences and how do you use it?
**A:** SharedPreferences is a key-value store (like browser localStorage) for small data that survives app restarts. We store the entire orders list as a JSON string under one key (`laundrygo_orders`). On every save/update we read the existing list, replace or append the order, then write the whole list back.

### Q9: Explain the order status lifecycle and why it is forward-only.
**A:** The chain is: Placed → Picked Up → Washing → Ready → Out for Delivery → Delivered. `OrderStatus.next` returns the next step or `null` at the end. The UI only calls `advanceStatus()` which internally calls `.next` — so you can never skip a step or go backward. Cancel is only allowed at "Placed" (before pickup).

### Q10: How does the Material 3 theming work?
**A:** We create a `ThemeData` with `useMaterial3: true` and `ColorScheme.fromSeed(seedColor: 0xFF0288D1)`. Flutter automatically generates a harmonious full palette (primary, secondary, tertiary, surface, containers…). We pass separate light and dark ThemeData to `MaterialApp`, and set `themeMode: ThemeMode.system` so it follows the device setting. All widgets read colors from `Theme.of(context).colorScheme` so they automatically adapt.
