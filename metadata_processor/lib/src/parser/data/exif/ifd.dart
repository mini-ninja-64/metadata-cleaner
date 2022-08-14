import 'dart:typed_data';

import 'package:metadata_processor/src/parser/data/exif/tag.dart';
import 'package:metadata_processor/src/utils.dart';

class ImageFileDirectory {
  final List<Tag> interoptabilityArray;

  ImageFileDirectory(this.interoptabilityArray);

  @override
  String toString() {
    return interoptabilityArray.map((tag) => tag.toString()).join("\n");
  }

  Uint8List toExifBytes(int ifdOffset, [bool finalIfd = true]) {
    // TODO: need endian from somewhere
    final endianness = Endian.big;
    Uint8List arraySize =
        unsignedIntToBytes(endianness, interoptabilityArray.length, 2);

    final sizeOfInteroptabilityArray = interoptabilityArray.length * 12;
    Uint8List interoptabilityArrayBytes = Uint8List(sizeOfInteroptabilityArray);
    var interoptabilityArrayBytesPos = 0;

    List<Uint8List> exifExtraData = [];
    var exifExtraDataPos = ifdOffset + // offset to ifd from tiff header
        2 + // ifd array size
        sizeOfInteroptabilityArray + // interoptability array
        4; // pointer to next ifd block

    // OffsetTag chunks such as SubIfd's must go at the very end of IFD data
    final Map<int, OffsetTag> offsetTags = {};

    for (var tag in interoptabilityArray) {
      interoptabilityArrayBytes.setRange(
          interoptabilityArrayBytesPos,
          interoptabilityArrayBytesPos + 2,
          unsignedIntToBytes(endianness, tag.id, 2));
      interoptabilityArrayBytesPos += 2;

      interoptabilityArrayBytes.setRange(
          interoptabilityArrayBytesPos,
          interoptabilityArrayBytesPos + 2,
          unsignedIntToBytes(endianness, tag.type.id, 2));
      interoptabilityArrayBytesPos += 2;

      interoptabilityArrayBytes.setRange(
          interoptabilityArrayBytesPos,
          interoptabilityArrayBytesPos + 4,
          unsignedIntToBytes(endianness, tag.count, 4));
      interoptabilityArrayBytesPos += 4;

      final Uint8List dataToInsertBigEndian;
      if (tag is OffsetTag) {
        // Temporary pointer to the sub ifd, this will be updated later as sub
        // ifds MUST go after the parent IFDs data
        dataToInsertBigEndian = unsignedIntToBytes(endianness, 0, 4);
        offsetTags[interoptabilityArrayBytesPos] = tag;
      } else {
        dataToInsertBigEndian = Uint8List(tag.tagData.lengthInBytes);
        dataToInsertBigEndian.setAll(0, tag.tagData);
      }

      Uint8List dataToInsert = (endianness == Endian.big)
          ? dataToInsertBigEndian
          // TODO: will not work for all data types, eg rationals
          : reverseBytes(dataToInsertBigEndian);

      if (dataToInsert.lengthInBytes > 4) {
        interoptabilityArrayBytes.setRange(
            interoptabilityArrayBytesPos,
            interoptabilityArrayBytesPos + 4,
            unsignedIntToBytes(endianness, exifExtraDataPos, 4));

        exifExtraData.add(dataToInsert);
        exifExtraDataPos += dataToInsert.lengthInBytes;
      } else {
        interoptabilityArrayBytes.setRange(
            interoptabilityArrayBytesPos,
            interoptabilityArrayBytesPos + dataToInsert.lengthInBytes,
            dataToInsert);
      }
      interoptabilityArrayBytesPos += 4;
    }

    for (var offsetTagEntry in offsetTags.entries) {
      final offsetTagPointerLocation = offsetTagEntry.key;
      final offsetTag = offsetTagEntry.value;

      final newOffsetTagPointer =
          unsignedIntToBytes(endianness, exifExtraDataPos, 4);
      interoptabilityArrayBytes.setRange(offsetTagPointerLocation,
          offsetTagPointerLocation + 4, newOffsetTagPointer);

      switch (offsetTag.runtimeType) {
        case SubIfdTag:
          offsetTag as SubIfdTag;
          for (var subIfd in offsetTag.imageFileDirectories) {
            final subIfdBytes = subIfd.toExifBytes(exifExtraDataPos);
            exifExtraDataPos += subIfdBytes.lengthInBytes;
            exifExtraData.add(subIfdBytes);
          }
          break;
        case ThumbnailTag:
          offsetTag as ThumbnailTag;
          exifExtraDataPos += offsetTag.thumbnailData.lengthInBytes;
          exifExtraData.add(offsetTag.thumbnailData);
          break;
        default:
          final offsetData = offsetTag.tagData;
          exifExtraDataPos += offsetData.lengthInBytes;
          exifExtraData.add(offsetData);
          break;
      }
    }

    var renderedIfdChunk = arraySize + interoptabilityArrayBytes;
    // if finalIfd set next ifd pointer to 0 otherwise set pointer to directly after this chunk
    renderedIfdChunk +=
        unsignedIntToBytes(endianness, finalIfd ? 0 : exifExtraDataPos, 4);

    for (var extraData in exifExtraData) {
      renderedIfdChunk += extraData;
    }

    return Uint8List.fromList(renderedIfdChunk);
  }
}
