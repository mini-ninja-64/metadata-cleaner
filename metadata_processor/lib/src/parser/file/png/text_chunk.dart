import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:metadata_processor/src/parser/file/png/chunk.dart';

abstract class TextualChunk extends Chunk {
  final _latin1Decoder = const Latin1Decoder();
  final _latin1Encoder = const Latin1Encoder();

  late String keyword;
  late String text;

  TextualChunk(super.type, Uint8List chunkBytes) {
    keyword =
        _latin1Decoder.convert(chunkBytes.sublist(0, _nullIndex(chunkBytes)));
  }

  TextualChunk.empty(super.type) {
    keyword = "";
    text = "";
  }

  static int _nullIndex(Uint8List bytes, [int startIndex = 0]) {
    return bytes.indexOf(0x00, startIndex);
  }
}

class TextChunk extends TextualChunk {
  TextChunk(String type, Uint8List chunkBytes) : super(type, chunkBytes) {
    text = _latin1Decoder.convert(
        chunkBytes, TextualChunk._nullIndex(chunkBytes) + 1);
  }
  TextChunk.empty() : super.empty("tEXt");

  @override
  Uint8List get data => Uint8List.fromList(
      [..._latin1Encoder.convert(keyword), 0, ..._latin1Encoder.convert(text)]);
}

enum TextCompressionMethod {
  deflateInflate(0);

  final int compressionByte;
  const TextCompressionMethod(this.compressionByte);

  static TextCompressionMethod fromCompressionByte(int byte) {
    return TextCompressionMethod.values.firstWhere(
        (element) => element.compressionByte == byte,
        orElse: () =>
            throw ArgumentError.value(byte, "unknown text compression method"));
  }
}

class ZtxtChunk extends TextualChunk {
  late TextCompressionMethod compressionMethod;

  ZtxtChunk(String type, Uint8List chunkBytes) : super(type, chunkBytes) {
    final firstNullIndex = TextualChunk._nullIndex(chunkBytes);
    compressionMethod = TextCompressionMethod.fromCompressionByte(
        chunkBytes[firstNullIndex + 1]);

    final textBytes = chunkBytes.sublist(firstNullIndex + 2);
    text = _latin1Decoder.convert(zlib.decode(textBytes));
  }
  ZtxtChunk.empty()
      : compressionMethod = TextCompressionMethod.deflateInflate,
        super.empty("zTXt");

  @override
  Uint8List get data => Uint8List.fromList([
        ..._latin1Encoder.convert(keyword),
        0,
        compressionMethod.compressionByte,
        ...zlib.encode(_latin1Encoder.convert(text))
      ]);
}

class ItxtChunk extends TextualChunk {
  final _utf8Decoder = const Utf8Decoder();
  final _utf8Encoder = const Utf8Encoder();

  late bool compressed;
  late TextCompressionMethod compressionMethod;

  late String languageTag;
  late String translatedKeyword;

  ItxtChunk(String type, Uint8List chunkBytes) : super(type, chunkBytes) {
    final firstNullIndex = TextualChunk._nullIndex(chunkBytes);

    compressed = chunkBytes[firstNullIndex + 1] == 1;
    compressionMethod = TextCompressionMethod.fromCompressionByte(
        chunkBytes[firstNullIndex + 2]);

    final languageTagStart = firstNullIndex + 3;
    final languageTagSeperator =
        TextualChunk._nullIndex(chunkBytes, languageTagStart);
    languageTag = ascii
        .decode(chunkBytes.sublist(languageTagStart, languageTagSeperator));

    final translatedKeywordStart = languageTagSeperator + 1;
    final translatedKeywordSeperator =
        TextualChunk._nullIndex(chunkBytes, translatedKeywordStart);
    translatedKeyword = _utf8Decoder.convert(
        chunkBytes.sublist(translatedKeywordStart, translatedKeywordSeperator));

    final textBytesStart = translatedKeywordSeperator + 1;
    final textBytes = chunkBytes.sublist(textBytesStart);

    if (compressed) {
      switch (compressionMethod) {
        case TextCompressionMethod.deflateInflate:
          text = _utf8Decoder.convert(zlib.decode(textBytes));
          break;
      }
    } else {
      text = _utf8Decoder.convert(textBytes);
    }
  }
  ItxtChunk.empty()
      : compressed = false,
        compressionMethod = TextCompressionMethod.deflateInflate,
        languageTag = "",
        translatedKeyword = "",
        super.empty("iTXt");

  @override
  Uint8List get data {
    final utf8Text = _utf8Encoder.convert(text);
    Uint8List textBytes;
    if (compressed) {
      textBytes = Uint8List.fromList(zlib.encode(utf8Text));
    } else {
      textBytes = utf8Text;
    }
    return Uint8List.fromList([
      ..._latin1Encoder.convert(keyword),
      0,
      (compressed ? 1 : 0),
      compressionMethod.compressionByte,
      ...ascii.encode(languageTag),
      0,
      ..._utf8Encoder.convert(translatedKeyword),
      0,
      ...textBytes
    ]);
  }
}
