// SupabaseOrderRepository — persists orders to Supabase.
// Implements the same OrderRepository interface as LocalOrderRepository,
// so the swap in main.dart is a one-liner.
//
// Table schema (run once in the Supabase SQL editor):
//
//   CREATE TABLE IF NOT EXISTS orders (
//     id            TEXT PRIMARY KEY,
//     data          JSONB NOT NULL,
//     created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
//   );
//
//   ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
//   CREATE POLICY "allow_all" ON orders FOR ALL USING (true) WITH CHECK (true);
//
// The full Order is stored as JSONB under the `data` column so that
// schema changes in Dart never require a DB migration.

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/index.dart';
import 'order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  static const _table = 'orders';

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> save(Order order) async {
    await _client.from(_table).upsert(
      {
        'id': order.id,
        'data': order.toJson(),
        'created_at': order.createdAt.toUtc().toIso8601String(),
      },
      onConflict: 'id',
    );
  }

  @override
  Future<List<Order>> fetchAll() async {
    final response = await _client
        .from(_table)
        .select('data')
        .order('created_at', ascending: false);

    return (response as List)
        .map((row) => Order.fromJson(row['data'] as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
