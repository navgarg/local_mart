import 'package:cloud_firestore/cloud_firestore.dart';


class WholesalerInventoryItem {
  final String id;
  final String productId;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String imageUrl;

  WholesalerInventoryItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.imageUrl,
  });

  WholesalerInventoryItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? imageUrl,
  }) {
    return WholesalerInventoryItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
    };
  }

  factory WholesalerInventoryItem.fromJson(Map<String, dynamic> json) {
    return WholesalerInventoryItem(
      id: json['id'] as String,
      productId: json['productId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      stock: (json['stock'] as num).toInt(),
      imageUrl: json['imageUrl'] as String,
    );
  }
}

class WholesalerInventory {
  final String id;
  final String wholesalerId;
  final List<WholesalerInventoryItem> items;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  WholesalerInventory({
    required this.id,
    required this.wholesalerId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wholesalerId': wholesalerId,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory WholesalerInventory.fromJson(Map<String, dynamic> json) {
    return WholesalerInventory(
      id: json['id'] as String,
      wholesalerId: json['wholesalerId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((itemJson) => WholesalerInventoryItem.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
    );
  }

  WholesalerInventory copyWith({
    String? id,
    String? wholesalerId,
    List<WholesalerInventoryItem>? items,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return WholesalerInventory(
      id: id ?? this.id,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}