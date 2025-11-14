// lib/models/order_model.dart
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// ---------------- ORDER ITEM ----------------
class OrderItem {
  final String productId;
  final String name;
  final double price; // price per unit (INR)
  final int quantity; // user-selected quantity (ordered quantity)
  final int? stock; // optional: total available stock in DB
  final String sellerId; // maps to users/{sellerId}
  final String? image;
  final String productPath;
  Uint8List? cachedImageBytes;

  OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.stock,
    required this.sellerId,
    this.image,
    required this.productPath,
    this.cachedImageBytes,
  });

  OrderItem copyWith({
    String? productId,
    String? name,
    double? price,
    int? quantity,
    int? stock,
    String? sellerId,
    String? image,
    String? productPath,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      stock: stock ?? this.stock,
      sellerId: sellerId ?? this.sellerId,
      image: image ?? this.image,
      productPath: productPath ?? this.productPath,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
    'stock': stock,
    'sellerId': sellerId,
    'image': image,
    'productPath': productPath,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'] ?? '',
    name: json['name'] ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    stock: (json['stock'] as num?)?.toInt(),
    sellerId: json['sellerId'] ?? '',
    image: json['image'] as String?,
    productPath: json['productPath'] ?? '',
  );
}

/// ---------------- ADDRESS ----------------
class Address {
  final String house;
  final String area;
  final String city;
  final String state;
  final String pincode;
  final double lat;
  final double lng;

  Address({
    required this.house,
    required this.area,
    required this.city,
    required this.state,
    required this.pincode,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toJson() => {
    'house': house,
    'area': area,
    'city': city,
    'state': state,
    'pincode': pincode,
    'lat': lat,
    'lng': lng,
  };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    house: json['house'] ?? '',
    area: json['area'] ?? '',
    city: json['city'] ?? '',
    state: json['state'] ?? '',
    pincode: json['pincode'] ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
    lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
  );
}

/// ---------------- ORDER MODEL ----------------
class Order {
  final String id;
  final String userId; // buyer's user id (parent doc under users)
  final String customerName;
  final Address deliveryAddress;
  final List<OrderItem> items;
  final double totalAmount; // total payable (INR)
  final String paymentMethod; // e.g. 'razorpay', 'cod'
  final String receivingMethod; // 'home_delivery' / 'self_pickup'
  final String
  status; // e.g. 'order_placed', 'preparing', 'ready', 'in_transit', 'delivered'
  final Timestamp createdAt; // server timestamp stored
  final DateTime placedAt; // convenience parsed DateTime (from Timestamp)
  final DateTime? pickupDate; // optional
  final int? etaDays; // optional computed ETA days
  final DateTime? expectedDelivery; // optional parsed DateTime
  final String? razorpayOrderId; // server-side created order id (Razorpay)
  final String? razorpayPaymentId; // payment id after success
  final String? razorpaySignature; // signature (verify on server)
  final Map<String, dynamic>
  perRetailerDelivery; // flexible map: {sellerId: {...}}

  Order({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.deliveryAddress,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.receivingMethod,
    required this.status,
    required this.createdAt,
    required this.placedAt,
    required this.perRetailerDelivery,
    this.pickupDate,
    this.etaDays,
    this.expectedDelivery,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.razorpaySignature,
  });

  Order copyWith({
    String? id,
    String? userId,
    String? customerName,
    Address? deliveryAddress,
    List<OrderItem>? items,
    double? totalAmount,
    String? paymentMethod,
    String? receivingMethod,
    String? status,
    Timestamp? createdAt,
    DateTime? placedAt,
    DateTime? pickupDate,
    int? etaDays,
    DateTime? expectedDelivery,
    String? razorpayOrderId,
    String? razorpayPaymentId,
    String? razorpaySignature,
    Map<String, dynamic>? perRetailerDelivery,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receivingMethod: receivingMethod ?? this.receivingMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      placedAt: placedAt ?? this.placedAt,
      pickupDate: pickupDate ?? this.pickupDate,
      etaDays: etaDays ?? this.etaDays,
      expectedDelivery: expectedDelivery ?? this.expectedDelivery,
      razorpayOrderId: razorpayOrderId ?? this.razorpayOrderId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      razorpaySignature: razorpaySignature ?? this.razorpaySignature,
      perRetailerDelivery: perRetailerDelivery ?? this.perRetailerDelivery,
    );
  }

  /// Firestore serializer — stores Dates as Timestamps
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'customerName': customerName,
    'deliveryAddress': deliveryAddress.toJson(),
    'items': items.map((e) => e.toJson()).toList(),
    'totalAmount': totalAmount,
    'paymentMethod': paymentMethod,
    'receivingMethod': receivingMethod,
    'status': status,
    'createdAt':
        createdAt, // Timestamp (use FieldValue.serverTimestamp() when creating)
    'placedAt': Timestamp.fromDate(placedAt),
    'pickupDate': pickupDate != null ? Timestamp.fromDate(pickupDate!) : null,
    'etaDays': etaDays,
    'expectedDelivery': expectedDelivery != null
        ? Timestamp.fromDate(expectedDelivery!)
        : null,
    'razorpayOrderId': razorpayOrderId,
    'razorpayPaymentId': razorpayPaymentId,
    'razorpaySignature': razorpaySignature,
    'perRetailerDelivery': perRetailerDelivery,
  };

  /// Parse from Firestore DocumentSnapshot
  factory Order.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // helper to parse Timestamp or String to DateTime
    DateTime _parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    // createdAt may be a Timestamp or absent — default to now if missing
    final createdAtVal = data['createdAt'];
    final createdAtTs = createdAtVal is Timestamp
        ? createdAtVal
        : Timestamp.now();

    // placedAt could be Timestamp, String or missing
    final placedAtVal = data['placedAt'];
    final placedAtDt = _parseDate(placedAtVal);

    Map<String, dynamic> perRetailer = {};
    if (data['perRetailerDelivery'] is Map) {
      perRetailer = Map<String, dynamic>.from(
        data['perRetailerDelivery'] as Map,
      );
    }

    final itemsList =
        (data['items'] as List<dynamic>?)
            ?.map(
              (e) => OrderItem.fromJson(Map<String, dynamic>.from(e as Map)),
            )
            .toList() ??
        <OrderItem>[];

    final addressMap = data['deliveryAddress'] as Map<String, dynamic>? ?? {};

    return Order(
      id: data['id'] ?? doc.id,
      userId: data['userId'] ?? '',
      customerName: data['customerName'] ?? '',
      deliveryAddress: Address.fromJson(addressMap),
      items: itemsList,
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: data['paymentMethod'] ?? '',
      receivingMethod: data['receivingMethod'] ?? '',
      status: data['status'] ?? 'order_placed',
      createdAt: createdAtTs,
      placedAt: placedAtDt,
      pickupDate: data['pickupDate'] != null
          ? _parseDate(data['pickupDate'])
          : null,
      etaDays: (data['etaDays'] as num?)?.toInt(),
      expectedDelivery: data['expectedDelivery'] != null
          ? _parseDate(data['expectedDelivery'])
          : null,
      razorpayOrderId: data['razorpayOrderId'],
      razorpayPaymentId: data['razorpayPaymentId'],
      razorpaySignature: data['razorpaySignature'],
      perRetailerDelivery: perRetailer,
    );
  }
}
