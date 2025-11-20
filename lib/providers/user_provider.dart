import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  String? _userRole;
  String? _wholesalerId; // If the current user is a wholesaler
  String? _retailerId; // If the current user is a retailer

  UserProvider() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      fetchUserRoleAndIds(_currentUser!.uid);
    }
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
      if (user != null) {
        fetchUserRoleAndIds(user.uid);
      } else {
        _userRole = null;
        _wholesalerId = null;
        _retailerId = null;
        notifyListeners();
      }
    });
  }

  User? get currentUser => _currentUser;
  String? get userRole => _userRole;
  String? get wholesalerId => _wholesalerId;
  String? get retailerId => _retailerId;

  Future<void> fetchUserRoleAndIds(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        _userRole = userDoc.data()?['role'] as String?;
        if (_userRole == 'Wholesaler') {
          _wholesalerId = uid;
          _retailerId = null;
        } else if (_userRole == 'Retailer') {
          _retailerId = uid;
          _wholesalerId = null;
        } else {
          _wholesalerId = null;
          _retailerId = null;
        }
      } else {
        _userRole = null;
        _wholesalerId = null;
        _retailerId = null;
      }
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      _userRole = null;
      _wholesalerId = null;
      _retailerId = null;
    } finally {
      notifyListeners();
    }
  }

  // Method to refresh user data manually if needed
  Future<void> refreshUserData() async {
    if (_currentUser != null) {
      await fetchUserRoleAndIds(_currentUser!.uid);
    }
  }
}