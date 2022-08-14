import 'dart:typed_data';

import 'package:metadata_processor/src/parser/data/exif/exif_data.dart';

class Segment {
  int marker;
  Uint8List data;

  Segment(this.marker, this.data);

  @override
  String toString() {
    return """Marker: 0x${marker.toRadixString(16)}
data:   ${data.length} bytes
""";
  }
}

class ExifSegment extends Segment {
  ExifSegment(super.marker, super.data);

  ExifData get asExifData {
    return ExifData.fromBytes(data);
  }
}
