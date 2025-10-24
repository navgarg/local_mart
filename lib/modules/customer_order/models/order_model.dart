import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String retailerId; // to group by retailer

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.retailerId,
  });

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'retailerId': retailerId,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'],
    name: json['name'],
    price: (json['price'] as num).toDouble(),
    quantity: json['quantity'],
    retailerId: json['retailerId'],
  );
}

class Address {
  final String id;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String pincode;
  final double lat;
  final double lng;

  Address({
    required this.id,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'line1': line1,
    'line2': line2,
    'city': city,
    'state': state,
    'pincode': pincode,
    'lat': lat,
    'lng': lng,
  };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'],
    line1: json['line1'],
    line2: json['line2'],
    city: json['city'],
    state: json['state'],
    pincode: json['pincode'],
    lat: (json['lat'] as num).toDouble(),
    lng: (json['lng'] as num).toDouble(),
  );
}

class Order {
  final String id;
  final String customerId;
  final String customerName;
  final Address deliveryAddress;
  final List<OrderItem> items;
  final double totalAmount;
  final String paymentMethod; // 'online' | 'cod' | 'pickup'
  final String status; // placed, packed, shipped, out_for_delivery, delivered, cancelled
  final Timestamp createdAt;
  final Map<String, dynamic> perRetailerDelivery; // {retailerId: estimatedDeliveryDateIsoString}

  Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    required this.perRetailerDelivery,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'deliveryAddress': deliveryAddress.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
    'totalAmount': totalAmount,
    'paymentMethod': paymentMethod,
    'status': status,
    'createdAt': createdAt,
    'perRetailerDelivery': perRetailerDelivery,
  };

  factory Order.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Order(
      id: data['id'] ?? doc.id,
      customerId: data['customerId'],
      customerName: data['customerName'],
      deliveryAddress: Address.fromJson(Map<String, dynamic>.from(data['deliveryAddress'])),
      items: (data['items'] as List).map((i) => OrderItem.fromJson(Map<String, dynamic>.from(i))).toList(),
      totalAmount: (data['totalAmount'] as num).toDouble(),
      paymentMethod: data['paymentMethod'],
      status: data['status'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      perRetailerDelivery: Map<String, dynamic>.from(data['perRetailerDelivery'] ?? {}),
    );
  }
}
