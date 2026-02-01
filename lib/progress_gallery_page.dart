import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';

class ProgressGalleryPage extends StatefulWidget {
  const ProgressGalleryPage({super.key});

  @override
  State<ProgressGalleryPage> createState() => _ProgressGalleryPageState();
}

class _ProgressGalleryPageState extends State<ProgressGalleryPage> {
  final Box _progressBox = Hive.box('progressBox');
  final ImagePicker _picker = ImagePicker();

  // List of Map entries {'key': '2024-02', 'path': '/data/...', 'date': DateTime}
  List<Map<String, dynamic>> _galleryItems = [];

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  void _loadImages() {
    final keys = _progressBox.keys.cast<String>().toList();
    final List<Map<String, dynamic>> items = [];

    for (var key in keys) {
      // Key format is "YYYY-MM"
      List<String> parts = key.split('-');
      DateTime date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
      String filePath = _progressBox.get(key);

      items.add({
        'key': key,
        'path': filePath,
        'date': date,
      });
    }

    // Sort oldest to newest for the slideshow
    items.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));

    setState(() {
      _galleryItems = items;
    });
  }

  Future<void> _takePhoto() async {
    // 1. Check if current month already has a photo
    String currentMonthKey = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

    if (_progressBox.containsKey(currentMonthKey)) {
      bool confirm = await _showOverwriteDialog();
      if (!confirm) return;
    }

    // 2. Pick Image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    // Note: Change source: ImageSource.camera if you prefer direct camera access

    if (image == null) return;

    // 3. Save to local app directory
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String fileName = 'progress_$currentMonthKey.jpg';
    final String localPath = path.join(appDir.path, fileName);

    // Copy image to our app's storage
    await File(image.path).copy(localPath);

    // 4. Save path to Hive
    await _progressBox.put(currentMonthKey, localPath);

    _loadImages();
  }

  Future<bool> _showOverwriteDialog() async {
    return await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2927),
        title: const Text("Replace Photo?"),
        content: const Text("You already have a photo for this month. Do you want to replace it?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Replace")),
        ],
      ),
    ) ?? false;
  }

  void _openSlideshow(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SlideshowViewer(items: _galleryItems, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Monthly Progress"),
        backgroundColor: Colors.transparent,
      ),
      body: _galleryItems.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, size: 60, color: Colors.grey[800]),
            const SizedBox(height: 10),
            const Text("No photos yet.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            const Text("Upload one for this month!", style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.8,
        ),
        itemCount: _galleryItems.length,
        itemBuilder: (context, index) {
          final item = _galleryItems[index];
          File imgFile = File(item['path']);
          DateTime date = item['date'];

          return GestureDetector(
            onTap: () => _openSlideshow(index),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: FileImage(imgFile),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.darken),
                ),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    ),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy').format(date),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _takePhoto,
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text("Add This Month", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

// --- SLIDESHOW VIEWER WIDGET ---
class SlideshowViewer extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int initialIndex;

  const SlideshowViewer({super.key, required this.items, required this.initialIndex});

  @override
  State<SlideshowViewer> createState() => _SlideshowViewerState();
}

class _SlideshowViewerState extends State<SlideshowViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          children: [
            Text(
              DateFormat('MMMM yyyy').format(widget.items[_currentIndex]['date']),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              "${_currentIndex + 1} of ${widget.items.length}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Center(
            child: Image.file(
              File(widget.items[index]['path']),
              fit: BoxFit.contain,
            ),
          );
        },
      ),
    );
  }
}