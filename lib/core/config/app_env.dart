/// Centralized compile-time environment configuration sourced from `.env`
/// (`--dart-define-from-file=.env`) or CI/CD `--dart-define` flags.
///
/// Keeping all project IDs, API keys, endpoints, and feature flags out of
/// committed Dart source protects the public GitHub repository.
abstract final class AppEnv {
  // ─── Firebase Core / Shared ──────────────────────────────────────
  static const firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const firebaseDatabaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
  );

  // ─── Firebase Platform Credentials ───────────────────────────────
  static const firebaseWebApiKey = String.fromEnvironment(
    'FIREBASE_WEB_API_KEY',
  );
  static const firebaseWebAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const firebaseWebMeasurementId = String.fromEnvironment(
    'FIREBASE_WEB_MEASUREMENT_ID',
  );

  static const firebaseAndroidApiKey = String.fromEnvironment(
    'FIREBASE_ANDROID_API_KEY',
  );
  static const firebaseAndroidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );

  static const firebaseIosApiKey = String.fromEnvironment(
    'FIREBASE_IOS_API_KEY',
  );
  static const firebaseIosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
    defaultValue: 'com.org.cotsworthCalendarApp',
  );

  static const firebaseWindowsApiKey = String.fromEnvironment(
    'FIREBASE_WINDOWS_API_KEY',
  );
  static const firebaseWindowsAppId = String.fromEnvironment(
    'FIREBASE_WINDOWS_APP_ID',
  );
  static const firebaseWindowsMeasurementId = String.fromEnvironment(
    'FIREBASE_WINDOWS_MEASUREMENT_ID',
  );

  // ─── App / Backend Runtime Controls ──────────────────────────────
  static const appPublicBaseUrl = String.fromEnvironment(
    'APP_PUBLIC_BASE_URL',
    defaultValue: '',
  );
  static const firestoreUsersCollection = String.fromEnvironment(
    'FIRESTORE_USERS_COLLECTION',
    defaultValue: 'users',
  );
  static const allowGuestMode = bool.fromEnvironment(
    'AUTH_ALLOW_GUEST_MODE',
    defaultValue: true,
  );
  static const tempGuestUsername = String.fromEnvironment(
    'AUTH_TEMP_GUEST_USERNAME',
    defaultValue: 'Guest',
  );
  static const tempGuestPassword = String.fromEnvironment(
    'AUTH_TEMP_GUEST_PASSWORD',
    defaultValue: 'guest',
  );
  static const minPasswordLength = int.fromEnvironment(
    'AUTH_MIN_PASSWORD_LENGTH',
    defaultValue: 6,
  );
}
