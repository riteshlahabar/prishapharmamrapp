import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';

final ordersProvider = FutureProvider<List<OrderModel>>((ref) async {
  return [
    OrderModel(id: 1, customerName: 'Dr. Sharma', date: '2026-11-21', total: 2500.0, status: 'Confirmed'),
    OrderModel(id: 2, customerName: 'Dr. Patel', date: '2026-11-20', total: 1800.0, status: 'Pending'),
    OrderModel(id: 3, customerName: 'Dr. Gupta', date: '2026-11-19', total: 3200.0, status: 'Delivered'),
  ];
});

final newOrderProvider = StateNotifierProvider<NewOrderNotifier, NewOrderState>((ref) => NewOrderNotifier());

class NewOrderState {
  final String? customerId;
  final List<OrderItem> items;
  final double total;

  NewOrderState({this.customerId, this.items = const [], this.total = 0.0});

  NewOrderState copyWith({String? customerId, List<OrderItem>? items, double? total}) {
    return NewOrderState(
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      total: total ?? this.total,
    );
  }
}

class NewOrderNotifier extends StateNotifier<NewOrderState> {
  NewOrderNotifier() : super(NewOrderState());

  void setCustomer(String id) => state = state.copyWith(customerId: id);

  void addItem(OrderItem item) {
    final newItems = [...state.items, item];
    state = state.copyWith(items: newItems, total: newItems.fold(0.0, (sum, i) => sum + i.subtotal));
  }

  void removeItem(int index) {
    final newItems = [...state.items]..removeAt(index);
    state = state.copyWith(items: newItems, total: newItems.fold(0.0, (sum, i) => sum + i.subtotal));
  }

  void clear() => state = NewOrderState();
}