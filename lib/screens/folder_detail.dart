// lib/screens/folder_detail.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:scanit/models/folder.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanit/utils/camera_utils.dart';


class FolderDetailScreen extends StatefulWidget {
  final Folder folder;
  const FolderDetailScreen({Key? key, required this.folder}) : super(key: key);

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  Future<void> _openCamera() async {
    final imagePath = await pickImageWithCamera(context);
    if (imagePath != null) {
      setState(() {
        widget.folder.images.add(imagePath);
        widget.folder.save();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Scanned document saved!')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final images = widget.folder.images;
    return Scaffold(
      appBar: AppBar(title: Text(widget.folder.name)),
      body: images.isEmpty
          ? Center(
        child: Text(
          'No scans yet.\nTap the camera button below to add your first document!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => Dialog(
                child: Image.file(File(images[i]), fit: BoxFit.contain),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(File(images[i]), fit: BoxFit.cover),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        onPressed: _openCamera,
        child: const Icon(Icons.camera_alt_rounded, size: 30),
        tooltip: "Scan Document",
      ),
    );
  }
}
