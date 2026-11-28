import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/storage/local_storage_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (DefaultFirebaseOptions.isConfigured) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final storage = await AppLocalStorageService.initialize();
  runApp(CotsworthApp(storage: storage));
}
