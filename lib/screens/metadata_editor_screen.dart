import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metadata_cleaner/widgets/metadata_list.dart';
import 'package:metadata_processor/metadata_processor.dart';

FileMetadata metadataFromFile(File file) {
  final path = file.path.toLowerCase();
  if (path.endsWith(".jpeg") || path.endsWith(".jpg")) {
    return JpegMetadata(JpegFile.fromFile(file));
  } else if (path.endsWith(".png")) {
    return PngMetadata(PngFile.fromFile(file));
  }
  throw UnsupportedError(
      "This file type is currently unsupported: ${file.path}");
}

class MetadataEditorScreen extends StatelessWidget {
  final File file;
  final FileMetadata metadata;
  MetadataEditorScreen({super.key, required this.file})
      : metadata = metadataFromFile(file);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const Icon(Icons.edit_note_rounded),
          actions:  [Container(margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),child: IconButton(onPressed: () {
            final splitFilePath = file.path.split(".");
            splitFilePath.insert(splitFilePath.length - 1, "cleaned");

            final newFile = File(splitFilePath.join("."));
            final newFileBytes = metadata.fileBytes;

            newFile.writeAsBytes(newFileBytes);
          } , icon: const Icon(Icons.save_as_rounded)),)],
          title: const Text("Edit image metadata")),

      body: Column(
        children: [
          Container(
              padding: const EdgeInsets.all(10),
              child: Center(
                  child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: AspectRatio(
                          aspectRatio: 1,
                          child: Image.file(file, fit: BoxFit.cover))))),
          Expanded(
              child: MetadataList(
            metadata: metadata,
          ))
        ],
      ),
    );
  }
}
