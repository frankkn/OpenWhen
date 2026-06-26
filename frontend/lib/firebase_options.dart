// 這個檔案由 flutterfire configure 自動產生
// 執行：flutterfire configure --project=<your-firebase-project-id>
// 或手動填入 Firebase Console 的 Web app config

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:openwhen/config/env.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        return web;
    }
  }

  // 填入 Firebase Console → 專案設定 → 你的 Web app
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: firebaseApiKey,
    authDomain: firebaseAuthDomain,
    projectId: firebaseProjectId,
    storageBucket: firebaseStorageBucket,
    messagingSenderId: firebaseMessagingSenderId,
    appId: firebaseAppId,
  );

  // Android：執行 flutterfire configure 後會自動填入
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: firebaseApiKey,
    appId: '',
    messagingSenderId: firebaseMessagingSenderId,
    projectId: firebaseProjectId,
    storageBucket: firebaseStorageBucket,
  );
}
