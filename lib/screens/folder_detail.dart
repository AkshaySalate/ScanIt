// lib/screens/folder_detail.dart
import 'package:flutter/material.dart';
import 'package:scanit/models/folder.dart';

class FolderDetailScreen extends StatelessWidget {
  final Folder folder;

  const FolderDetailScreen({Key? key, required this.folder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folder.name),
      ),
      body: Center(
        child: Text('Contents of folder "${folder.name}" go here'),
      ),
    );
  }
}
