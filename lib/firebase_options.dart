// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyBkIFo465lc23zoBiKVfMD51EMv7pPYqLE',
    appId: '1:27527501175:web:0ae954de0f79e5515cfd72',
    messagingSenderId: '27527501175',
    projectId: 'auth-caa1a',
    authDomain: 'auth-caa1a.firebaseapp.com',
    databaseURL: 'https://auth-caa1a-default-rtdb.firebaseio.com',
    storageBucket: 'auth-caa1a.firebasestorage.app',
    measurementId: 'G-323WQBV9H2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDzsAfsTO02OPJKZQ-I_AzCtUrH11HkRzg',
    appId: '1:27527501175:android:e811cf0ef3ae2a025cfd72',
    messagingSenderId: '27527501175',
    projectId: 'auth-caa1a',
    databaseURL: 'https://auth-caa1a-default-rtdb.firebaseio.com',
    storageBucket: 'auth-caa1a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDgTAj9RGLCT1GofpZO9u7Uq_iNYUlVzuw',
    appId: '1:27527501175:ios:bf92eae2cd950e2e5cfd72',
    messagingSenderId: '27527501175',
    projectId: 'auth-caa1a',
    databaseURL: 'https://auth-caa1a-default-rtdb.firebaseio.com',
    storageBucket: 'auth-caa1a.firebasestorage.app',
    iosBundleId: 'com.example.auth',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDgTAj9RGLCT1GofpZO9u7Uq_iNYUlVzuw',
    appId: '1:27527501175:ios:bf92eae2cd950e2e5cfd72',
    messagingSenderId: '27527501175',
    projectId: 'auth-caa1a',
    databaseURL: 'https://auth-caa1a-default-rtdb.firebaseio.com',
    storageBucket: 'auth-caa1a.firebasestorage.app',
    iosBundleId: 'com.example.auth',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBkIFo465lc23zoBiKVfMD51EMv7pPYqLE',
    appId: '1:27527501175:web:a38de671034f60e75cfd72',
    messagingSenderId: '27527501175',
    projectId: 'auth-caa1a',
    authDomain: 'auth-caa1a.firebaseapp.com',
    databaseURL: 'https://auth-caa1a-default-rtdb.firebaseio.com',
    storageBucket: 'auth-caa1a.firebasestorage.app',
    measurementId: 'G-NB9235H4BP',
  );
}
