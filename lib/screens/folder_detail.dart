// lib/screens/folder_detail.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:scanit/models/folder.dart';
import 'package:scanit/utils/camera_utils.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class FolderDetailScreen extends StatefulWidget {
  final Folder folder;
  const FolderDetailScreen({Key? key, required this.folder}) : super(key: key);

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  String _searchQuery = "";

  void _editTags(String imagePath) {
    final currentTags = widget.folder.imageTags[imagePath] ?? [];
    final tagsController = TextEditingController(text: currentTags.join(', '));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Tags"),
        content: TextField(
          controller: tagsController,
          decoration: const InputDecoration(
            hintText: "Comma separated tags",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final tags = tagsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              setState(() {
                widget.folder.imageTags[imagePath] = tags;
                widget.folder.save();
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  List<String> _getFilteredImages() {
    if (_searchQuery.isEmpty) return widget.folder.images;

    return widget.folder.images.where((img) {
      final tags = widget.folder.imageTags[img] ?? [];
      final inTags = tags.any((t) => t.toLowerCase().contains(_searchQuery.toLowerCase()));
      final inName = img.toLowerCase().contains(_searchQuery.toLowerCase());
      return inTags || inName;
    }).toList();
  }

  Future<void> _openCamera() async {
    final imagePaths = await pickImagesWithCamera(context);
    if (imagePaths.isNotEmpty) {
      // Add all scanned images to the folder
      setState(() {
        widget.folder.images.addAll(imagePaths);
        widget.folder.save();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${imagePaths.length} document(s) scanned and saved!')),
      );
    }

  }

  Future<Directory?> getPublicScanItFolder() async {
    // On Android, this gives something like /storage/emulated/0/Android/data/<package>/files
    Directory? baseDir = await getExternalStorageDirectory();
    if (baseDir == null) return null;

    // Step up to /storage/emulated/0
    final segments = baseDir.path.split("/");
    // Remove 'Android', 'data', ... to get to root of internal storage
    int androidIndex = segments.indexOf('Android');
    String root = segments.sublist(0, androidIndex).join('/');
    final documents = Directory('$root/Documents/ScanIT');

    if (!await documents.exists()) {
      await documents.create(recursive: true);
    }
    return documents;
  }

  Future<bool> ensureStoragePermission() async {
    // First: Request Manage External Storage permission on Android 11+
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    } else {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) {
        return true;
      }
    }

    // Fallback: Request MANAGE_EXTERNAL_STORAGE permission for Android 11+, other devices Storage permission
    if (await Permission.storage.isGranted) {
      return true;
    } else {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        return true;
      }
    }

    // If here, permission denied
    return false;
  }


  Future<void> _showExportOptionsDialog() async {
    final TextEditingController controller = TextEditingController(text: widget.folder.name);
    bool exportAsPdf = true;

    await showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          // --- Blurred Background ---
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(color: Colors.black.withOpacity(0.15)),
          ),
          // --- Centered Dialog Card ---
          Center(
            child: Dialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: Container(
                constraints: const BoxConstraints(minWidth: 300, maxWidth: 380),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.tealAccent.withOpacity(0.08),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.10),
                      blurRadius: 24,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
                child: StatefulBuilder(
                  builder: (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon + Title
                      Icon(Icons.import_export_rounded, color: Colors.teal.shade600, size: 44),
                      const SizedBox(height: 14),
                      const Text(
                        'Export Scanned Images',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Create a PDF or save images in your Documents/ScanIT folder.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      // Document Name Field
                      TextField(
                        controller: controller,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.teal),
                        decoration: InputDecoration(
                          hintText: 'Document Name',
                          filled: true,
                          fillColor: Colors.tealAccent.withOpacity(0.06),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          prefixIcon: Icon(Icons.edit_note_rounded, color: Colors.teal.shade300),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Export Type Toggle
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.teal.shade50.withOpacity(0.65),
                              Colors.white.withOpacity(0.82),
                            ],
                            begin: Alignment.bottomRight,
                            end: Alignment.topLeft,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(() => exportAsPdf = true),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  decoration: BoxDecoration(
                                    color: exportAsPdf ? Colors.teal.shade100.withOpacity(0.38) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: exportAsPdf ? Colors.teal.shade400 : Colors.transparent,
                                      width: exportAsPdf ? 1.4 : 0,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.picture_as_pdf_rounded, color: Colors.teal.shade800, size: 24),
                                      const SizedBox(width: 7),
                                      Text(
                                        "PDF",
                                        style: TextStyle(
                                          color: Colors.teal.shade900,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(() => exportAsPdf = false),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  decoration: BoxDecoration(
                                    color: !exportAsPdf ? Colors.teal.shade100.withOpacity(0.38) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: !exportAsPdf ? Colors.teal.shade400 : Colors.transparent,
                                      width: !exportAsPdf ? 1.4 : 0,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_rounded, color: Colors.teal.shade800, size: 24),
                                      const SizedBox(width: 7),
                                      Text(
                                        "PNGs",
                                        style: TextStyle(
                                          color: Colors.teal.shade900,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade700,
                              side: BorderSide(color: Colors.teal.shade200, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                              elevation: 2,
                            ),
                            onPressed: () async {
                              Navigator.pop(context);
                              if (exportAsPdf) {
                                await _exportAsPdf(controller.text.trim());
                              } else {
                                await _exportAsPngs(controller.text.trim());
                              }
                            },
                            child: const Text('Export', style: TextStyle(fontSize: 16)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsPdf(String name) async {
    if (widget.folder.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No images to export.")),
      );
      return;
    }
    if (!await ensureStoragePermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission required to save file.')),
      );
      return;
    }

    final pdf = pw.Document();
    for (final path in widget.folder.images) {
      final imageBytes = await File(path).readAsBytes();
      final pdfImage = pw.MemoryImage(imageBytes);
      pdf.addPage(
        pw.Page(
          build: (_) => pw.Center(child: pw.Image(pdfImage)),
          pageFormat: PdfPageFormat.a4,
        ),
      );
    }

    final dir = await getPublicScanItFolder();
    if (dir == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to access Documents/ScanIT.')),
      );
      return;
    }

    final filename = (name.isNotEmpty ? name : widget.folder.name) + ".pdf";
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to: ${file.path}')),
    );
  }

  Future<void> _exportAsPngs(String name) async {
    if (widget.folder.images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No images to export.")),
      );
      return;
    }
    if (!await ensureStoragePermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission required to save file.')),
      );
      return;
    }


    final dir = await getPublicScanItFolder(); // <-- Always save in ScanIT
    int count = 1;
    for (final path in widget.folder.images) {
      final src = File(path);
      if (await src.exists()) {
        final fileName =
        (name.isNotEmpty ? "${name}_$count.png" : "ScanIt-$count.png");
        final dest = File('${dir?.path}/$fileName');
        await dest.writeAsBytes(await src.readAsBytes());
        count++;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Images saved in: ${dir?.path}')),
    );
  }


  @override
  @override
  Widget build(BuildContext context) {
    final images = _getFilteredImages();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folder.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            onPressed: _showExportOptionsDialog,
            tooltip: "Export as PDF/Images",
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search",
            onPressed: () async {
              final result = await showSearch<String?>(
                context: context,
                delegate: _ImageSearchDelegate(widget.folder),
              );
              if (result != null) {
                setState(() => _searchQuery = result);
              }
            },
          ),
        ],
      ),
      body: images.isEmpty
          ? Center(
        child: Text(
          'No scans found.\nTap the camera button below to add your first document!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: images.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16),
        itemBuilder: (context, i) {
          final imgPath = images[i];
          final tags = widget.folder.imageTags[imgPath] ?? [];
          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  child: Image.file(File(imgPath), fit: BoxFit.contain),
                ),
              );
            },
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(imgPath), fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(
                  bottom: 4,
                  left: 4,
                  right: 4,
                  child: Wrap(
                    spacing: 4,
                    children: [
                      for (final t in tags)
                        Chip(
                          label: Text(t, style: const TextStyle(fontSize: 10)),
                          backgroundColor: Colors.black54,
                          labelStyle: const TextStyle(color: Colors.white),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _editTags(imgPath),
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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

class _ImageSearchDelegate extends SearchDelegate<String?> {
  final Folder folder;
  _ImageSearchDelegate(this.folder);

  @override
  List<Widget> buildActions(BuildContext context) =>
      [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];

  @override
  Widget buildLeading(BuildContext context) =>
      IconButton(onPressed: () => close(context, null), icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) {
    final results = folder.images.where((img) {
      final tags = folder.imageTags[img] ?? [];
      return img.toLowerCase().contains(query.toLowerCase()) ||
          tags.any((t) => t.toLowerCase().contains(query.toLowerCase()));
    }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (_, i) {
        final imgPath = results[i];
        return ListTile(
          leading: Image.file(File(imgPath), width: 50, height: 50, fit: BoxFit.cover),
          title: Text(imgPath.split('/').last),
          subtitle: Text((folder.imageTags[imgPath] ?? []).join(', ')),
          onTap: () => close(context, query),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) => buildResults(context);
}

