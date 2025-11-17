// lib/models/product.dart
import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String description;
  final String image; // base64 string (raw or data URI)
  final int price;
  final int stock;
  final String sellerId;
  final double avgRating;
  final Map<String, dynamic>? extraData;


  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.stock,
    required this.sellerId,
    required this.avgRating,
    this.extraData,
  });

  // Safely parse numeric values coming from Firestore (String/num/int/double)
  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
    return 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  factory Product.fromFirestore(Map<String, dynamic> data, String docId) {
    return Product(
      id: docId,
      name: (data['name'] ?? data['Name'] ?? '') as String,
      description: (data['Description'] ?? data['description'] ?? '') as String,
      image: (data['image'] ?? '') as String,
      price: _toInt(data['price'] ?? data['Price']),
      stock: _toInt(data['stock'] ?? data['Stock']),
      sellerId: (data['sellerId'] ?? data['sellerID'] ?? '') as String,
      avgRating: _toDouble(data['avgRating'] ?? 0),
      extraData: data,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    int? price,
    int? stock,
    String? sellerId,
    double? avgRating,
    Map<String, dynamic>? extraData,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      sellerId: sellerId ?? this.sellerId,
      avgRating: avgRating ?? this.avgRating,
      extraData: extraData ?? this.extraData,
    );
  }

}

