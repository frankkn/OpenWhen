import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:openwhen/services/api_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn();

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<User?> signInWithGoogle() async {
    if (kIsWeb) {
      // Flutter Web: use Firebase's signInWithPopup — google_sign_in idToken is null on web
      final provider = GoogleAuthProvider();
      final result = await _auth.signInWithPopup(provider);
      await ApiService().verifyUser();
      return result.user;
    }
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    if (googleAuth.idToken == null) throw Exception('Google 登入失敗：無法取得 ID Token');
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
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
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }
}
