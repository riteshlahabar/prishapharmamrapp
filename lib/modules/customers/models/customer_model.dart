import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerModel {
  final int id;
  final String name;
  final String? phone;
  final String? address;
  final String? customerType;

  CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.customerType,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      customerType: json['customer_type'] as String?,
    );
  }
}

final customersProvider = FutureProvider<List<CustomerModel>>((ref) async {
  // TODO: Replace with real API call
  return [
    CustomerModel(id: 1, name: 'Dr. Amit Sharma', phone: '9876543210', address: 'Delhi', customerType: 'Doctor'),
    CustomerModel(id: 2, name: 'MedPlus Pharmacy', phone: '9876543211', address: 'Mumbai', customerType: 'Pharmacy'),
    CustomerModel(id: 3, name: 'Dr. Priya Patel', phone: '9876543212', address: 'Ahmedabad', customerType: 'Doctor'),
  ];
});