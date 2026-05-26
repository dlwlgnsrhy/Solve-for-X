import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';

void main() {
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

class PostcardHomeScreen extends StatelessWidget {
  const PostcardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '임종 케어 엽서',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          '크림 엽서의 평화로운 감성을 만나보세요.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
