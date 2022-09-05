import 'dart:io';

import 'package:flutter/material.dart';
import 'package:metadata_cleaner/widgets/metadata_list.dart';
import 'package:metadata_processor/metadata_processor.dart';

class MockMetadata extends FileMetadata {
  final List<MetadataTag> tags = List.of(const [
    ImmutableMetadataTag("mock tag 1", "tag content"),
    ImmutableMetadataTag("mock tag 2", "tag content"),
    ImmutableMetadataTag("mock tag 3", "tag content"),
    ImmutableMetadataTag("mock tag 4", "tag content"),
    ImmutableMetadataTag("mock tag 5", "tag content"),
    ImmutableMetadataTag("mock tag 6", "tag content"),
    ImmutableMetadataTag("mock tag 7", "tag content"),
    ImmutableMetadataTag("mock tag 8", "tag content"),
    ImmutableMetadataTag("mock tag 9", "tag content"),
    ImmutableMetadataTag("mock tag 10", "tag content"),
    ImmutableMetadataTag("mock tag 11", "tag content"),
    ImmutableMetadataTag("mock tag 12", "tag content"),
    ImmutableMetadataTag("mock tag 13", "tag content"),
    ImmutableMetadataTag("mock tag 14", "tag content"),
    ImmutableMetadataTag("mock tag 15", "tag content"),
    ImmutableMetadataTag("mock tag 16", "tag content"),
    ImmutableMetadataTag("mock tag 17", "tag content")
  ], growable: true);

  @override
  List<MetadataTag> get allTags => tags;

  @override
  void deleteTag(int tagToDelete) {
    print("deleting tag");
    tags.removeAt(tagToDelete);
  }

  MockMetadata();
}

class MetadataEditorScreen extends StatelessWidget {
  final File file;
  final FileMetadata metadata;
  MetadataEditorScreen({super.key, required this.file})
      : metadata = JpegMetadata(JpegFile.fromFile(file));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: const Icon(Icons.edit_note_rounded),
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
