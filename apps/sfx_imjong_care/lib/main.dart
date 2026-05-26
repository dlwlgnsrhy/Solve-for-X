import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'core/error_boundary.dart';
import 'screens/postcard_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with fallback mock options for environments without google-services config files
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "mock-api-key-1234567890-imjong-care",
        appId: "1:1234567890:ios:1234567890abcdef",
        messagingSenderId: "1234567890",
        projectId: "sfx-imjong-care",
      ),
    );
  } catch (e) {
    debugPrint("Firebase Initializer Safe-Guard: $e");
  }

  // Override default red screen with custom warm sepia error boundary
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorBoundary(errorDetails: details);
  };

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solve for X: Imjong Care',
      theme: AppTheme.creamTheme,
      home: const PostcardHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
