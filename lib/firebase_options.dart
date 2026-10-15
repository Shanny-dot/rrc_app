// Firebase settings for phone alerts (project rrc-app-6f899). Generated from the Firebase
// project's registered apps; these values identify the app and are not secret.
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  /// [packageName] tells the store app (com.rrc.app) from the test build (com.rrc.app.test).
  static FirebaseOptions forPlatform(String packageName) {
    if (Platform.isIOS) return ios;
    return packageName.endsWith('.test') ? androidTest : android;
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBjNvmzPCsIDid4UCOxROHebyTVk40Ohus',
    appId: '1:785942700049:android:a2088cba119eb583f911b0',
    messagingSenderId: '785942700049',
    projectId: 'rrc-app-6f899',
    storageBucket: 'rrc-app-6f899.firebasestorage.app',
  );

  static const FirebaseOptions androidTest = FirebaseOptions(
    apiKey: 'AIzaSyBjNvmzPCsIDid4UCOxROHebyTVk40Ohus',
    appId: '1:785942700049:android:fadaae6591847b3ef911b0',
    messagingSenderId: '785942700049',
    projectId: 'rrc-app-6f899',
    storageBucket: 'rrc-app-6f899.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDIgEjX6BhK-2jtEAzX3BCN4K4w0PVAKdE',
    appId: '1:785942700049:ios:a82e359aed730478f911b0',
    messagingSenderId: '785942700049',
    projectId: 'rrc-app-6f899',
    storageBucket: 'rrc-app-6f899.firebasestorage.app',
    iosBundleId: 'com.rrc.referralapp',
  );
}
