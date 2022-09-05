import 'dart:ffi';
import 'dart:typed_data';

import 'package:metadata_processor/src/parser/data/exif/ifd.dart';
import 'package:metadata_processor/src/parser/data/exif/tag.dart';
import 'package:metadata_processor/src/parser/data/exif/tiff_header.dart';
import 'package:metadata_processor/src/utils.dart';

class ExifData {
  final TiffHeader tiffHeader;
  final List<ImageFileDirectory> imageFileDirectories;

  @override
  String toString() {
    String stringForm = "";
    int ifdCount = 0;
    for (var ifd in imageFileDirectories) {
      stringForm += "\nIFD $ifdCount";
      stringForm += "\n$ifd";
      ifdCount++;
    }
    return stringForm;
  }

  Map<String, String> get fields {
    int ifdCount = 0;
    for (var ifd in imageFileDirectories) {
      print("IFD $ifdCount");
      print(ifd);
      ifdCount++;
    }
    return {};
  }

  static const _exifHeader = 0x457869660000;

  Uint8List get asExifBytes {
    List<Uint8List> chunks = [];
    // add exif header
    chunks.add(unsignedIntToBytes(Endian.big, _exifHeader, 6));

    var nextIfdOffset = imageFileDirectories.isEmpty ? 0 : 8;
    chunks.add(tiffHeader.toExifBytes(nextIfdOffset));

    for (var i = 0; i < imageFileDirectories.length; i++) {
      final ifdToAdd = imageFileDirectories[i];
      final finalIfd = i == imageFileDirectories.length - 1 ? true : false;

      chunks.add(ifdToAdd.toExifBytes(nextIfdOffset, finalIfd));
      nextIfdOffset += chunks.last.lengthInBytes;
    }

    return Uint8List.fromList(chunks.expand((element) => element).toList());
  }

  ExifData(this.tiffHeader, this.imageFileDirectories);

  factory ExifData.fromBytes(Uint8List data) {
    var bytePos = 0;
    // https://stackoverflow.com/questions/1821515/how-is-exif-info-encoded
    // https://www.codeproject.com/Articles/47486/Understanding-and-Reading-Exif-Data
    // https://metacpan.org/release/BETTELLI/Image-MetaData-JPEG-0.10/view/lib/Image/MetaData/JPEG.pm

    // ############################### EXIF HEADER PARSING ###############################
    // first 6 bytes reserved for EXIF header
    final exifHeader = valueFromBytes(Endian.big, data, bytePos, 6);
    bytePos += 6;
    // exif magic number = 0x457869660000 = "Exif\000\000"
    assert(exifHeader == 0x457869660000);

    // ############################### TIFF HEADER PARSING ###############################
    // calculate "tiff header" (the tiff header is made of 3 distinct components: endianness, signature, IFD0_Pointer)
    // 2 byte flag to show endianness / byte ordering
    final endiannessValue = valueFromBytes(Endian.big, data, bytePos, 2);
    bytePos += 2;

    var endianness = Endian.big; // most common in my experience
    // https://www.metadata2go.com/file-info/byte-order
    if (endiannessValue == 0x4D4D /*"MM"*/) {
      endianness = Endian.big;
      print("Big Endian (motorolla ordering)");
    } else if (endiannessValue == 0x4949 /*"II"*/) {
      endianness = Endian.little;
      print("Little Endian (intel ordering)");
    } else {
      throw FormatException("Unknown endianess in exif data");
    }

    // 2 byte exif signature (always 42)
    final signature = valueFromBytes(endianness, data, bytePos, 2);
    bytePos += 2;
    assert(signature == 42);

    // pointer to ifd0
    final ifd0Pointer = valueFromBytes(endianness, data, bytePos, 4);
    bytePos += 4;

    final tiffHeader = TiffHeader(endianness, signature);
    // -8 as ifd0 pointer is offset from the start of the tiff header
    final tiffHeaderPos = bytePos - 8;

    Uint8List exifDataCallback(int offsetFromTiffHeader, int size) {
      final calculatedDataPos = tiffHeaderPos + offsetFromTiffHeader;
      return data.sublist(calculatedDataPos, calculatedDataPos + size);
    }

    List<ImageFileDirectory> ifdList =
        parseIfds(endianness, ifd0Pointer, exifDataCallback);

    return ExifData(tiffHeader, ifdList);
  }
}

typedef ExifDataCallback = Uint8List Function(
    int offsetFromTiffHeader, int size);

