import 'package:flutter/material.dart';
import 'screens/homepage.dart'; // Import your home screen
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/folder.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(FolderAdapter());

  await Hive.openBox<Folder>('foldersBox');
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
