import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // FACEBOOK SECRETS FROM .env
  String get fbAppId => dotenv.env['FACEBOOK_APP_ID'] ?? '';
  String get fbClientToken => dotenv.env['FACEBOOK_CLIENT_TOKEN'] ?? '';
  String get fbProtocolScheme => dotenv.env['FACEBOOK_PROTOCOL_SCHEME'] ?? '';

  // ----------------------------------------------------------------
  //  GOOGLE SIGN-IN
  // ----------------------------------------------------------------
  Future<User?> signInWithGoogleAndUpsert() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      await _ensureUserDoc(result.user, provider: 'google');

      return result.user;
    } catch (e) {
      print(" Google Sign-In Error: $e");
      rethrow;
    }
  }

  // ----------------------------------------------------------------
  //  FACEBOOK SIGN-IN
  // ----------------------------------------------------------------
  Future<User?> signInWithFacebookAndUpsert() async {
    try {
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw Exception(result.message ?? 'Facebook login failed');
      }

      final credential =
      FacebookAuthProvider.credential(result.accessToken!.token);

      final authResult = await _auth.signInWithCredential(credential);
      await _ensureUserDoc(authResult.user, provider: 'facebook');

      return authResult.user;
    } catch (e) {
      print(" Facebook Sign-In Error: $e");
      rethrow;
    }
  }

  // ----------------------------------------------------------------
  //  CREATE FIRESTORE DOCUMENT
  // ----------------------------------------------------------------
  Future<void> _ensureUserDoc(User? user, {required String provider}) async {
    if (user == null) return;

    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'username': user.displayName ?? '',
        'email': user.email ?? '',
        'mobile': '',
        'photoURL': user.photoURL ?? '',
        'provider': provider,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await ref.update({'lastLogin': FieldValue.serverTimestamp()});
    }
  }

  // ----------------------------------------------------------------
  //  PHONE AUTH
  // ----------------------------------------------------------------
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String verificationId) codeSent,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      print(" Phone verification failed: $e");
      rethrow;
    }
  }

  // ----------------------------------------------------------------
  //  SIGN OUT
  // ----------------------------------------------------------------
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
  }

  Future<User?> signInWithOTP(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint("Error signing in with OTP: $e");
      rethrow;
    }
  }
}
