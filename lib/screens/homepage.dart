import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanit/models/folder.dart';
import 'folder_detail.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

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

    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Camera Permission Needed'),
            content: const Text(
                'ScanIT needs camera access to scan documents. Please enable camera permission in your settings.'),
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
        return;
      }
    }

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      // Update images list and save changes persistently
      selectedFolder.images.add(image.path);
      selectedFolder.save();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image saved to "${selectedFolder.name}" folder!')),
      );
      setState(() {}); // Refresh UI
    }
  }

  void _addFolder() {
    showDialog(
      context: context,
      builder: (context) {
        String folderName = '';
        return AlertDialog(
          title: const Text('New Folder Name'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => folderName = value,
            decoration: const InputDecoration(hintText: 'Folder name'),
          ),
          actions: [
            TextButton(
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            )
          ],
        );
      },
    );
  }

  void _showFolderMenu(Folder folder, BuildContext context) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Rename'),
                onTap: () async {
                  Navigator.pop(ctx);
                  _renameFolder(folder);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  _deleteFolder(folder);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }


  void _renameFolder(Folder folder) {
    String folderName = folder.name;
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Rename Folder'),
          content: TextField(
            autofocus: true,
            controller: TextEditingController(text: folderName),
            onChanged: (val) => folderName = val,
            decoration: const InputDecoration(hintText: 'New folder name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (folderName.trim().isNotEmpty && folderName != folder.name) {
                  folder.name = folderName.trim();
                  await folder.save();
                  setState(() {});
                }
                Navigator.pop(context);
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }


  void _deleteFolder(Folder folder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: const Text('This will permanently delete the folder and all its scans. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
    final folders = foldersBox.values.toList();
    return showDialog<Folder>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
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
                        // The "Add New Folder" card
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () async {
                              await showDialog(
                                context: context,
                                builder: (context2) => AlertDialog(
                                  title: const Text('New Folder Name'),
                                  content: TextField(
                                    autofocus: true,
                                    onChanged: (val) => newFolderName = val,
                                    decoration: const InputDecoration(hintText: 'Folder name'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context2),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (newFolderName != null && newFolderName!.trim().isNotEmpty) {
                                          foldersBox.add(Folder(
                                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                                            name: newFolderName!.trim(),
                                          ));
                                          newFolderName = '';
                                          setDialogState(() {});
                                        }
                                        Navigator.pop(context2);
                                      },
                                      child: const Text('Add'),
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
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add, color: Colors.teal, size: 45),
                                  ],
                                ),
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
