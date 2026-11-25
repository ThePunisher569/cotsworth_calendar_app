import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'core/storage/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await AppLocalStorageService.initialize();
  runApp(CotsworthApp(storage: storage));
}
