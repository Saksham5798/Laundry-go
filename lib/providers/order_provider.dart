// OrderProvider — single ChangeNotifier the UI talks to.
// It owns the cart, draft schedule, price calculation, and order lifecycle.
// It delegates persistence to OrderRepository and charging to PaymentGateway.

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../data/order_repository.dart';
import '../data/payment_gateway.dart';
import '../data/scheduling_service.dart';
import '../core/constants.dart';

/// Possible states during payment processing.
enum PaymentState { idle, processing, success, failure }

class OrderProvider extends ChangeNotifier {
  // ---- Dependencies (injected via constructor) ----
  final OrderRepository _repo;
  final PaymentGateway  _gateway;
  final SchedulingService _scheduling;

  OrderProvider({
    required OrderRepository repo,
    required PaymentGateway gateway,
    SchedulingService? scheduling,
  })  : _repo = repo,        // ignore: prefer_initializing_formals
        _gateway = gateway,  // ignore: prefer_initializing_formals
        _scheduling = scheduling ?? SchedulingService();

  // ---- Persisted state ----
  List<Order> _orders = [];
  List<Order> get orders => List.unmodifiable(_orders);

  // ---- Cart (in-flight booking) ----
  // Map<serviceId, quantity>
  final Map<String, int> _cart = {};
  Map<String, int> get cart => Map.unmodifiable(_cart);

  // Draft address + schedule (filled by ScheduleScreen)
  Address? _draftAddress;
  Schedule? _draftSchedule;
  String? _promoCode;
  String? _promoError;

  Address?  get draftAddress  => _draftAddress;
  Schedule? get draftSchedule => _draftSchedule;
  String?   get promoCode     => _promoCode;
  String?   get promoError    => _promoError;

  // ---- Payment state ----
  PaymentState _paymentState = PaymentState.idle;
  String? _lastTransactionId;
  String? _lastPaymentError;

  PaymentState get paymentState     => _paymentState;
  String? get lastTransactionId     => _lastTransactionId;
  String? get lastPaymentError      => _lastPaymentError;

  // ---- Initialisation ----

  /// Load persisted orders; seed a sample Delivered order on first run.
  Future<void> init() async {
    _orders = await _repo.fetchAll();
    if (_orders.isEmpty) {
      await _seedSampleOrder();
      _orders = await _repo.fetchAll();
    }
    notifyListeners();
  }

  // ---- Cart management ----

