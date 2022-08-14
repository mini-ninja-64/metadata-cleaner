import 'dart:typed_data';

import 'package:crclib/catalog.dart';

int appendBytes(int value, int element) {
  return (value << 8) | element;
}

int sumBytes(Endian endian, Uint8List bytes) {
  switch (endian) {
    case Endian.big:
      return bytes.reduce(appendBytes);
    case Endian.little:
      return bytes.reversed.reduce(appendBytes);
    default:
      throw ArgumentError.value(endian, "Expected big or little endian");
  }
}

int valueFromBytes(Endian endianness, Uint8List bytes, int pos, int length) {
  return sumBytes(endianness, bytes.sublist(pos, pos + length));
}

List<Uint8List> chunkList(Uint8List data, int chunkSize) {
  List<Uint8List> chunkList = [];
  for (var i = 0; i < data.length; i += chunkSize) {
    final Uint8List chunk = data.sublist(i, i + chunkSize);
    chunkList.add(chunk);
  }

  return chunkList;
}

int bytesToSigned(Uint8List byteList, int intWidth, Endian endianness) {
  final byteData = ByteData.view(byteList.buffer);
  switch (intWidth) {
    case 1:
      return byteData.getInt8(0);
    case 2:
      return byteData.getInt16(0, endianness);
    case 4:
      return byteData.getInt32(0, endianness);
    case 8:
      return byteData.getInt64(0, endianness);
    default:
      throw ArgumentError.value(intWidth, "Unexpected integer width");
  }
}

Uint8List unsignedIntToBytes(Endian endianness, int value, int widthInBytes) {
  Uint8List byteList = Uint8List(widthInBytes);
  for (var i = 0; i < widthInBytes; i++) {
    final insertionIndex =
        (endianness == Endian.big) ? widthInBytes - i - 1 : i;
    byteList[insertionIndex] = (value >> i * 8) & 0xFF;
  }

  return byteList;
}

Uint8List padBytes(Uint8List bytes, int paddingByte, int minimumWidth,
    [bool padToTheLeft = true]) {
  if (bytes.lengthInBytes >= minimumWidth) return bytes;

  final paddedBytes = Uint8List(minimumWidth);
  paddedBytes.fillRange(0, minimumWidth, paddingByte);

  if (padToTheLeft) {
    paddedBytes.setRange(
        minimumWidth - bytes.lengthInBytes, minimumWidth, bytes);
  } else {
    paddedBytes.setRange(0, bytes.length, bytes);
  }

  return paddedBytes;
}

Uint8List reverseBytes(Uint8List bytes) {
  return Uint8List.fromList(bytes.reversed.toList());
}

int calculateCrc32(List<int> bytes) {
  final value = Crc32().convert(bytes).toBigInt();
  return value.toInt();
}
