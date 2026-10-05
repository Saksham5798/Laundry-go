# LaundryGo — Figma Flow Reference

> Frame size: 390 × 844 pt (iPhone 14 Pro equivalent). All measurements in pt.

---

## Color Tokens

| Token | Hex | Usage |
|-------|-----|-------|
| Primary | `#0288D1` | Buttons, chips, active states |
| PrimaryContainer | `#B3E5FC` | Active card backgrounds |
| Secondary | `#4FC3F7` | Gradient accent |
| Tertiary | `#0097A7` | Hero gradient end |
| Surface | `#FAFAFA` | Screen background |
| SurfaceContainerLow | `#F0F4F8` | Card fills |
| Error | `#B00020` | Error text, cancel button |
| OnPrimary | `#FFFFFF` | Text on primary fill |

## Typography Scale (Material 3)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| displaySmall | 36 | 400 | — |
| headlineMedium | 28 | 700 | App name in hero |
| titleLarge | 22 | 700 | Section titles |
| titleMedium | 16 | 700 | Card headings |
| titleSmall | 14 | 700 | Section labels |
| bodyMedium | 14 | 400 | Body text |
| bodySmall | 12 | 400 | Captions, timestamps |
| labelLarge | 14 | 600 | Order IDs |

## Spacing System (8 pt grid)

| Token | Value |
|-------|-------|
| spaceXS | 4 |
| spaceS | 8 |
| spaceM | 16 |
| spaceL | 24 |
| spaceXL | 32 |

---

## Frame 1 — Dashboard (390 × 844)

```
┌──────────────────────────────┐
│  [Hero Gradient 390×200]      │  ← LinearGradient Primary→Tertiary
│  "Good morning! 🌅"           │  bodyMedium / white α0.8
│  LaundryGo                   │  headlineMedium bold / white
├──────────────────────────────┤
│  [FilledButton] Book a Pickup │  h=52, full width, Primary fill
├──────────────────────────────┤
│  Active Order                 │  titleMedium bold  ← Section header
│  ┌────────────────────────┐  │
│  │ #A1B2C3D4   [Chip]     │  │  labelLarge + OrderStatusChip
│  │ ████████░░░░ 66%       │  │  LinearProgressIndicator h=8
│  │ Step 4 of 6            │  │  bodySmall / onPrimaryContainer
│  │ [Track Order]          │  │  FilledButton.tonal
│  └────────────────────────┘  │  Card / PrimaryContainer bg
├──────────────────────────────┤
│  Our Services                 │  titleMedium bold
│  [Chip] [Chip] [Chip] …      │  ActionChips, horizontal scroll
├──────────────────────────────┤
│  Recent Orders                │  titleMedium bold
│  ┌─────────────────────────┐ │
│  │ #XXXXXXXX   [StatusChip]│ │  OrderCard (see Frame 2 detail)
│  └─────────────────────────┘ │
└──────────────────────────────┘
│ BottomNavigationBar           │  Home | Orders — M3 NavigationBar
└──────────────────────────────┘
```

**Flow arrow**: "Book a Pickup" → Frame 3 (Services)
**Flow arrow**: OrderCard tap → Frame 7 (Tracking)

---

## Frame 2 — OrderCard Component (390 × 88)

```
┌────────────────────────────────────────┐
│  #A1B2C3D    [Wash & Fold ×3, Iron ×5] │
│  Status chip                           │
│  12 Oct 2026, 10:00 AM    ₹267.75      │
└────────────────────────────────────────┘
```
- Card radius: 16
- Padding: 16 all sides
- Tap → Tracking screen

---

## Frame 3 — Services Screen (390 × 844)

```
┌─────────────────────────────┐
│  ← Select Services   [AppBar]│
├─────────────────────────────┤
│  ┌──────┐  ┌──────┐         │  ← 2-column grid, gap=16
│  │ 🧺   │  │ 🔧   │         │     childAspectRatio = 0.75
│  │Wash & │  │Wash & │         │
│  │ Fold  │  │ Iron  │         │
│  │₹60/kg │  │₹80/kg │         │
│  │[-][2][+]│ │ [Add] │         │
│  └──────┘  └──────┘         │
│  … (3 more rows) …           │
├─────────────────────────────┤
│  Total: ₹120.00  [Continue] │  ← Sticky bottom bar h=72
└─────────────────────────────┘
```

**ServiceCard anatomy**: icon badge (primary bg if selected), name titleSmall bold, price bodySmall, stepper row (−/n/+).
Border: 2pt primary when selected, 1pt outlineVariant when not.

**Flow arrow**: Continue → Frame 4 (Schedule)

---

## Frame 4 — Schedule Screen (390 × 844)

