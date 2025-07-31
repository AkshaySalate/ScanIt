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
          ? Center(
              child: Text(
                "No scans yet.\nClick the camera button to add your first document!",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            )
          : GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: folder.images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16),
        // In the itemBuilder of your GridView
        itemBuilder: (context, i) => GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                child: Image.file(File(folder.images[i]), fit: BoxFit.contain),
              ),
            );
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Delete image?"),
                content: const Text("Are you sure you want to remove this scan?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      folder.images.removeAt(i);
                      Navigator.pop(context);
                      // Use setState at parent to update UI:
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(folder.images[i]), fit: BoxFit.cover),
          ),
        ),

      ),

    );
  }
}
