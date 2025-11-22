import 'package:cloud_firestore/cloud_firestore.dart';

class Address {
  final String area;
  final String pincode;
  final String flatNo;
  final double lng;
  final String city;
  final String locality;
  final String state;
  final String building;
  final double lat;
  final Timestamp timestamp;

  Address({
    required this.area,
    required this.pincode,
    required this.flatNo,
    required this.lng,
    required this.city,
    required this.locality,
    required this.state,
    required this.building,
    required this.lat,
    required this.timestamp,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      area: map['area'] as String? ?? '',
      pincode: map['pincode'] as String? ?? '',
      flatNo: map['flatNo'] as String? ?? '',
      lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
      city: map['city'] as String? ?? '',
      locality: map['locality'] as String? ?? '',
      state: map['state'] as String? ?? '',
      building: map['building'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'area': area,
      'pincode': pincode,
      'flatNo': flatNo,
      'lng': lng,
      'city': city,
      'locality': locality,
      'state': state,
      'building': building,
      'lat': lat,
      'timestamp': timestamp,
    };
  }
}