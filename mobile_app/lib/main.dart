import 'package:flutter/material.dart';
import 'app/main.dart';

void main() {
  runApp(const RifqaApp());
}

class RifqaApp extends StatelessWidget {
  const RifqaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رفقة بلاد الحرمين',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Arial',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF277D78),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6FAFA),
      ),
      home: const LoginPage(),
    );
  }
}