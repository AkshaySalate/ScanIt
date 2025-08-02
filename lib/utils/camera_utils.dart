//lib/utils/camera_utils.dart
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

Future<String?> pickImageWithCamera(BuildContext context) async {
  var status = await Permission.camera.status;
  if (!status.isGranted) {
    status = await Permission.camera.request();
    if (!status.isGranted) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Camera Permission Needed'),
          content: const Text('ScanIT needs camera access to scan documents. Please enable camera permission in your settings.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return null;
    }
  }

  final picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.camera);
  return image?.path;
}
