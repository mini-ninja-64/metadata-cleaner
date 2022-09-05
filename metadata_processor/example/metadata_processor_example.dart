import 'dart:io';

import 'package:metadata_processor/metadata_processor.dart';
import 'package:metadata_processor/src/metadata/jpeg_metadata.dart';

void main() {
  final jpegFile = File(
      "/home/mini/Development/git-clones/image-parsing-experiment/dart-image-parser/test-files/metadata.jpg");

  final jpeg = JpegFile.fromFile(jpegFile);
  final metadata = JpegMetadata(jpeg);

  print(metadata.allTags);
}
