// lib/models/wholesaler_product.dart


import 'package:cloud_firestore/cloud_firestore.dart';

class WholesalerProduct {
  final String id;
  final String name;
  final String description;
  final String image; // base64 string (raw or data URI)
  final int price;
  final int stock;
  final String wholesalerId;
  final double avgRating;
  final Map<String, dynamic>? extraData;


  WholesalerProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.stock,
    required this.wholesalerId,
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

  factory WholesalerProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WholesalerProduct(
      id: doc.id,
      name: (data['name'] ?? data['Name'] ?? '') as String,
      description: (data['Description'] ?? data['description'] ?? '') as String,
      image: (data['image'] ?? '') as String,
      price: _toInt(data['price'] ?? data['Price']),
      stock: _toInt(data['stock'] ?? data['Stock']),
      wholesalerId: (data['wholesalerId'] ?? data['wholesalerID'] ?? '') as String,
      avgRating: _toDouble(data['avgRating'] ?? 0),
      extraData: data,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'image': image,
      'price': price,
      'stock': stock,
      'wholesalerId': wholesalerId,
      'avgRating': avgRating,
      'extraData': extraData,
    };
  }

  WholesalerProduct copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    int? price,
    int? stock,
    String? wholesalerId,
    double? avgRating,
    Map<String, dynamic>? extraData,
  }) {
    return WholesalerProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      avgRating: avgRating ?? this.avgRating,
      extraData: extraData ?? this.extraData,
    );
  }

}