import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:metadata_processor/src/parser/file/png/chunk.dart';
import 'package:metadata_processor/src/parser/file/png/text_chunk.dart';
import 'package:metadata_processor/src/utils.dart';

const pngSignature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];

class PngFile {
  final List<Chunk> chunks;

  Uint8List get bytes {
    final chunkBytes = chunks.map((chunk) => chunk.asBytes);
    final pngBytes = chunkBytes.expand((element) => element);
    return Uint8List.fromList([...pngSignature, ...pngBytes.toList()]);
  }

  factory PngFile.fromFile(File file) {
    final fileContents = file.readAsBytesSync();
    final fileSignature = fileContents.sublist(0, 8);

    if (!ListEquality().equals(fileSignature, pngSignature)) {
      throw FormatException("provided does not contain a png header");
    }

    var filePosition = 8;
    final chunks = <Chunk>[];
    while (filePosition < fileContents.length) {
      final length = sumBytes(
          Endian.big, fileContents.sublist(filePosition, filePosition + 4));
      filePosition += 4;

      final type =
          ascii.decode(fileContents.sublist(filePosition, filePosition + 4));
      filePosition += 4;

      final data = fileContents.sublist(filePosition, filePosition + length);
      filePosition += length;

      final crc = sumBytes(
          Endian.big, fileContents.sublist(filePosition, filePosition + 4));
      filePosition += 4;

      final Chunk chunk;
      switch (type) {
        case "iTXt":
          chunk = ItxtChunk(type, data);
          break;
        case "tEXt":
          chunk = TextChunk(type, data);
          break;
        case "zTXt":
          chunk = ZtxtChunk(type, data);
          break;
        default:
          chunk = ImmutableChunk(type, data, crc);
          break;
      }
      print("""Parsing Chunk:
Type:   $type
Data:   $length bytes
CRC:    $crc
CRC calculated: ${chunk.crc}
""");
      chunks.add(chunk);
    }

    return PngFile(chunks);
  }

  PngFile(this.chunks);
}
