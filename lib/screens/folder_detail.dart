// lib/screens/folder_detail.dart
import 'dart:io';

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
      body: folder.images.isEmpty
          ? const Center(child: Text("No scans yet."))
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: folder.images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16),
        itemBuilder: (context, i) => Image.file(
            File(folder.images[i]), fit: BoxFit.cover),
      ),
    );
  }
}
