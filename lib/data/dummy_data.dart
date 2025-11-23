import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/modules/retailer_wholesaler_order/models/retailer_wholesaler_order_model.dart';
import 'package:local_mart/modules/customer_order/models/order_model.dart';
import 'package:local_mart/models/retailer_product.dart';

class Product {
  final String id;
  final String name;
  final String image;
  final double price;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    required this.category,
  });
}

final List<Product> dummyProducts = [
  Product(
    id: 'p1',
    name: 'Tomato',
    image: 'https://via.placeholder.com/150',
    price: 50,
    category: 'Groceries',
  ),
  Product(
    id: 'p2',
    name: 'Speakers',
    image: 'https://via.placeholder.com/150',
    price: 4560,
    category: 'Electronics',
  ),
  Product(
    id: 'p3',
    name: 'Carrot',
    image: 'https://via.placeholder.com/150',
    price: 40,
    category: 'Groceries',
  ),
  Product(
    id: 'p4',
    name: 'Sofa',
    image: 'https://via.placeholder.com/150',
    price: 1500,
    category: 'Home Goods',
  ),
  Product(
    id: 'p5',
    name: 'Charger',
    image: 'https://via.placeholder.com/150',
    price: 500,
    category: 'Electronics',
  ),
];

final List<Order> dummyOrders = [
  Order(
    id: 'cust_ord_1',
    retailerId: 'ret1',
    customerName: 'John Doe',
    orderDate: DateTime(2023, 11, 23, 10, 0),
    totalAmount: 250.0,
    status: 'order_placed',
    items: [
      OrderItem(productId: 'p1', productName: 'Tomato', quantity: 2, price: 50.0),
      OrderItem(productId: 'p3', productName: 'Carrot', quantity: 3, price: 40.0),
    ],
  ),
  Order(
    id: 'cust_ord_2',
    retailerId: 'ret1',
    customerName: 'Jane Smith',
    orderDate: DateTime(2023, 11, 22, 14, 30),
    totalAmount: 150.0,
    status: 'processing',
    items: [
      OrderItem(productId: 'p2', productName: 'Speakers', quantity: 1, price: 150.0),
    ],
  ),
  Order(
    id: 'cust_ord_3',
    retailerId: 'ret1',
    customerName: 'Peter Jones',
    orderDate: DateTime(2023, 11, 21, 9, 0),
    totalAmount: 500.0,
    status: 'delivered',
    items: [
      OrderItem(productId: 'p4', productName: 'Sofa', quantity: 1, price: 500.0),
    ],
  ),
];

class Alert {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  Alert({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });
}

final List<Alert> dummyAlerts = [
  Alert(
    id: 'alert1',
    userId: 'retailer1',
    title: 'New Order Received!',
    message: 'You have a new order from John Doe for 5 items.',
    timestamp: DateTime(2023, 11, 20, 10, 0),
    isRead: false,
  ),
  Alert(
    id: 'alert2',
    userId: 'retailer1',
    title: 'Low Stock Alert',
    message: 'Product "Milk" is running low. Only 10 units left.',
    timestamp: DateTime(2023, 11, 19, 15, 30),
    isRead: false,
  ),
  Alert(
    id: 'alert3',
    userId: 'retailer1',
    title: 'Order Delivered',
    message: 'Order #ORD12345 has been successfully delivered.',
    timestamp: DateTime(2023, 11, 18, 9, 0),
    isRead: true,
  ),
  Alert(
    id: 'alert4',
    userId: 'wholesaler1',
    title: 'New Retailer Signup',
    message: 'A new retailer, "Fresh Mart", has signed up.',
    timestamp: DateTime(2023, 11, 20, 11, 0),
    isRead: false,
  ),
  Alert(
    id: 'alert5',
    userId: 'wholesaler1',
    title: 'Payment Received',
    message: 'Payment of ₹5000 received from "Green Grocers".',
    timestamp: DateTime(2023, 11, 17, 14, 0),
    isRead: true,
  ),
];

class OrderItem {
  final String productId;
  final String productName;
  final double quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });
}

class Order {
  final String id;
  final String retailerId;
  final String customerName;
  final DateTime orderDate;
  final double totalAmount;
  final String status;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.retailerId,
    required this.customerName,
    required this.orderDate,
    required this.totalAmount,
    required this.status,
    required this.items,
  });
}

