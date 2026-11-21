import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_router.dart';
import '../models/customer_model.dart';

class CustomerListScreen extends ConsumerWidget {
  const CustomerListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (customers) {
          if (customers.isEmpty) {
            return const Center(child: Text('No customers found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal[800],
                    child: Text(
                      customer.name[0],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(customer.customerType ?? 'Customer'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    context.push('${AppRoutes.customerDetail}/${customer.id}');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}