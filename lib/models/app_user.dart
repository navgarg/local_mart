import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String? email;
  final String? name;
  final String? username;
  final String? mobile;
  final Map<String, dynamic>? address;
  final String? photoURL;
  final String? provider;
  final Timestamp? createdAt;
  final Timestamp? lastLogin;
  final Map<String, dynamic>? categoryStats;
  final String? role;
  final String? retailerName;
  final String? retailerAddress;
  final List<String>? wholesalerIds;
  final String? wholesalerName;
  final String? wholesalerAddress;
  final List<String>? retailerIds;

  AppUser({
    required this.uid,
    this.email,
    this.name,
    this.username,
    this.mobile,
    this.address,
    this.photoURL,
    this.provider,
    this.createdAt,
    this.lastLogin,
    this.categoryStats,
    this.role,
    this.retailerName,
    this.retailerAddress,
    this.wholesalerIds,
    this.wholesalerName,
    this.wholesalerAddress,
    this.retailerIds,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: doc.id,
      email: data['email'] as String?,
      name: data['name'] as String?,
      username: data['username'] as String?,
      mobile: data['mobile'] as String?,
      address: data['address'] as Map<String, dynamic>?,
      photoURL: data['photoURL'] as String?,
      provider: data['provider'] as String?,
      createdAt: data['createdAt'] as Timestamp?,
      lastLogin: data['lastLogin'] as Timestamp?,
      categoryStats: data['categoryStats'] as Map<String, dynamic>?,
      role: data['role'] as String?,
      retailerName: data['retailerName'] as String?,
      retailerAddress: data['retailerAddress'] as String?,
      wholesalerIds: (data['wholesalerIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
      wholesalerName: data['wholesalerName'] as String?,
      wholesalerAddress: data['wholesalerAddress'] as String?,
      retailerIds: (data['retailerIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'username': username,
      'mobile': mobile,
      'address': address,
      'photoURL': photoURL,
      'provider': provider,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'lastLogin': lastLogin ?? FieldValue.serverTimestamp(),
      'categoryStats': categoryStats,
      'role': role,
      'retailerName': retailerName,
      'retailerAddress': retailerAddress,
      'wholesalerIds': wholesalerIds,
      'wholesalerName': wholesalerName,
      'wholesalerAddress': wholesalerAddress,
      'retailerIds': retailerIds,
    };
  }
}