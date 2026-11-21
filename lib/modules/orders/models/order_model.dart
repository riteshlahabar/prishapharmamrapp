import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderItem {
  final int productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });
}

class OrderModel {
  final int id;
  final int customerId;
  final String customerName;
  final List<OrderItem> items;
  final String status;
  final String date;
  final double totalAmount;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.items,
    this.status = 'Pending',
    this.date = '',
    this.totalAmount = 0.0,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as int,
      customerId: json['customer_id'] as int,
      customerName: json['customer_name'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => OrderItem(
                    productId: i['product_id'] as int,
                    productName: i['product_name'] as String,
                    quantity: i['quantity'] as int,
                    price: (i['price'] as num).toDouble(),
                  ))
              .toList() ??
          [],
      status: json['status'] as String? ?? 'Pending',
      date: json['date'] as String? ?? '',
      totalAmount: json['total_amount'] != null ? (json['total_amount'] as num).toDouble() : 0.0,
    );
  }
}

final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  // TODO: Replace with real API call
  return [
    OrderModel(id: 1, customerId: 1, customerName: 'Dr. Amit Sharma', items: [OrderItem(productId: 1, productName: 'Paracetamol', quantity: 10, price: 40.0)], status: 'Pending', date: '2026-11-21', totalAmount: 400.0),
    OrderModel(id: 2, customerId: 2, customerName: 'MedPlus Pharmacy', items: [OrderItem(productId: 2, productName: 'Amoxicillin', quantity: 5, price: 95.0)], status: 'Confirmed', date: '2026-11-20', totalAmount: 475.0),
  ];
});

final newOrderProvider = StateProvider<List<OrderItem>>((ref) => []);