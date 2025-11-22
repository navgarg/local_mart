import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/product.dart';

class WholesalerProduct {
  final String id;
  final String name;
  final String description;
  final String image;
  final int price;
  final int stock;
  final String wholesalerId;
  final double avgRating;
  final Map<String, dynamic>? extraData;
  final String sellerId;
  final String sellerType;
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
  }) : sellerId = wholesalerId,
       sellerType = 'wholesaler';

  factory WholesalerProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WholesalerProduct(
      id: doc.id,
      name: (data['name'] ?? data['Name'] ?? '') as String,
      description: (data['Description'] ?? data['description'] ?? '') as String,
      image: (data['image'] ?? '') as String,
      price: Product.toInt(data['price'] ?? data['Price']),
      stock: Product.toInt(data['stock'] ?? data['Stock']),
      wholesalerId:
          (data['wholesalerId'] ?? data['wholesalerID'] ?? '') as String,
      avgRating: Product.toDouble(data['avgRating'] ?? 0),
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
      'sellerType': sellerType,
      ...extraData ?? {},
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
