import 'package:metadata_processor/metadata_processor.dart';
import 'package:metadata_processor/src/parser/data/exif/ifd.dart';
import 'package:metadata_processor/src/parser/data/exif/tag.dart';
import 'package:metadata_processor/src/parser/file/jpeg/segment.dart';

class JpegMetadata extends FileMetadata {
  final JpegFile file;

  JpegMetadata(this.file);

  Iterable<MapEntry<Tag, ImageFileDirectory>> getTagsFromIfd(ImageFileDirectory ifd) {
    List<MapEntry<Tag, ImageFileDirectory>> allTags = List.empty(growable: true);
    for (final tag in ifd.interoptabilityArray) {
      if (tag is SubIfdTag) {
        final tags = tag.imageFileDirectories.expand(getTagsFromIfd);
        allTags.addAll(tags);
      } else {
        allTags.add(MapEntry(tag, ifd));
      }
    }
    return allTags;
  }

  Iterable<MapEntry<Segment, ExifData>> get exifData => file.segments
      .whereType<ExifSegment>()
      .map((segment) => MapEntry(segment, segment.asExifData));

  @override
  List<MetadataTag> get allTags {
    return exifData
        .expand((exifEntry) =>
            exifEntry.value.imageFileDirectories.expand(getTagsFromIfd))
        .map((tag) => ImmutableMetadataTag(tag.key.name, tag.key.dataAsString))
        .toList();
  }

  @override
  void deleteTag(int tagToDelete) {
    List<_UpdatableTag> tagsMappedToIfd = exifData
        .expand((exifEntry) => exifEntry.value.imageFileDirectories
            .expand((ifd) => getTagsFromIfd(ifd).map((tag) {
                  final segment = exifEntry.key;
                  final exifData = exifEntry.value;
                  return _UpdatableTag(tag.key, tag.value, segment, exifData);
                })))
        .toList();

    final tagToDeleteData = tagsMappedToIfd[tagToDelete];

    tagToDeleteData.ifd.interoptabilityArray.remove(tagToDeleteData.tag);
    tagToDeleteData.segment.data = tagToDeleteData.exifData.asExifBytes;
  }
}

class _UpdatableTag {
  final Tag tag;
  final ImageFileDirectory ifd;
  final Segment segment;
  final ExifData exifData;

  _UpdatableTag(this.tag, this.ifd, this.segment, this.exifData);
}