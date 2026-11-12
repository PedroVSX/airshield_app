
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'domain/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa notificações.
  await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: AirShieldApp(),
    ),
  );
}