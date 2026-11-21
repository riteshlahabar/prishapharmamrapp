import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final int orderId;
  const OrderDetailScreen({required this.orderId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (orders) {
          final order = orders.firstWhere((o) => o.id == orderId, orElse: () => OrderModel(id: 0, customerId: 0, customerName: 'Not Found', items: []));
          if (order.id == 0) {
            return const Center(child: Text('Order not found'));
          }
          return _OrderDetail(order: order);
        },
      ),
    );
  }
}

class _OrderDetail extends StatelessWidget {
  final OrderModel order;
  const _OrderDetail({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order #${order.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Customer: ${order.customerName}'),
                  Text('Date: ${order.date.isEmpty ? 'N/A' : order.date}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...order.items.map((item) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(item.productName),
              subtitle: Text('Qty: ${item.quantity}'),
              trailing: Text('₹${item.price * item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          )),
          const SizedBox(height: 16),
          Card(
            color: Colors.teal[50],
            child: ListTile(
              title: const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              trailing: Text('₹${order.totalAmount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }
}