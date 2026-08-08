import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const QuickMartApp());
}

class QuickMartApp extends StatelessWidget {
  const QuickMartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'कांकरीया सुपरमार्केट',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF2E7D32),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
