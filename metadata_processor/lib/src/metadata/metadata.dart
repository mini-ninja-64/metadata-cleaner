import 'dart:typed_data';

abstract class MetadataTag {
  String get name;
  String get content;

  const MetadataTag();

  @override
  String toString() {
    return '$name: $content';
  }
}

class ImmutableMetadataTag extends MetadataTag {
  @override
  final String name;
  @override
  final String content;
  const ImmutableMetadataTag(this.name, this.content);
}


abstract class FileMetadata {
  List<MetadataTag> get allTags;
  Uint8List get fileBytes;

  void deleteTag(int tagToDelete);

  const FileMetadata();
}