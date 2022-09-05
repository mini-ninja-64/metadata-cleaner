import 'package:flutter/material.dart';
import 'package:metadata_cleaner/screens/metadata_editor_screen.dart';
import 'package:metadata_cleaner/widgets/recent_image_gallery.dart';

class ImagePickerScreen extends StatelessWidget {
  const ImagePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: const Icon(Icons.camera),
            title: const Text("Select an image")),
        body: RecentImageGallery(
          onImageSelect: (file) async {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MetadataEditorScreen(file: file)));
          },
        ));
  }
}