```
┌───────────────────────────────┐
│  ← Schedule Pickup  [AppBar]  │
├───────────────────────────────┤
│  🚚 Pickup Details             │  titleMedium bold
│  ┌──────────┐ ┌──────────┐   │
│  │📅 14 Oct │ │⏰ 10:00 AM│  │  ← Date tile | Time tile
│  └──────────┘ └──────────┘   │     each: SurfaceContainerLow, r=12
│  [inline error if invalid]    │     bodySmall red
│  📦 Delivery Details           │
│  ┌──────────┐ ┌──────────┐   │
│  │📅 16 Oct │ │⏰ 12:00 PM│  │
│  └──────────┘ └──────────┘   │
├───────────────────────────────┤
│  📍 Address                   │  titleMedium bold
│  Full Name  [TextField]       │
│  Phone      [TextField]       │
│  Address    [TextField 2row]  │
│  Type       [Dropdown]        │
│  Notes      [TextField 2row]  │
├───────────────────────────────┤
│  [Continue to Summary ▶]      │  FilledButton h=48
└───────────────────────────────┘
```

**Flow arrow**: Continue → Frame 5 (Summary)

---

## Frame 5 — Order Summary (390 × 844)

```
┌────────────────────────────────┐
│  ← Order Summary   [AppBar]    │
├────────────────────────────────┤
│  🧺 Items                       │  SectionCard (SurfaceContainerLow, r=16)
│    Wash & Fold × 2 kg  ₹120.00 │
│    Ironing × 5 items   ₹75.00  │
├────────────────────────────────┤
│  📅 Schedule                   │
│    ↑ Pickup   14 Oct 10:00 AM  │
│    ↓ Delivery 16 Oct 12:00 PM  │
├────────────────────────────────┤
│  📍 Address                    │
│    Rahul · 9876543210          │
│    42 Sector 15, New Delhi     │
│    [Home chip]                 │
├────────────────────────────────┤
│  🎁 Promo Code                 │
│    [________] [Apply]          │
│    ✓ "LAUNDRY10" applied!     │  green text
├────────────────────────────────┤
│  💰 Price Breakdown            │
│    Subtotal          ₹195.00  │
│    Discount (10%)   −₹19.50  │  green
│    Delivery           FREE     │  green (subtotal ≥ 500 rule)
│    GST (5%)          ₹8.78   │
│    ─────────────────────────  │
│    Total             ₹184.28  │  titleMedium bold
├────────────────────────────────┤
│  [Confirm & Pay ₹184.28]      │  sticky FilledButton h=52
└────────────────────────────────┘
```

**Flow arrow**: Confirm → Frame 6 (Payment)

---

## Frame 6 — Payment Screen (390 × 844)

```
┌────────────────────────────────┐
│  ← Payment         [AppBar]    │
├────────────────────────────────┤
│  Amount to Pay   ₹184.28      │  gradient banner, headlineSmall bold
├────────────────────────────────┤
│  Select Payment Method         │  titleMedium bold
│  ┌─────────────────────────┐  │
│  │ [QR icon] UPI       [✓]│  │  ← selected card / PrimaryContainer
│  └─────────────────────────┘  │
│  [ [💳] Credit Card     [ ] ] │  outlineVariant
│  [ [💵] Cash on Delivery [ ]] │
├────────────────────────────────┤
│  UPI ID  [_______________]    │  ← dynamic form per method
├────────────────────────────────┤
│  [Pay ₹184.28]                │  sticky FilledButton h=52
└────────────────────────────────┘

Loading dialog: CircularProgressIndicator + "Processing payment…"
Success dialog: ✅ icon, TXN ID, [Track Order] button
Failure dialog: ❌ icon, error message, [Retry] button
```

**Flow arrow**: Track Order → Frame 7 (Tracking)

---

## Frame 7 — Order Tracking (390 × 844)

```
┌────────────────────────────────┐
│  ← Order Tracking  [AppBar]    │
├────────────────────────────────┤
│  ┌─────────────────────────┐  │  ← Order header card (PrimaryContainer)
│  │ #A1B2C3D4  [StatusChip] │  │
│  │ [PayChip]  ₹184.28      │  │
│  │ Pickup: 14 Oct 10:00 AM │  │
│  │ Delivery: 16 Oct 12:00  │  │
│  └─────────────────────────┘  │
├────────────────────────────────┤
│  ████████████░░░░  66%        │  LinearProgressIndicator h=10, r=5
├────────────────────────────────┤
│  Timeline                      │  titleMedium bold
│  ●─────────────────────────   │
│  │ Order Placed   14 Oct 09:00│  bodyMedium bold (if current)
│  ●                            │
│  │ Picked Up      14 Oct 10:30│
│  ●                            │
│  │ Washing        14 Oct 14:00│
│  ○  (future/not reached)      │  empty dot
├────────────────────────────────┤
│  [▶ Simulate Next Stage]      │  FilledButton h=48 (demo only)
│  [Cancel Order]               │  OutlinedButton, red, only if Placed
└────────────────────────────────┘
```

---

## Navigation Flow Summary

```
Dashboard
    │  Book a Pickup
    ▼
Services Screen
    │  Continue (cart not empty)
    ▼
Schedule Screen
    │  Continue to Summary
    ▼
Summary Screen
    │  Confirm & Pay
    ▼
Payment Screen
    │  Success: Track Order
    ▼
Tracking Screen
    │  Simulate Next Stage (loop)
    ◯  Delivered (terminal)

Dashboard / Orders tab: any OrderCard tap → Tracking
```
