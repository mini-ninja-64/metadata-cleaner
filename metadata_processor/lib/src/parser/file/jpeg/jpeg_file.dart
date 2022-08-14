import 'dart:collection';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:metadata_processor/src/parser/file/jpeg/segment.dart';
import 'package:metadata_processor/src/utils.dart';

const jpgSignature = [0xFF, 0xD8];

class JpegFile {
  final List<Segment> segments;
  final Uint8List imageData;

  JpegFile(this.segments, this.imageData);

  factory JpegFile.fromFile(File file) {
    final fileContents = file.readAsBytesSync();
    final fileSignature = fileContents.sublist(0, 2);

    if (!ListEquality().equals(fileSignature, jpgSignature)) {
      throw FormatException("provided does not contain a jpeg header");
    }

    var filePosition = 2;
    final segments = <Segment>[];
    Uint8List? imageData;
    while (filePosition < fileContents.length) {
      final marker = valueFromBytes(Endian.big, fileContents, filePosition, 2);
      filePosition += 2;

      if (marker == 0xFFDA) {
        imageData = fileContents.sublist(filePosition - 2, fileContents.length);
        filePosition = fileContents.length;
        break;
      }

      // - 2 since the length field also includes the size of itself
      final length =
          valueFromBytes(Endian.big, fileContents, filePosition, 2) - 2;
      filePosition += 2;

      final data = fileContents.sublist(filePosition, filePosition + length);
      filePosition += length;

      final Segment newSegment;

      switch (marker) {
        case 0xFFE1:
          newSegment = ExifSegment(marker, data);
          break;
        // case 0xFFE0:
        // JFIF DATA
        //   break;
        default:
          newSegment = Segment(marker, data);
          break;
      }
      segments.add(newSegment);
      print(newSegment);
    }
    if (imageData == null) {
      throw FormatException("No image data found in jpeg");
    }
    return JpegFile(segments, imageData);
  }

  Uint8List get asBytes {
    final jpegFileBytes = segments
        .map((segment) =>
            unsignedIntToBytes(Endian.big, segment.marker, 2) +
            unsignedIntToBytes(Endian.big, segment.data.length + 2, 2) +
            segment.data)
        .expand((element) => element)
        .toList();

    jpegFileBytes.insertAll(0, jpgSignature);
    jpegFileBytes.insertAll(jpegFileBytes.length, imageData);

    return Uint8List.fromList(jpegFileBytes);
  }
}
