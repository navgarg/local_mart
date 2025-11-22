import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_mart/models/address.dart';


class Wholesaler {
  final String id;
  final String name;
  final String email;
  final Address address;
  final String phone;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Wholesaler({
    required this.id,
    required this.name,
    required this.email,
    required this.address,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Wholesaler.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Wholesaler(
      id: doc.id,
      name: data['username'] as String? ?? '',
      email: data['email'] as String? ?? '',
      address: Address.fromMap(data['address'] as Map<String, dynamic>? ?? {}),
      phone: data['phone'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp,
      updatedAt: data['updatedAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'username': name,
      'email': email,
      'address': address.toMap(),
      'phone': phone,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Wholesaler copyWith({
    String? id,
    String? name,
    String? email,
    Address? address,
    String? phone,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return Wholesaler(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
