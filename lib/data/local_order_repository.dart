// Concrete repository backed by SharedPreferences.
// Orders are stored as a JSON array under the key 'laundrygo_orders'.
// On cold start this key is absent — that's the empty-state case.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/index.dart';
import 'order_repository.dart';

class LocalOrderRepository implements OrderRepository {
  static const _key = 'laundrygo_orders';

  @override
  Future<void> save(Order order) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadRaw(prefs);
    // Replace existing or append new.
    final idx = all.indexWhere((m) => m['id'] == order.id);
    if (idx >= 0) {
      all[idx] = order.toJson();
    } else {
      all.add(order.toJson());
    }
    await prefs.setString(_key, jsonEncode(all));
  }

  @override
  Future<List<Order>> fetchAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = await _loadRaw(prefs);
    // Newest first.
    final orders = raw.map((m) => Order.fromJson(m)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }

  @override
  Future<void> delete(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final all = await _loadRaw(prefs);
    all.removeWhere((m) => m['id'] == id);
    await prefs.setString(_key, jsonEncode(all));
  }

  // ---- private ----

  Future<List<Map<String, dynamic>>> _loadRaw(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }
}
