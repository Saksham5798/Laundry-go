// Abstract repository — the real app only talks to this interface.
// Swap LocalOrderRepository for FirebaseOrderRepository here.
// ---------------------------------------------------------------
// FIREBASE PLUG-IN POINT:
//   class FirebaseOrderRepository implements OrderRepository {
//     final FirebaseFirestore _db = FirebaseFirestore.instance;
//     Future<void> save(Order order) => _db.collection('orders').doc(order.id).set(order.toJson());
//     Future<List<Order>> fetchAll() async { ... }
//   }
// ---------------------------------------------------------------

import '../models/index.dart';

abstract class OrderRepository {
  /// Persist (create or update) one order.
  Future<void> save(Order order);

  /// Load all previously saved orders (newest first).
  Future<List<Order>> fetchAll();

  /// Delete a single order by id (used in tests only).
  Future<void> delete(String id);
}
