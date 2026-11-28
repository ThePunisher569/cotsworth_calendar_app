// Environment-backed Firebase options (safe for public repositories).
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'core/config/app_env.dart';

/// Reads [FirebaseOptions] from [AppEnv] (`--dart-define-from-file=.env` or
/// CI `--dart-define`) so zero API keys or project IDs exist in Git history.
class DefaultFirebaseOptions {
  /// Returns `true` when required Firebase credentials are available for the
  /// active target platform. Allows local offline runs & tests without `.env`.
  static bool get isConfigured {
    if (defaultTargetPlatform == TargetPlatform.linux && !kIsWeb) {
      return false;
    }
    try {
      final opts = currentPlatform;
      return opts.apiKey.isNotEmpty &&
          opts.appId.isNotEmpty &&
          opts.projectId.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

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
          'DefaultFirebaseOptions are not configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: AppEnv.firebaseWebApiKey,
    appId: AppEnv.firebaseWebAppId,
    messagingSenderId: AppEnv.firebaseMessagingSenderId,
    projectId: AppEnv.firebaseProjectId,
    authDomain: AppEnv.firebaseAuthDomain == ''
        ? null
        : AppEnv.firebaseAuthDomain,
    databaseURL: AppEnv.firebaseDatabaseUrl == ''
        ? null
        : AppEnv.firebaseDatabaseUrl,
    storageBucket: AppEnv.firebaseStorageBucket == ''
        ? null
        : AppEnv.firebaseStorageBucket,
    measurementId: AppEnv.firebaseWebMeasurementId == ''
        ? null
        : AppEnv.firebaseWebMeasurementId,
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: AppEnv.firebaseAndroidApiKey,
    appId: AppEnv.firebaseAndroidAppId,
    messagingSenderId: AppEnv.firebaseMessagingSenderId,
    projectId: AppEnv.firebaseProjectId,
    databaseURL: AppEnv.firebaseDatabaseUrl == ''
        ? null
        : AppEnv.firebaseDatabaseUrl,
    storageBucket: AppEnv.firebaseStorageBucket == ''
        ? null
        : AppEnv.firebaseStorageBucket,
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: AppEnv.firebaseIosApiKey,
    appId: AppEnv.firebaseIosAppId,
    messagingSenderId: AppEnv.firebaseMessagingSenderId,
    projectId: AppEnv.firebaseProjectId,
    databaseURL: AppEnv.firebaseDatabaseUrl == ''
        ? null
        : AppEnv.firebaseDatabaseUrl,
    storageBucket: AppEnv.firebaseStorageBucket == ''
        ? null
        : AppEnv.firebaseStorageBucket,
    iosBundleId: AppEnv.firebaseIosBundleId,
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: AppEnv.firebaseIosApiKey,
    appId: AppEnv.firebaseIosAppId,
    messagingSenderId: AppEnv.firebaseMessagingSenderId,
    projectId: AppEnv.firebaseProjectId,
    databaseURL: AppEnv.firebaseDatabaseUrl == ''
        ? null
        : AppEnv.firebaseDatabaseUrl,
    storageBucket: AppEnv.firebaseStorageBucket == ''
        ? null
        : AppEnv.firebaseStorageBucket,
    iosBundleId: AppEnv.firebaseIosBundleId,
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: AppEnv.firebaseWindowsApiKey,
    appId: AppEnv.firebaseWindowsAppId,
    messagingSenderId: AppEnv.firebaseMessagingSenderId,
    projectId: AppEnv.firebaseProjectId,
    authDomain: AppEnv.firebaseAuthDomain == ''
        ? null
        : AppEnv.firebaseAuthDomain,
    databaseURL: AppEnv.firebaseDatabaseUrl == ''
        ? null
        : AppEnv.firebaseDatabaseUrl,
    storageBucket: AppEnv.firebaseStorageBucket == ''
        ? null
        : AppEnv.firebaseStorageBucket,
    measurementId: AppEnv.firebaseWindowsMeasurementId == ''
        ? null
        : AppEnv.firebaseWindowsMeasurementId,
  );
}
