import 'package:flutter/material.dart';
import '../models/order_model.dart';

class CartProvider with ChangeNotifier {
  final Map<String, OrderItem> _items = {}; // key = productId

  Map<String, OrderItem> get items => _items;

  bool get isEmpty => _items.isEmpty;

  double get total {
    return _items.values.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  }

  void addItem(OrderItem item) {
    if (_items.containsKey(item.productId)) {
      final existing = _items[item.productId]!;
      _items[item.productId] = OrderItem(
        productId: existing.productId,
        name: existing.name,
        price: existing.price,
        quantity: existing.quantity + item.quantity,
        retailerId: existing.retailerId,
      );
    } else {
      _items[item.productId] = item;
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void changeQuantity(String productId, int delta) {
    if (!_items.containsKey(productId)) return;
    final e = _items[productId]!;
    final newQty = e.quantity + delta;
    if (newQty <= 0) {
      _items.remove(productId);
    } else {
      _items[productId] = OrderItem(
        productId: e.productId,
        name: e.name,
        price: e.price,
        quantity: newQty,
        retailerId: e.retailerId,
      );
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  List<OrderItem> get itemsList => _items.values.toList();

  // Group items by retailer to compute per-retailer delivery time later
  Map<String, List<OrderItem>> groupedByRetailer() {
    final Map<String, List<OrderItem>> map = {};
    for (var item in _items.values) {
      map[item.retailerId] = (map[item.retailerId] ?? [])..add(item);
    }
    return map;
  }
}
