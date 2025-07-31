import 'package:flutter/material.dart';
import 'screens/homepage.dart'; // Import your home screen

void main() {
  runApp(const ScanITApp());
}

class ScanITApp extends StatelessWidget {
  const ScanITApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScanIT',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: const HomeScreen(), // Now using imported HomeScreen
    );
  }
}
