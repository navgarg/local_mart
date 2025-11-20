import 'package:cloud_firestore/cloud_firestore.dart';

/// ---------------- RETAILER WHOLESALER ORDER ITEM ----------------
class RetailerWholesalerOrderItem {
  final String productId;
  final String name;
  final double price; // price per unit (INR)
  final int quantity; // ordered quantity
  final String wholesalerId;
  final String retailerId;
  final String? image;
  final String productPath;

  RetailerWholesalerOrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.wholesalerId,
    required this.retailerId,
    this.image,
    required this.productPath,
  });

  RetailerWholesalerOrderItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    String? wholesalerId,
    String? retailerId,
    String? image,
    String? productPath,
  }) {
    return RetailerWholesalerOrderItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      retailerId: retailerId ?? this.retailerId,
      image: image ?? this.image,
      productPath: productPath ?? this.productPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'wholesalerId': wholesalerId,
        'retailerId': retailerId,
        'image': image,
        'productPath': productPath,
      };

  factory RetailerWholesalerOrderItem.fromJson(Map<String, dynamic> json) =>
      RetailerWholesalerOrderItem(
        productId: json['productId'] ?? '',
        name: json['name'] ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (json['quantity'] as num?)?.toInt() ?? 0,
        wholesalerId: json['wholesalerId'] ?? '',
        retailerId: json['retailerId'] ?? '',
        image: json['image'] as String?,
        productPath: json['productPath'] ?? '',
      );
}

/// ---------------- RETAILER WHOLESALER ORDER MODEL ----------------
class RetailerWholesalerOrder {
  final String id;
  final String retailerId;
  final String wholesalerId;
  final List<RetailerWholesalerOrderItem> items;
  final double totalAmount;
  final String status; // e.g., 'pending', 'confirmed', 'shipped', 'delivered'
  final Timestamp createdAt;
  final DateTime placedAt; // convenience parsed DateTime (from Timestamp)
  final DateTime? expectedDeliveryDate;

  RetailerWholesalerOrder({
    required this.id,
    required this.retailerId,
    required this.wholesalerId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.placedAt,
    this.expectedDeliveryDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'retailerId': retailerId,
        'wholesalerId': wholesalerId,
        'items': items.map((item) => item.toJson()).toList(),
        'totalAmount': totalAmount,
        'status': status,
        'createdAt': createdAt,
        'expectedDeliveryDate': expectedDeliveryDate != null
            ? Timestamp.fromDate(expectedDeliveryDate!)
            : null,
      };

  factory RetailerWholesalerOrder.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RetailerWholesalerOrder(
      id: doc.id,
      retailerId: data['retailerId'] ?? '',
      wholesalerId: data['wholesalerId'] ?? '',
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => RetailerWholesalerOrderItem.fromJson(item))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? '',
      createdAt: data['createdAt'] as Timestamp,
      placedAt: (data['createdAt'] as Timestamp).toDate(),
      expectedDeliveryDate: (data['expectedDeliveryDate'] as Timestamp?)?.toDate(),
    );
  }

  RetailerWholesalerOrder copyWith({
    String? id,
    String? retailerId,
    String? wholesalerId,
    List<RetailerWholesalerOrderItem>? items,
    double? totalAmount,
    String? status,
    Timestamp? createdAt,
    DateTime? placedAt,
    DateTime? expectedDeliveryDate,
  }) {
    return RetailerWholesalerOrder(
      id: id ?? this.id,
      retailerId: retailerId ?? this.retailerId,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      placedAt: placedAt ?? this.placedAt,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
    );
  }
}