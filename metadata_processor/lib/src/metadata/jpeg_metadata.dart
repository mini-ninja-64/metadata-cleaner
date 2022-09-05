import 'package:metadata_processor/metadata_processor.dart';
import 'package:metadata_processor/src/parser/data/exif/ifd.dart';
import 'package:metadata_processor/src/parser/data/exif/tag.dart';
import 'package:metadata_processor/src/parser/file/jpeg/segment.dart';
import 'package:metadata_processor/src/parser/file/png/text_chunk.dart';

class JpegMetadata extends FileMetadata {
  final JpegFile file;

  JpegMetadata(this.file);

  Iterable<Tag> getTagsFromIfd(ImageFileDirectory ifd) {
    List<Tag> allTags = List.empty(growable: true);
    for (final tag in ifd.interoptabilityArray) {
      if (tag is SubIfdTag) {
        final tags = tag.imageFileDirectories.expand(getTagsFromIfd);
        allTags.addAll(tags);
      } else {
        allTags.add(tag);
      }
    }
    return allTags;
  }

  Iterable<ExifData> get exifData => file.segments
      .whereType<ExifSegment>()
      .map((segment) => segment.asExifData);

  @override
  List<MetadataTag> get allTags => exifData
      .expand((exif) => exif.imageFileDirectories.expand(getTagsFromIfd))
      .map((tag) => ImmutableMetadataTag(tag.name, tag.dataAsString))
      .toList();

  @override
  void deleteTag(int tagToDelete) {}
}
