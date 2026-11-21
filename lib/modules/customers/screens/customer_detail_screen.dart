import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/custom_button.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final int customerId;
  const CustomerDetailScreen({required this.customerId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customer Details')),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (customers) {
          final customer = customers.firstWhere((c) => c.id == customerId, orElse: () => CustomerModel(id: 0, name: 'Not Found'));
          if (customer.id == 0) {
            return const Center(child: Text('Customer not found'));
          }
          return _CustomerDetail(customer: customer);
        },
      ),
    );
  }
}

class _CustomerDetail extends StatelessWidget {
  final CustomerModel customer;
  const _CustomerDetail({required this.customer});

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
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.teal[800],
                    child: Text(
                      customer.name[0],
                      style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(customer.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text(customer.customerType ?? 'Customer', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoTile(icon: Icons.phone, label: 'Phone', value: customer.phone ?? 'N/A'),
          _InfoTile(icon: Icons.location_on, label: 'Address', value: customer.address ?? 'N/A'),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Log Visit',
            icon: Icons.add_task,
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Visit logged')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal[800]),
      title: Text(label, style: TextStyle(color: Colors.grey[600])),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}