Tag parseTag(Endian endianness, int tagPos, ExifDataCallback exifDataCallback,
    int currentIfd) {
  final tagData = exifDataCallback(tagPos, 12);
  var bytePos = 0;
  final tagId = valueFromBytes(endianness, tagData, bytePos, 2);
  bytePos += 2;

  final itemType = valueFromBytes(endianness, tagData, bytePos, 2);
  final tagType = TagType.fromExifValue(itemType);
  bytePos += 2;

  final itemCount = valueFromBytes(endianness, tagData, bytePos, 4);
  bytePos += 4;

  final rawDataSize = tagType.size.total * itemCount;
  final Uint8List rawData;
  if (rawDataSize > 4) {
    final offsetToValue = valueFromBytes(endianness, tagData, bytePos, 4);
    rawData = exifDataCallback(offsetToValue, rawDataSize);
    // print("offset data for tag 0x${tagId.toRadixString(16)}: ${rawData.map((e) => "0x" + e.toRadixString(16)).toList()}");
  } else {
    rawData = tagData.sublist(bytePos, bytePos + rawDataSize);
  }
  bytePos += 4;

  final normalizedData = (endianness == Endian.big)
      ? rawData
      // TODO: reversing not enough for stuff like rationals, have to properly use tagType sizes etc
      : reverseBytes(rawData);

  switch (tagId) {
    case 0x8769:
    case 0x8825:
    case 0xA005:
      print("nested ifd found id: ${tagId.toRadixString(16)}");
      final nestedIfdOffset = sumBytes(Endian.big, normalizedData);
      final subIfds =
          parseIfds(endianness, nestedIfdOffset, exifDataCallback, tagId);
      return SubIfdTag(
          tagId, tagType, itemCount, normalizedData, subIfds, currentIfd);
  }

  switch (tagType) {
    case TagType.byte:
      return ByteTag(tagId, tagType, itemCount, normalizedData, currentIfd);
    case TagType.ascii:
      return AsciiTag(tagId, tagType, itemCount, normalizedData, currentIfd);
    case TagType.short:
      return ShortTag(tagId, tagType, itemCount, normalizedData, currentIfd);
    case TagType.long:
      return LongTag(tagId, tagType, itemCount, normalizedData, currentIfd);
    case TagType.rational:
      return RationalTag(tagId, tagType, itemCount, normalizedData, currentIfd);
    case TagType.undefined:
      return UndefinedTag(
          tagId, tagType, itemCount, normalizedData, currentIfd);
    case TagType.signedLong:
      return SignedLongTag(
          tagId, tagType, itemCount, normalizedData, currentIfd);
    case TagType.signedRational:
      return SignedRationalTag(
          tagId, tagType, itemCount, normalizedData, currentIfd);
  }
}

List<ImageFileDirectory> parseIfds(
    Endian endianness, int firstIfdPos, ExifDataCallback exifDataCallback,
    [int? ifdId]) {
  List<ImageFileDirectory> ifdList = [];

  var ifdPointer = firstIfdPos;
  while (ifdPointer != 0) {
    // ############################### IFD BLOCK PARSING ###############################
    var bytePos = ifdPointer;

    ifdId ??= ifdList.length;

    final arraySize = sumBytes(endianness, exifDataCallback(bytePos, 2));
    bytePos += 2;

    List<Tag> tags = [];
    for (var i = 0; i < arraySize; i++) {
      final tag = parseTag(endianness, bytePos, exifDataCallback, ifdId);

      tags.add(tag);

      bytePos += 12;
    }

    int? thumbnailTagIndex;
    int? thumbnailPointer;
    int? thumbnailSize;

    for (var i = 0; i < tags.length; i++) {
      final tag = tags[i];
      if (tag is UnsignedIntMixin) {
        switch (tag.id) {
          case 513:
            thumbnailTagIndex = i;
            thumbnailPointer = tag.asValues[0];
            break;
          case 514:
            thumbnailSize = tag.asValues[0];
            break;
        }
      }
    }

    if (thumbnailTagIndex != null &&
        thumbnailSize != null &&
        thumbnailPointer != null) {
      final tag = tags[thumbnailTagIndex];
      Uint8List thumbnailData =
          exifDataCallback(thumbnailPointer, thumbnailSize);
      tags[thumbnailTagIndex] = ThumbnailTag(
          tag.id, tag.type, tag.count, tag.tagData, thumbnailData, ifdId);
    }

    ifdPointer = sumBytes(endianness, exifDataCallback(bytePos, 4));
    bytePos += 4;

    var ifd = ImageFileDirectory(tags);
    ifdList.add(ifd);
  }

  return ifdList;
}
