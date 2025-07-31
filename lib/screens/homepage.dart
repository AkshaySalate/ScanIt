import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scanit/models/folder.dart';
import 'folder_detail.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Folder> folders = [
    Folder(id: '1', name: 'ScanIT'),
    Folder(id: '2', name: 'Receipts'),
    Folder(id: '3', name: 'Work Docs'),
  ];

  Future<void> _openCamera() async {
    // Check camera permission status
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      // Request permission if not already granted
      status = await Permission.camera.request();
      if (!status.isGranted) {
        // Show dialog asking user to enable permission in settings
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
                  await openAppSettings(); // Opens the app settings page
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        return;
      }
    }

    // If permission is granted, open the camera as before
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Scanned: ${image.path}')),
      );
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
                  setState(() {
                    folders.add(Folder(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: folderName.trim(),
                    ));
                  });
                  Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    // Responsive column count based on width (2 for phones, more for wide screens)
    int crossAxisCount = MediaQuery.of(context).size.width > 600 ? 3 : 2;
    double sidePadding = MediaQuery.of(context).size.width > 600 ? 32 : 16;

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
                child: GridView.builder(
                  itemCount: folders.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 22,
                    mainAxisSpacing: 22,
                    childAspectRatio: 1.0, // Square!
                  ),
                  itemBuilder: (context, i) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FolderDetailScreen(folder: folders[i]),
                          ),
                        );
                      },
                      child: _FolderSquareCard(folderName: folders[i].name),
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

// Square, glassy look folder card with gradient overlay
class _FolderSquareCard extends StatelessWidget {
  final String folderName;

  const _FolderSquareCard({required this.folderName, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
