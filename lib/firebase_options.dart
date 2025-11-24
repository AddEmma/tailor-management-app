// Corrected firebase_options.dart with your actual project values
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
    apiKey: 'AIzaSyB6kk3DEsUcWjFWYHo04EhZLOMx7e44ZDQ',
    appId:
        '1:182037359017:web:YOUR_WEB_APP_ID', // You need to create a web app to get this
    messagingSenderId: '182037359017',
    projectId: 'tailor-management-18fb9',
    authDomain: 'tailor-management-18fb9.firebaseapp.com',
    storageBucket: 'tailor-management-18fb9.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB6kk3DEsUcWjFWYHo04EhZLOMx7e44ZDQ',
    appId: '1:182037359017:android:eeebf2e7a021ed6e657cb8',
    messagingSenderId: '182037359017',
    projectId: 'tailor-management-18fb9',
    authDomain: 'tailor-management-18fb9.firebaseapp.com',
    storageBucket: 'tailor-management-18fb9.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB6kk3DEsUcWjFWYHo04EhZLOMx7e44ZDQ',
    appId:
        '1:182037359017:ios:YOUR_IOS_APP_ID', // You need to create an iOS app to get this
    messagingSenderId: '182037359017',
    projectId: 'tailor-management-18fb9',
    authDomain: 'tailor-management-18fb9.firebaseapp.com',
    storageBucket: 'tailor-management-18fb9.appspot.com',
    iosBundleId: 'com.example.tailorManagement',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB6kk3DEsUcWjFWYHo04EhZLOMx7e44ZDQ',
    appId: '1:182037359017:ios:YOUR_IOS_APP_ID', // Same as iOS
    messagingSenderId: '182037359017',
    projectId: 'tailor-management-18fb9',
    authDomain: 'tailor-management-18fb9.firebaseapp.com',
    storageBucket: 'tailor-management-18fb9.appspot.com',
    iosBundleId: 'com.example.tailorManagement',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB6kk3DEsUcWjFWYHo04EhZLOMx7e44ZDQ',
    appId: '1:182037359017:web:YOUR_WEB_APP_ID', // Same as web
    messagingSenderId: '182037359017',
    projectId: 'tailor-management-18fb9',
    authDomain: 'tailor-management-18fb9.firebaseapp.com',
    storageBucket: 'tailor-management-18fb9.appspot.com',
  );
}
