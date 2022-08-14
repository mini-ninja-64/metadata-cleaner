import 'dart:io';

import 'package:flutter/material.dart';

class MetadataEditorScreen extends StatelessWidget {
  final File file;
  const MetadataEditorScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: const Icon(Icons.edit_note_rounded),
            title: const Text("Edit image metadata")),
        body: Container(
          padding: const EdgeInsets.all(10),
            child: Column(
          children: [
            Center(
                child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.file(file, fit: BoxFit.cover)))),
            Text(file.uri.pathSegments.last)
          ],
        )));
  }
}
