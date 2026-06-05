import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore, Settings;
import 'package:intl/date_symbol_data_local.dart';
import 'providers/theme_provider.dart';
import 'providers/rifa_provider.dart';
import 'providers/auth_provider.dart';
import 'services/firebase_service.dart';
import 'services/offline_queue_service.dart';
import 'config/constants.dart';
import 'app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  await AppConstants.loadChatbotUrl();
  await AppConstants.loadBotApiKey();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAuth.instance.signOut();

    // Enable Firestore offline persistence (mobile only)
    if (!kIsWeb) {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  await FirebaseService.instance.initialize();
  await OfflineQueueService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => RifaProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const RifaDoradaApp(),
    ),
  );
}
