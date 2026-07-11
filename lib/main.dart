import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'app/chatty_pet_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const ChattyPetApp());
}
