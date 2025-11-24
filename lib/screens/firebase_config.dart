import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  static Future<void> initialize() async {
    // Only use emulator in debug mode and when emulator is running
    if (kDebugMode) {
      try {
        await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
      } catch (e) {
        // Emulator not running, continue with production Firebase
        print('Firebase emulator not available: $e');
      }
    }

    // Configure Firebase Auth settings
    FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: kDebugMode,
      forceRecaptchaFlow: false,
    );
  }
}
