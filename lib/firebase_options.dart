
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDeK3Sl5MXWzg_bBMFF-SlSUV9GOwKk44Q',
    appId: '1:239389192310:web:10f77720d16dfa39446f57',
    messagingSenderId: '239389192310',
    projectId: 'stoxneu',
    authDomain: 'stoxneu.firebaseapp.com',
    storageBucket: 'stoxneu.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAYGO4HxTpi9-OfyvOTkHqL-eVCbTuqOt4',
    appId: '1:239389192310:android:3b5cffa592f3923d446f57',
    messagingSenderId: '239389192310',
    projectId: 'stoxneu',
    storageBucket: 'stoxneu.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD5F7sHD3AnOJyPUQzbNAry-Qcypuv_x-E',
    appId: '1:239389192310:ios:1032856aa799e4cb446f57',
    messagingSenderId: '239389192310',
    projectId: 'stoxneu',
    storageBucket: 'stoxneu.firebasestorage.app',
    iosBundleId: 'com.example.stoxneu',
  );
}
