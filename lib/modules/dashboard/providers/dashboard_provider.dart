import 'package:flutter_riverpod/flutter_riverpod.dart';

final dashboardProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  // TODO: Replace with real API call
  return {
    'totalVisits': 0,
    'totalOrders': 0,
    'totalCustomers': 0,
    'pendingOrders': 0,
    'monthlyTarget': 0,
  };
});