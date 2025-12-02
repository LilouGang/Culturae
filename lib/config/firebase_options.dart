import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'AIzaSyD3A_mkZron1D0L9bZ0LSszSsdwuy7qdDc',
    appId: '1:839416392268:web:808cca1df6cd465a2be2e9',
    messagingSenderId: '839416392268',
    projectId: 'culturek-ffdac',
    authDomain: 'culturek-ffdac.firebaseapp.com',
    storageBucket: 'culturek-ffdac.firebasestorage.app',
    measurementId: 'G-ZEP2KS7DCV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD4VoF7v3mHBq49Whn-IIuE1v09g3vlvYo',
    appId: '1:839416392268:android:ee1e0ba0659025e92be2e9',
    messagingSenderId: '839416392268',
    projectId: 'culturek-ffdac',
    storageBucket: 'culturek-ffdac.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCsUY-kj1blKesLpmbXiMhvmUmQ1eo_pLQ',
    appId: '1:839416392268:ios:bf1c5158ed45fdfe2be2e9',
    messagingSenderId: '839416392268',
    projectId: 'culturek-ffdac',
    storageBucket: 'culturek-ffdac.firebasestorage.app',
    iosBundleId: 'com.example.culturek',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCsUY-kj1blKesLpmbXiMhvmUmQ1eo_pLQ',
    appId: '1:839416392268:ios:bf1c5158ed45fdfe2be2e9',
    messagingSenderId: '839416392268',
    projectId: 'culturek-ffdac',
    storageBucket: 'culturek-ffdac.firebasestorage.app',
    iosBundleId: 'com.example.culturek',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD3A_mkZron1D0L9bZ0LSszSsdwuy7qdDc',
    appId: '1:839416392268:web:58d7526befcdeddf2be2e9',
    messagingSenderId: '839416392268',
    projectId: 'culturek-ffdac',
    authDomain: 'culturek-ffdac.firebaseapp.com',
    storageBucket: 'culturek-ffdac.firebasestorage.app',
    measurementId: 'G-KVL47GZDFE',
  );
}