  void setQuantity(String serviceId, int qty) {
    if (qty <= 0) {
      _cart.remove(serviceId);
    } else {
      _cart[serviceId] = qty.clamp(1, 50);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _draftAddress = null;
    _draftSchedule = null;
    _promoCode = null;
    _promoError = null;
    notifyListeners();
  }

  void reorder(Order order) {
    _cart.clear();
    for (final item in order.items) {
      _cart[item.service.id] = item.quantity;
    }
    notifyListeners();
  }

  bool get cartIsEmpty => _cart.isEmpty;

  // ---- Draft setters ----

  void setDraftSchedule(Schedule s) {
    _draftSchedule = s;
    notifyListeners();
  }

  void setDraftAddress(Address a) {
    _draftAddress = a;
    notifyListeners();
  }

  // ---- Promo code ----

  void applyPromo(String code) {
    final trimmed = code.trim().toUpperCase();
    if (AppConstants.promoCodes.containsKey(trimmed)) {
      _promoCode  = trimmed;
      _promoError = null;
    } else {
      _promoCode  = null;
      _promoError = 'Invalid promo code.';
    }
    notifyListeners();
  }

  void clearPromo() {
    _promoCode  = null;
    _promoError = null;
    notifyListeners();
  }

  // ---- Pricing (pure calculation, no side-effects) ----

  double get subtotal {
    double s = 0;
    for (final entry in _cart.entries) {
      final svc = _serviceById(entry.key);
      if (svc != null) s += svc.pricePerUnit * entry.value;
    }
    return s;
  }

  double get discount {
    if (_promoCode == null) return 0;
    final rate = AppConstants.promoCodes[_promoCode] ?? 0;
    return subtotal * rate;
  }

  double get deliveryFee =>
      subtotal >= AppConstants.freeDeliveryMin ? 0 : AppConstants.deliveryFee;

  double get gst => (subtotal - discount) * AppConstants.gstRate;

  double get total {
    final raw = subtotal - discount + deliveryFee + gst;
    return double.parse(raw.toStringAsFixed(2));
  }

  // ---- Place order ----

  /// Creates an Order record with Pending payment and saves it.
  Future<Order> placeOrder(PaymentMethod method) async {
    final id = const Uuid().v4();
    final items = _buildLineItems();
    final payment = Payment(
      method: method,
      status: PaymentStatus.pending,
      amount: total,
    );
    final now = DateTime.now();
    final order = Order(
      id: id,
      items: items,
      address: _draftAddress!,
      schedule: _draftSchedule!,
      promoCode: _promoCode,
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
      gst: gst,
      total: total,
      status: OrderStatus.placed,
      payment: payment,
      createdAt: now,
      statusHistory: [
        {'status': OrderStatus.placed.name, 'timestamp': now.toIso8601String()},
      ],
    );
    await _repo.save(order);
    _orders = await _repo.fetchAll();
    notifyListeners();
    return order;
  }

  // ---- Payment ----

  Future<void> processPayment({
    required String orderId,
    required PaymentMethod method,
    String? upiId,
    String? cardNumber,
    String? cardExpiry,
    String? cardCvv,
    String? cardName,
  }) async {
    if (_paymentState == PaymentState.processing) return; // block double-submit
    _paymentState = PaymentState.processing;
    _lastTransactionId = null;
    _lastPaymentError  = null;
    notifyListeners();

    final order = _orderById(orderId);
    if (order == null) {
      _paymentState = PaymentState.failure;
      _lastPaymentError = 'Order not found.';
      notifyListeners();
      return;
    }

    final result = await _gateway.charge(
      method: method,
      amount: order.total,
      upiId: upiId,
      cardNumber: cardNumber,
      cardExpiry: cardExpiry,
      cardCvv: cardCvv,
      cardName: cardName,
    );

    if (result.success) {
      order.payment.status = PaymentStatus.paid;
      _paymentState      = PaymentState.success;
      _lastTransactionId = result.transactionId;
      // COD stays Pending until delivered; gateway always returns success for COD.
      if (method == PaymentMethod.cod) {
        order.payment.status = PaymentStatus.pending;
      }
    } else {
      order.payment.status = PaymentStatus.failed;
      _paymentState        = PaymentState.failure;
      _lastPaymentError    = result.errorMessage;
    }

    await _repo.save(order);
    _orders = await _repo.fetchAll();
    notifyListeners();
  }

  void resetPaymentState() {
    _paymentState = PaymentState.idle;
    notifyListeners();
  }

  // ---- Status lifecycle ----

  /// Advance an order to its next status (forward-only).
  Future<void> advanceStatus(String orderId) async {
    final order = _orderById(orderId);
    if (order == null) return;
    final next = order.status.next;
    if (next == null) return; // already at terminal

    order.status = next;
    order.statusHistory.add({
      'status': next.name,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // COD → Delivered: mark payment Paid.
    if (next == OrderStatus.delivered &&
        order.payment.method == PaymentMethod.cod) {
      order.payment.status = PaymentStatus.paid;
    }

    await _repo.save(order);
    _orders = await _repo.fetchAll();
    notifyListeners();
  }

  /// Cancel an order (only while Placed). Refund if already paid.
  Future<bool> cancelOrder(String orderId) async {
    final order = _orderById(orderId);
    if (order == null || order.status != OrderStatus.placed) return false;

    order.status = OrderStatus.cancelled;
    if (order.payment.status == PaymentStatus.paid) {
      order.payment.status = PaymentStatus.refunded;
    }
    order.statusHistory.add({
      'status': OrderStatus.cancelled.name,
      'timestamp': DateTime.now().toIso8601String(),
    });

    await _repo.save(order);
    _orders = await _repo.fetchAll();
    notifyListeners();
    return true;
  }

  // ---- Helpers ----

  Order? get latestActiveOrder {
    for (final o in _orders) {
      if (!o.status.isFinal) return o;
    }
    return null;
  }

  List<Order> get activeOrders =>
      _orders.where((o) => !o.status.isFinal).toList();

  Order? _orderById(String id) {
    try {
      return _orders.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  LaundryService? _serviceById(String id) {
    try {
      return kServiceCatalog.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ServiceLineItem> _buildLineItems() {
    return _cart.entries.map((e) {
      final svc = _serviceById(e.key)!;
      return ServiceLineItem(service: svc, quantity: e.value);
    }).toList();
  }

  // ---- Sample seed data ----

  Future<void> _seedSampleOrder() async {
    final now = DateTime.now();
    final pickup   = now.subtract(const Duration(days: 3));
    final delivery = now.subtract(const Duration(days: 1));
    final order = Order(
      id: 'sample-001',
      items: [
        ServiceLineItem(
          service: kServiceCatalog.firstWhere((s) => s.id == 'wash_fold'),
          quantity: 3,
        ),
        ServiceLineItem(
          service: kServiceCatalog.firstWhere((s) => s.id == 'ironing'),
          quantity: 5,
        ),
      ],
      address: const Address(
        name: 'Rahul Sharma',
        phone: '9876543210',
        addressLine: '42 Sector 15, Dwarka, New Delhi - 110075',
        type: AddressType.home,
      ),
      schedule: Schedule(pickupDateTime: pickup, deliveryDateTime: delivery),
      subtotal: 255,
      discount: 0,
      deliveryFee: 0,
      gst: 12.75,
      total: 267.75,
      status: OrderStatus.delivered,
      payment: Payment(
        method: PaymentMethod.upi,
        status: PaymentStatus.paid,
        amount: 267.75,
        transactionId: 'TXN-SAMPLE-001',
      ),
      createdAt: pickup.subtract(const Duration(hours: 1)),
      statusHistory: [
        {'status': 'placed',         'timestamp': pickup.subtract(const Duration(hours: 1)).toIso8601String()},
        {'status': 'pickedUp',       'timestamp': pickup.toIso8601String()},
        {'status': 'washing',        'timestamp': pickup.add(const Duration(hours: 4)).toIso8601String()},
        {'status': 'ready',          'timestamp': pickup.add(const Duration(hours: 20)).toIso8601String()},
        {'status': 'outForDelivery', 'timestamp': delivery.subtract(const Duration(hours: 2)).toIso8601String()},
        {'status': 'delivered',      'timestamp': delivery.toIso8601String()},
      ],
    );
    await _repo.save(order);
  }

  // ---- Scheduling delegation (for ScheduleScreen) ----
  SchedulingService get schedulingService => _scheduling;
}
