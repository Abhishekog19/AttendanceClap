import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvc2BSmy2cFbPrPTbaHfqrC9bbX6ynJbc',
    appId: '1:227435969864:android:e8805cbe7bc75ad7b9877d',
    messagingSenderId: '227435969864',
    projectId: 'attendanceclap',
    storageBucket: 'attendanceclap.firebasestorage.app',
  );

  // Web config — fill these in after adding a Web app in Firebase Console
  // (Project Settings → Add app → Web)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAvc2BSmy2cFbPrPTbaHfqrC9bbX6ynJbc',
    appId: '1:227435969864:web:TODO_ADD_WEB_APP_ID',
    messagingSenderId: '227435969864',
    projectId: 'attendanceclap',
    authDomain: 'attendanceclap.firebaseapp.com',
    storageBucket: 'attendanceclap.firebasestorage.app',
  );

  // iOS config — fill these in after downloading GoogleService-Info.plist
  // (Project Settings → iOS app → GoogleService-Info.plist)
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAvc2BSmy2cFbPrPTbaHfqrC9bbX6ynJbc',
    appId: '1:227435969864:ios:TODO_ADD_IOS_APP_ID',
    messagingSenderId: '227435969864',
    projectId: 'attendanceclap',
    storageBucket: 'attendanceclap.firebasestorage.app',
    iosBundleId: 'com.attendanceai.attendanceAi',
  );
}
