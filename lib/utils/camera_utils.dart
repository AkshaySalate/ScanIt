import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

// Returns a list of all scanned page paths (multi-page support)
Future<List<String>> pickImagesWithCamera(BuildContext context) async {
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
      return [];
    }
  }

  try {
    // Get all scanned/cropped images (user can do multiple pages in one session)
    final images = await CunningDocumentScanner.getPictures() ?? [];
    return images; // Will be empty if cancelled
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Document scanning cancelled or failed.")),
    );
    return [];
  }
}

Future<String> extractTextFromImage(String filePath) async {
  final inputImage = InputImage.fromFilePath(filePath);
  final textRecognizer = TextRecognizer();
  final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
  await textRecognizer.close();
  return recognizedText.text;
}
