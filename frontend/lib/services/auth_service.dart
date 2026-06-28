import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:openwhen/services/api_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<User?> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    // Web 用 popup；行動裝置走原生 provider 流程，皆由 firebase_auth 直接處理
    final result = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    await ApiService().verifyUser();
    return result.user;
  }

  static Future<User?> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    await ApiService().verifyUser();
    return result.user;
  }

  static Future<User?> signUpWithEmail(String email, String password, String displayName) async {
    final result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await result.user?.updateDisplayName(displayName);
    await ApiService().verifyUser();
    return result.user;
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }
}
