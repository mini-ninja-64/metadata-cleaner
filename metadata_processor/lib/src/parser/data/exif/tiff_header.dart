import 'dart:typed_data';

import 'package:metadata_processor/src/utils.dart';

class TiffHeader {
  final Endian endianness;
  final int signature;

  static const int _bigEndianFlag = 0x4D4D;
  static const int _littleEndianFlag = 0x4949;

  Uint8List toExifBytes(int ifdOffset) {
    Uint8List bytes = Uint8List(8);
    bytes.setRange(
        0,
        2,
        unsignedIntToBytes(Endian.big,
            endianness == Endian.big ? _bigEndianFlag : _littleEndianFlag, 2));
    bytes.setRange(2, 4, unsignedIntToBytes(endianness, signature, 2));
    bytes.setRange(4, 8, unsignedIntToBytes(endianness, ifdOffset, 4));

    return bytes;
  }

  TiffHeader(this.endianness, this.signature);
}
