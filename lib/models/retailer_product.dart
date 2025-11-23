import 'package:cloud_firestore/cloud_firestore.dart';

class RetailerProduct {
  final String id;
  final String name;
  final String description;
  final String image;
  final String retailerId;
  final int price; // Retailer's selling price
  final int stock; // Retailer's available stock
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final String category;

  RetailerProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.retailerId,
    required this.price,
    required this.stock,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
  });

  factory RetailerProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RetailerProduct(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      image: data['image'] as String,
      retailerId: data['retailerId'] as String,
      price: data['price'] as int,
      stock: data['stock'] as int,
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp,
      category: data['category'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'retailerId': retailerId,
      'price': price,
      'stock': stock,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'category': category,
    };
  }

  RetailerProduct copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    String? retailerId,
    int? price,
    int? stock,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    String? category,
  }) {
    return RetailerProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      retailerId: retailerId ?? this.retailerId,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }
}
