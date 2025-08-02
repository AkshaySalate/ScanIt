import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:scanit/models/folder.dart';
import 'folder_detail.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scanit/utils/camera_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Box<Folder> foldersBox;

  @override
  void initState() {
    super.initState();
    foldersBox = Hive.box<Folder>('foldersBox');
    // Set up initial folders if app is run for the first time
    if (foldersBox.isEmpty) {
      foldersBox.addAll([
        Folder(id: '1', name: 'ScanIT'),
        Folder(id: '2', name: 'Receipts'),
        Folder(id: '3', name: 'Work Docs'),
      ]);
    }
  }

  Future<void> _openCamera() async {
    final Folder? selectedFolder = await _showFolderPicker();
    if (selectedFolder == null) return;

    final imagePath = await pickImageWithCamera(context);
    if (imagePath != null) {
      selectedFolder.images.add(imagePath);
      await selectedFolder.save();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to "${selectedFolder.name}" folder!')),
      );
    }
  }

  void _addFolder() {
    String folderName = '';
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // Make barrier fully transparent to see blur
      builder: (context) => Stack(
        children: [
          // Full screen blurred backdrop
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withOpacity(0.3), // Maintain a subtle dark overlay if you want
            ),
          ),
          // Centered Dialog as before
          Center(
            child: Dialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.tealAccent.withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'New Folder Name',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      autofocus: true,
                      onChanged: (value) => folderName = value,
                      decoration: InputDecoration(
                        hintText: 'Folder name',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.10),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.teal.shade800,
                              side: BorderSide(color: Colors.teal.shade200, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (folderName.trim().isNotEmpty) {
                              foldersBox.add(Folder(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                name: folderName.trim(),
                              ));
                              Navigator.pop(context);
                              setState(() {});
                            }
                          },
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFolderMenu(Folder folder, BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.tealAccent.withOpacity(0.13),
            ],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.only(top: 18, bottom: 24),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: Colors.teal.shade800),
                title: const Text('Rename', style: TextStyle(fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _renameFolder(folder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteFolder(folder);
                },
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }


  void _renameFolder(Folder folder) {
    String folderName = folder.name;
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // important to see through to blur
      builder: (context) => Stack(
        children: [
          // Blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withOpacity(0.3), // subtle dark overlay
            ),
          ),
          // Centered dialog as before, unchanged
          Center(
            child: Dialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.tealAccent.withOpacity(0.10),
                    ],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Rename Folder',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      autofocus: true,
                      controller: TextEditingController(text: folderName),
                      onChanged: (val) => folderName = val,
                      decoration: InputDecoration(
                        hintText: 'New folder name',
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.10),
                        contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal.shade800,
                            side:
                            BorderSide(color: Colors.teal.shade200, width: 1.5),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            padding:
                            const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () async {
                            if (folderName.trim().isNotEmpty &&
                                folderName != folder.name) {
                              folder.name = folderName.trim();
                              await folder.save();
                              setState(() {});
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Rename'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteFolder(Folder folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent, // make barrier transparent for blur effect
      builder: (context) => Stack(
        children: [
          // Blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withOpacity(0.3), // subtle dark overlay
            ),
          ),
          // Centered dialog box
          Center(
            child: Dialog(
              backgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Colors.tealAccent.withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.teal.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red.shade400, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'Delete Folder?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This will permanently delete the folder and all its scans. Are you sure you want to proceed?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal.shade700,
                            side: BorderSide(color: Colors.teal.shade200, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await folder.delete();
      setState(() {});
    }
  }

  Future<Folder?> _showFolderPicker() async {
    String? newFolderName;

    return showDialog<Folder>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) =>Stack(
        children: [
          // Blurred background layer
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              color: Colors.black.withOpacity(0.3), // Optional: dark tint over blur
            ),
          ),
          StatefulBuilder(
              builder: (context, setDialogState) {
                // ✅ Move inside so it's always up-to-date
                final folders = foldersBox.values.toList();

                return Dialog(
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 420),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          //Colors.teal.shade100.withOpacity(0.45),
                          Colors.white,
                          Colors.tealAccent.withOpacity(0.12),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      color: Colors.white.withOpacity(0.96),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Select Folder",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          itemCount: folders.length + 1,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 1),
                          itemBuilder: (context, i) {
                            if (i < folders.length) {
                              final folder = folders[i];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => Navigator.pop(context, folder),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.teal.shade50,
                                          Colors.white.withOpacity(0.94),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.teal.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.folder_rounded, color: Colors.teal.shade700, size: 32),
                                        const SizedBox(height: 10),
                                        Text(folder.name,
                                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () async {
                                    String? newFolderName;

                                    await showDialog(
                                      context: context,
                                      barrierColor: Colors.transparent, // Transparent to show blur
                                      builder: (context2) => Stack(
                                        children: [
                                          // Blurred background
                                          BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                                            child: Container(
                                              color: Colors.black.withOpacity(0.2), // subtle dark overlay
                                            ),
                                          ),
                                          // Centered dialog box matching Rename UI
                                          Center(
                                            child: Dialog(
                                              backgroundColor: Colors.transparent,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.white,
                                                      Colors.tealAccent.withOpacity(0.10),
                                                    ],
                                                    begin: Alignment.topRight,
                                                    end: Alignment.bottomLeft,
                                                  ),
                                                  borderRadius: BorderRadius.circular(24),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.teal.withOpacity(0.08),
                                                      blurRadius: 18,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(24),
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Text(
                                                      'New Folder Name',
                                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                                    ),
                                                    const SizedBox(height: 18),
                                                    TextField(
                                                      autofocus: true,
                                                      onChanged: (val) => newFolderName = val,
                                                      decoration: InputDecoration(
                                                        hintText: 'Folder name',
                                                        filled: true,
                                                        fillColor: Colors.grey.withOpacity(0.10),
                                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(15),
                                                          borderSide: BorderSide.none,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 22),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                      children: [
                                                        OutlinedButton(
                                                          style: OutlinedButton.styleFrom(
                                                            foregroundColor: Colors.teal.shade800,
                                                            side: BorderSide(color: Colors.teal.shade200, width: 1.5),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                          ),
                                                          onPressed: () => Navigator.pop(context2),
                                                          child: const Text('Cancel'),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.teal.shade700,
                                                            foregroundColor: Colors.white,
                                                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                          ),
                                                          onPressed: () {
                                                            if (newFolderName != null && newFolderName!.trim().isNotEmpty) {
                                                              foldersBox.add(Folder(
                                                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                                                name: newFolderName!.trim(),
                                                              ));
                                                              newFolderName = '';
                                                              setDialogState(() {}); // Trigger rebuild to show new folder
                                                            }
                                                            Navigator.pop(context2);
                                                          },
                                                          child: const Text('Add'),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.tealAccent.withOpacity(0.14),
                                          Colors.white.withOpacity(0.93),
                                        ],
                                        begin: Alignment.bottomRight,
                                        end: Alignment.topLeft,
                                      ),
                                      border: Border.all(
                                        color: Colors.teal.shade300,
                                        width: 1.4,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: const Center(
                                      child: Icon(Icons.add, color: Colors.teal, size: 45),
                                    ),
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;
    double sidePadding = MediaQuery.of(context).size.width > 600 ? 32 : 16;

    // Use ValueListenableBuilder for automatic UI updates
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF7F5EE),
            Color(0xFFEAE6FB),
            Color(0xFFEFF6F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'ScanIT',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.add_rounded, color: Colors.teal.shade800),
              onPressed: _addFolder,
              tooltip: 'Add Folder',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16, top: 8),
                child: Text(
                  'Welcome to ScanIT by Salate',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Text(
                "Folders",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: foldersBox.listenable(),
                  builder: (context, Box<Folder> box, _) {
                    final folders = box.values.toList();
                    if (folders.isEmpty) {
                      return const Center(child: Text("No folders yet."));
                    }
                    return GridView.builder(
                      itemCount: folders.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 22,
                        mainAxisSpacing: 22,
                        childAspectRatio: 1.0,
                      ),
                        itemBuilder: (context, i) {
                          final folder = folders[i];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FolderDetailScreen(folder: folder),
                                ),
                              );
                            },
                            child: _FolderSquareCard(
                              folderName: folder.name,
                              onMorePressed: () => _showFolderMenu(folder, context),
                            ),
                          );
                        }
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.teal.shade800,
          foregroundColor: Colors.white,
          onPressed: _openCamera,
          child: const Icon(Icons.camera_alt_rounded, size: 32),
          tooltip: "Scan Document",
        ),
      ),
    );
  }
}

// Your square folder card widget
class _FolderSquareCard extends StatelessWidget {
  final String folderName;
  final VoidCallback onMorePressed;

  const _FolderSquareCard({
    required this.folderName,
    required this.onMorePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Existing folder card design
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.85),
                Colors.teal.withOpacity(0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.folder_rounded, color: Colors.teal.shade700, size: 38),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Text(
                    folderName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        // "More" button (top right)
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: Icon(Icons.more_vert, color: Colors.grey.shade700, size: 20),
            onPressed: onMorePressed,
            tooltip: 'Folder options',
          ),
        ),
      ],
    );
  }
}
