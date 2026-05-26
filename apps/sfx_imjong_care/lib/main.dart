import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'core/error_boundary.dart';
import 'screens/postcard_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
