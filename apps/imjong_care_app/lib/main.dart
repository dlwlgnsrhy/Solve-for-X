import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'lib/presentation/screens/home_screen.dart';

void main() {
  runApp(ProviderScope(child: MaterialApp(home: HomeScreen())));
}
