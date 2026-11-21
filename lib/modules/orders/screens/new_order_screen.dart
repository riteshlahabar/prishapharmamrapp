import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../../products/models/product_model.dart';

class NewOrderScreen extends ConsumerWidget {
  const NewOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(AsyncValue.guard(() async {
      return <Map<String, dynamic>>[
        {'id': 1, 'name': 'Dr. Amit Sharma'},
        {'id': 2, 'name': 'MedPlus Pharmacy'},
      ];
    }));

    return Scaffold(
      appBar: AppBar(title: const Text('New Order')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Customer', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Text('Error: $e'),
              data: (customers) {
                return DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: customers.map((c) {
                    return DropdownMenuItem(value: c['id'], child: Text(c['name'] as String));
                  }).toList(),
                  onChanged: (val) {},
                );
              },
            ),
            const SizedBox(height: 16),
            const Text('Add Product', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            CustomTextField(label: 'Product Name', icon: Icons.medication),
            const SizedBox(height: 12),
            CustomTextField(label: 'Quantity', icon: Icons.numbers, isNumeric: true),
            const SizedBox(height: 12),
            CustomTextField(label: 'Price (₹)', icon: Icons.attach_money, isNumeric: true),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Place Order',
              icon: Icons.send,
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully')));
              },
            ),
          ],
        ),
      ),
    );
  }
}