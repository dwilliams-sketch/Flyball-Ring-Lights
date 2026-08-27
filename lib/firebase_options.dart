import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    return android;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBonBc4uDH5tkLNtkp3xUYVDBphIQ3dLlA',
    authDomain: 'flyball-ring-lights.firebaseapp.com',
    databaseURL:
        'https://flyball-ring-lights-default-rtdb.europe-west1.firebasedatabase.app',
    projectId: 'flyball-ring-lights',
    storageBucket: 'flyball-ring-lights.firebasestorage.app',
    messagingSenderId: '559694261262',
    appId: '1:559694261262:web:7ffafa626f5586251aa05f',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB_eGSVZp9VO1lbsQ0-b43bBbEivRdZ0Og',
    appId: '1:559694261262:android:6fe5515687aa64971aa05f',
    messagingSenderId: '559694261262',
    projectId: 'flyball-ring-lights',
    storageBucket: 'flyball-ring-lights.firebasestorage.app',
    databaseURL:
        'https://flyball-ring-lights-default-rtdb.europe-west1.firebasedatabase.app',
  );
}
