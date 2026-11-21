import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductModel {
  final int id;
  final String name;
  final String? productCode;
  final String? genericName;
  final String? category;
  final double? mrp;
  final double? sellingPrice;
  final int? stockQuantity;

  ProductModel({
    required this.id,
    required this.name,
    this.productCode,
    this.genericName,
    this.category,
    this.mrp,
    this.sellingPrice,
    this.stockQuantity,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int,
      name: json['name'] as String,
      productCode: json['product_code'] as String?,
      genericName: json['generic_name'] as String?,
      category: json['category'] as String?,
      mrp: json['mrp'] != null ? (json['mrp'] as num).toDouble() : null,
      sellingPrice: json['selling_price'] != null ? (json['selling_price'] as num).toDouble() : null,
      stockQuantity: json['stock_quantity'] as int?,
    );
  }
}

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  // TODO: Replace with real API call
  return [
    ProductModel(id: 1, name: 'Paracetamol 500mg', productCode: 'PAR-500', genericName: 'Paracetamol', category: 'Analgesic', mrp: 50.0, sellingPrice: 40.0, stockQuantity: 500),
    ProductModel(id: 2, name: 'Amoxicillin 250mg', productCode: 'AMX-250', genericName: 'Amoxicillin', category: 'Antibiotic', mrp: 120.0, sellingPrice: 95.0, stockQuantity: 200),
    ProductModel(id: 3, name: 'Metformin 500mg', productCode: 'MET-500', genericName: 'Metformin', category: 'Antidiabetic', mrp: 80.0, sellingPrice: 65.0, stockQuantity: 350),
  ];
});