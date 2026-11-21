import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_router.dart';
import '../models/product_model.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No products found'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(Icons.medication, color: Colors.teal[800]),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(product.genericName ?? product.category ?? ''),
                  trailing: product.sellingPrice != null
                      ? Text('₹${product.sellingPrice}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal))
                      : null,
                  onTap: () {
                    context.push('${AppRoutes.productDetail}/${product.id}');
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