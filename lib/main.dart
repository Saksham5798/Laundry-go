// main.dart — entry point.
// Wires up Provider, initialises Supabase, then runs the app.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/order_provider.dart';
import 'data/supabase_order_repository.dart';
import 'data/mock_payment_gateway.dart';
import 'app.dart';

// ─── Supabase credentials ───────────────────────────────────────────────────
const _supabaseUrl    = 'https://reesuacgefhrleupbcwy.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
    '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJlZXN1YWNnZWZocmxldXBiY3d5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTExODU0MzMsImV4cCI6MjEwNjc2MTQzM30'
    '.C_0aaA6lV5Ta8C8lBZB3jtsX0X5g5eT_34P30M9EbHo';
// ────────────────────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise Supabase client (idempotent — safe to call again on hot-restart).
  // supabase_flutter ≥2.18 uses publishableKey; anonKey is the legacy alias.
  await Supabase.initialize(
    url: _supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: _supabaseAnonKey,
  );

  // Build the provider with Supabase-backed repository.
  final provider = OrderProvider(
    repo: SupabaseOrderRepository(),
    gateway: MockPaymentGateway(),
  );
  await provider.init(); // loads persisted orders (seeds sample on first run)

  runApp(
    ChangeNotifierProvider.value(
      value: provider,
      child: const LaundryGoApp(),
    ),
  );
}