final List<RetailerProduct> dummyRetailerProducts = [
  RetailerProduct(
    id: 'rp1',
    name: 'Organic Apples',
    description: 'Fresh organic apples from local farms.',
    image: 'https://via.placeholder.com/150',
    retailerId: 'ret1',
    price: 120,
    stock: 50,
    category: 'Groceries',
    createdAt: Timestamp.fromDate(DateTime(2023, 11, 20, 10, 0)),
    updatedAt: Timestamp.fromDate(DateTime(2023, 11, 20, 10, 0)),
  ),
  RetailerProduct(
    id: 'rp2',
    name: 'Whole Wheat Bread',
    description: 'Freshly baked whole wheat bread.',
    image: 'https://via.placeholder.com/150',
    retailerId: 'ret1',
    price: 60,
    stock: 30,
    category: 'Groceries',
    createdAt: Timestamp.fromDate(DateTime(2023, 11, 19, 15, 30)),
    updatedAt: Timestamp.fromDate(DateTime(2023, 11, 19, 15, 30)),
  ),
  RetailerProduct(
    id: 'rp3',
    name: 'Milk (1 Liter)',
    description: 'Fresh cow milk, 1 liter pack.',
    image: 'https://via.placeholder.com/150',
    retailerId: 'ret1',
    price: 45,
    stock: 100,
    category: 'Groceries',
    createdAt: Timestamp.fromDate(DateTime(2023, 11, 18, 9, 0)),
    updatedAt: Timestamp.fromDate(DateTime(2023, 11, 18, 9, 0)),
  ),
];
final List<RetailerWholesalerOrder> dummyRetailerWholesalerOrders = [
  RetailerWholesalerOrder(
    id: 'rwo1',
    retailerId: 'ret1',
    wholesalerId: 'whole1',
    items: [
      RetailerWholesalerOrderItem(
        productId: 'p1',
        name: 'Tomato',
        price: 50.0,
        quantity: 5,
        wholesalerId: 'whole1',
        retailerId: 'ret1',
        image: 'https://via.placeholder.com/150',
        productPath: 'groceries/tomato',
      ),
      RetailerWholesalerOrderItem(
        productId: 'p3',
        name: 'Carrot',
        price: 40.0,
        quantity: 10,
        wholesalerId: 'whole1',
        retailerId: 'ret1',
        image: 'https://via.placeholder.com/150',
        productPath: 'groceries/carrot',
      ),
    ],
    totalAmount: 650.0,
    status: 'pending',
    createdAt: Timestamp.fromDate(DateTime(2023, 11, 22, 10, 0)),
    placedAt: DateTime(2023, 11, 22, 10, 0),
  ),
  RetailerWholesalerOrder(
    id: 'rwo2',
    retailerId: 'ret2',
    wholesalerId: 'whole1',
    items: [
      RetailerWholesalerOrderItem(
        productId: 'p2',
        name: 'Speakers',
        price: 4560.0,
        quantity: 1,
        wholesalerId: 'whole1',
        retailerId: 'ret2',
        image: 'https://via.placeholder.com/150',
        productPath: 'electronics/speakers',
      ),
    ],
    totalAmount: 4560.0,
    status: 'delivered',
    createdAt: Timestamp.fromDate(DateTime(2023, 11, 20, 14, 30)),
    placedAt: DateTime(2023, 11, 20, 14, 30),
  ),
  RetailerWholesalerOrder(
    id: 'rwo3',
    retailerId: 'ret1',
    wholesalerId: 'whole2',
    items: [
      RetailerWholesalerOrderItem(
        productId: 'p4',
        name: 'Sofa',
        price: 1500.0,
        quantity: 1,
        wholesalerId: 'whole2',
        retailerId: 'ret1',
        image: 'https://via.placeholder.com/150',
        productPath: 'homegoods/sofa',
      ),
    ],
    totalAmount: 1500.0,
    status: 'shipped',
    createdAt: Timestamp.fromDate(DateTime(2023, 11, 18, 9, 0)),
    placedAt: DateTime(2023, 11, 18, 9, 0),
  ),
];
