import 'package:flutter/material.dart';
import 'package:metadata_processor/metadata_processor.dart';

class MetadataList extends StatefulWidget {
  final FileMetadata metadata;
  final Image? image;

  const MetadataList({super.key, required this.metadata, this.image});

  @override
  State<MetadataList> createState() => _MetadataListState();
}

class _MetadataListState extends State<MetadataList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final tagIndex = index;
        final tag = widget.metadata.allTags[tagIndex];
        return ListTile(
          key: Key(tag.name),
          title: Text(tag.name),
          subtitle: Text(tag.content),
          trailing: IconButton(
            icon: const Icon(Icons.delete_rounded),
            onPressed: () => setState(() {
              widget.metadata.deleteTag(tagIndex);
            }),
          ),
        );
      },
      itemCount: widget.metadata.allTags.length,
    );
  }
}
