import 'package:cloud_firestore/cloud_firestore.dart';

class RetailerProduct {
  final String id;
  final String productId;
  final String retailerId;
  final int price; // Retailer's selling price
  final int stock; // Retailer's available stock
  final Timestamp createdAt;
  final Timestamp updatedAt;

  RetailerProduct({
    required this.id,
    required this.productId,
    required this.retailerId,
    required this.price,
    required this.stock,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RetailerProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RetailerProduct(
      id: doc.id,
      productId: data['productId'] as String,
      retailerId: data['retailerId'] as String,
      price: data['price'] as int,
      stock: data['stock'] as int,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'retailerId': retailerId,
      'price': price,
      'stock': stock,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  RetailerProduct copyWith({
    String? id,
    String? productId,
    String? retailerId,
    int? price,
    int? stock,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return RetailerProduct(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      retailerId: retailerId ?? this.retailerId,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}