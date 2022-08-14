import 'dart:convert';
import 'dart:typed_data';

import 'package:metadata_processor/src/utils.dart';

/* PNG CHUNKS: http://www.libpng.org/pub/png/spec/1.2/PNG-Chunks.html
http://www.libpng.org/pub/png/book/chapter11.html#png.ch11.div.3
- IHDR
- PLTE
- IDAT
- IEND
- tRNS
- gAMA
- cHRM
- sRGB
- iCCP
- iTXt
- tEXt
- zTXt
- bKGD
- pHYs
- sBIT
- sPLT
- hIST
- tIME
*/

abstract class Chunk {
  String type;

  Chunk(this.type);

  Uint8List get data;
  int get crc => calculateCrc32([...ascii.encode(type), ...data]);

  Uint8List get asBytes {
    final dataLengthBytes = unsignedIntToBytes(Endian.big, data.length, 4);
    final dataTypeBytes = ascii.encode(type);
    final dataBytes = data;
    final crcBytes = unsignedIntToBytes(Endian.big, crc, 4);

    return Uint8List.fromList(
        [...dataLengthBytes, ...dataTypeBytes, ...dataBytes, ...crcBytes]);
  }
}

class ImmutableChunk extends Chunk {
  @override
  final Uint8List data;
  @override
  final int crc;

  ImmutableChunk(super.type, this.data, this.crc);
}
