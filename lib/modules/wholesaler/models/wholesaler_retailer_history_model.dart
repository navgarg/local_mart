import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/models/retailer_wholesaler_order_model.dart';

class RetailerTransaction {
  final String id;
  final String retailerId;
  final String wholesalerId;
  final String orderId;
  final List<RetailerWholesalerOrderItem> items;
  final double totalAmount;
  final Timestamp transactionDate;
  final String status;

  RetailerTransaction({
    required this.id,
    required this.retailerId,
    required this.wholesalerId,
    required this.orderId,
    required this.items,
    required this.totalAmount,
    required this.transactionDate,
    required this.status,
  });

  RetailerTransaction copyWith({
    String? id,
    String? retailerId,
    String? wholesalerId,
    String? orderId,
    List<RetailerWholesalerOrderItem>? items,
    double? totalAmount,
    Timestamp? transactionDate,
    String? status,
  }) {
    return RetailerTransaction(
      id: id ?? this.id,
      retailerId: retailerId ?? this.retailerId,
      wholesalerId: wholesalerId ?? this.wholesalerId,
      orderId: orderId ?? this.orderId,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'retailerId': retailerId,
      'wholesalerId': wholesalerId,
      'orderId': orderId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'transactionDate': transactionDate,
      'status': status,
    };
  }

  factory RetailerTransaction.fromJson(Map<String, dynamic> json) {
    return RetailerTransaction(
      id: json['id'] as String,
      retailerId: json['retailerId'] as String,
      wholesalerId: json['wholesalerId'] as String,
      orderId: json['orderId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((itemJson) => RetailerWholesalerOrderItem.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      transactionDate: json['transactionDate'] as Timestamp,
      status: json['status'] as String,
    );
  }
}

class RetailerPurchaseHistory {
  final String id;
  final String retailerId;
  final List<RetailerTransaction> transactions;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  RetailerPurchaseHistory({
    required this.id,
    required this.retailerId,
    required this.transactions,
    required this.createdAt,
    required this.updatedAt,
  });

  RetailerPurchaseHistory copyWith({
    String? id,
    String? retailerId,
    List<RetailerTransaction>? transactions,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return RetailerPurchaseHistory(
      id: id ?? this.id,
      retailerId: retailerId ?? this.retailerId,
      transactions: transactions ?? this.transactions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'retailerId': retailerId,
      'transactions': transactions.map((transaction) => transaction.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory RetailerPurchaseHistory.fromJson(Map<String, dynamic> json) {
    return RetailerPurchaseHistory(
      id: json['id'] as String,
      retailerId: json['retailerId'] as String,
      transactions: (json['transactions'] as List<dynamic>)
          .map((transactionJson) => RetailerTransaction.fromJson(transactionJson as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] as Timestamp,
      updatedAt: json['updatedAt'] as Timestamp,
    );
  }
}