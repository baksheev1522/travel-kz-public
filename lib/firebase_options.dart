import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-6zu5p3ZXSILWswIy_QsRXwdykc41pWI',
    appId: '1:997349703277:android:67cd52cd3ebacb4ac08964',
    messagingSenderId: '997349703277',
    projectId: 'clone-ht-8324c',
    storageBucket: 'clone-ht-8324c.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD-6zu5p3ZXSILWswIy_QsRXwdykc41pWI',
    appId: '1:997349703277:android:67cd52cd3ebacb4ac08964',
    messagingSenderId: '997349703277',
    projectId: 'clone-ht-8324c',
    storageBucket: 'clone-ht-8324c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-6zu5p3ZXSILWswIy_QsRXwdykc41pWI',
    appId: '1:997349703277:android:67cd52cd3ebacb4ac08964',
    messagingSenderId: '997349703277',
    projectId: 'clone-ht-8324c',
    storageBucket: 'clone-ht-8324c.firebasestorage.app',
  );
}