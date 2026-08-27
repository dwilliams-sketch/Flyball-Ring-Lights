import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase Web is not configured yet in Rev 0.2B.');
    }
    return android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_eGSVZp9VO1lbsQ0-b43bBbEivRdZ0Og',
    appId: '1:559694261262:android:6fe5515687aa64971aa05f',
    messagingSenderId: '559694261262',
    projectId: 'flyball-ring-lights',
    storageBucket: 'flyball-ring-lights.firebasestorage.app',
  );
}
