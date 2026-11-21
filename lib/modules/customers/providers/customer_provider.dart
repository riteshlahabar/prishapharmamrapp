import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_service.dart';
import 'models/customer_model.dart';

/// Provider that fetches all customers from the API
final customerProvider = FutureProvider<List<Customer>>((ref) async {
  final apiService = ref.watch(apiServiceProvider);
  final response = await apiService.getDio().get('/customers');
  return (response.data as List).map((json) => Customer.fromJson(json)).toList();
});

/// Provider that searches customers by query string
final searchCustomerProvider = FutureProvider.family<List<Customer>, String>((query) async {
  final apiService = apiServiceProvider.readOnly;
  final response = await apiService.getDio().get('/customers/search', queryParameters: {'q': query});
  return (response.data as List).map((json) => Customer.fromJson(json)).toList();
});

/// Provider that fetches a single customer by ID
final customerDetailProvider = FutureProvider.family<Customer, int>((id) async {
  final apiService = apiServiceProvider.readOnly;
  final response = await apiService.getDio().get('/customers/$id');
  return Customer.fromJson(response.data);
});

/// Provider that creates a new customer
final createCustomerProvider = FutureProvider.family<Customer, Map<String, dynamic>>((data) async {
  final apiService = apiServiceProvider.readOnly;
  final response = await apiService.getDio().post('/customers', data: data);
  return Customer.fromJson(response.data);
});

/// Provider that updates an existing customer
final updateCustomerProvider = FutureProvider.family<Customer, ({int id, Map<String, dynamic> data})>((params) async {
  final apiService = apiServiceProvider.readOnly;
  final response = await apiService.getDio().put('/customers/${params.id}', data: params.data);
  return Customer.fromJson(response.data);
});

/// Provider that deletes a customer
final deleteCustomerProvider = FutureProvider.family<void, int>((id) async {
  final apiService = apiServiceProvider.readOnly;
  await apiService.getDio().delete('/customers/$id');
});
