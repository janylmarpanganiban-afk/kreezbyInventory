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
    apiKey: 'AIzaSyBvmQ7faOaKumma7WKuzgO0KTi9ebd-a3s',
    appId: '1:883468275809:web:57c44a7bfe8641f2a05a20',
    messagingSenderId: '883468275809',
    projectId: 'kreezby-bakeshop-df589',
    authDomain: 'kreezby-bakeshop-df589.firebaseapp.com',
    storageBucket: 'kreezby-bakeshop-df589.firebasestorage.app',
    measurementId: 'G-W6NGKZVHV1',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAkFXuGrVyW7UnFY0V10wR7vlZMyJ1ZdiQ',
    appId: '1:883468275809:android:49e27b633ee927b6a05a20',
    messagingSenderId: '883468275809',
    projectId: 'kreezby-bakeshop-df589',
    storageBucket: 'kreezby-bakeshop-df589.firebasestorage.app',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDdgjZFfdYR5vO0iWWuSLdZBX-4VCP16wI',
    appId: '1:883468275809:ios:8a1469030f511d78a05a20',
    messagingSenderId: '883468275809',
    projectId: 'kreezby-bakeshop-df589',
    storageBucket: 'kreezby-bakeshop-df589.firebasestorage.app',
    iosBundleId: 'com.example.raymond',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDdgjZFfdYR5vO0iWWuSLdZBX-4VCP16wI',
    appId: '1:883468275809:ios:8a1469030f511d78a05a20',
    messagingSenderId: '883468275809',
    projectId: 'kreezby-bakeshop-df589',
    storageBucket: 'kreezby-bakeshop-df589.firebasestorage.app',
    iosBundleId: 'com.example.raymond',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBvmQ7faOaKumma7WKuzgO0KTi9ebd-a3s',
    appId: '1:883468275809:web:2e7dcd806e9757b0a05a20',
    messagingSenderId: '883468275809',
    projectId: 'kreezby-bakeshop-df589',
    authDomain: 'kreezby-bakeshop-df589.firebaseapp.com',
    storageBucket: 'kreezby-bakeshop-df589.firebasestorage.app',
    measurementId: 'G-BS786JXZTS',
  );
}
