import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final int productId;
  const ProductDetailScreen({required this.productId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Product Details')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (products) {
          final product = products.firstWhere((p) => p.id == productId, orElse: () => ProductModel(id: 0, name: 'Not Found'));
          if (product.id == 0) {
            return const Center(child: Text('Product not found'));
          }
          return _ProductDetail(product: product);
        },
      ),
    );
  }
}

class _ProductDetail extends StatelessWidget {
  final ProductModel product;
  const _ProductDetail({required this.product});

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
                  Icon(Icons.medication, size: 48, color: Colors.teal[800]),
                  const SizedBox(height: 12),
                  Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _InfoTile(label: 'Code', value: product.productCode ?? 'N/A'),
          _InfoTile(label: 'Generic Name', value: product.genericName ?? 'N/A'),
          _InfoTile(label: 'Category', value: product.category ?? 'N/A'),
          _InfoTile(label: 'MRP', value: product.mrp != null ? '₹${product.mrp}' : 'N/A'),
          _InfoTile(label: 'Selling Price', value: product.sellingPrice != null ? '₹${product.sellingPrice}' : 'N/A'),
          _InfoTile(label: 'Stock', value: product.stockQuantity != null ? '${product.stockQuantity} units' : 'N/A'),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}