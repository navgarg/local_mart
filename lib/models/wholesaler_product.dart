import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/product.dart';

class WholesalerProduct {
  final String? id;
  final String name;
  final String description;
  final String image;
  final int price;
  final int stock;
  final String sellerId;

  final Map<String, dynamic>? extraData;
  final String? category;
  WholesalerProduct({
    this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.price,
    required this.stock,
    required this.sellerId,

    this.extraData,
    this.category,
  });

  factory WholesalerProduct.fromFirestore(DocumentSnapshot doc, String category) {
    final data = doc.data() as Map<String, dynamic>;
    return WholesalerProduct(
      id: doc.id,
      name: (data['name'] ?? data['Name'] ?? '') as String,
      description: (data['Description'] ?? data['description'] ?? '') as String,
      image: (data['image'] ?? '') as String,
      price: Product.toInt(data['price'] ?? data['Price']),
      stock: Product.toInt(data['stock'] ?? data['Stock']),
      sellerId: (data['sellerId'] ?? data['sellerID'] ?? data['wholesalerId'] ?? data['wholesalerID'] ?? '') as String,

      extraData: data,
      category: category,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'name_lower': name.toLowerCase(),
      'description': description,
      'image': image,
      'price': price,
      'stock': stock,
      'sellerId': sellerId,

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
    String? sellerId,

    Map<String, dynamic>? extraData,
    String? category,
  }) {
    return WholesalerProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      sellerId: sellerId ?? this.sellerId,

      extraData: extraData ?? this.extraData,
      category: category ?? this.category,
    );
  }
}
