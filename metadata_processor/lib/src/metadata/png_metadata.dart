import 'package:metadata_processor/metadata_processor.dart';
import 'package:metadata_processor/src/parser/file/png/text_chunk.dart';

const xmpPngKeyword = "XML:com.adobe.xmp";

class PngMetadata extends FileMetadata {
  final PngFile file;

  PngMetadata(this.file);

  Iterable<TextualChunk> get _xmpChunks {
    return file.chunks
        .whereType<TextualChunk>()
        .where((textualChunk) => textualChunk.keyword == xmpPngKeyword);
  }

  @override
  List<MetadataTag> get allTags => _xmpChunks
      .map((chunk) => XmpData(chunk.text))
      .expand((xmpData) => xmpData.fields)
      .map((xmpField) => ImmutableMetadataTag(xmpField.name, xmpField.content))
      .toList();

  @override
  void deleteTag(int tagToDelete) {
    int currentIndex = 0;
    for (final chunk in _xmpChunks) {
      final xmpData = XmpData(chunk.text);
      final fields = xmpData.fields;

      for (int fieldIndex = 0; fieldIndex < fields.length; fieldIndex++) {
        if (tagToDelete == currentIndex) {
          xmpData.deleteField(fieldIndex);
          return;
        }
        currentIndex++;
      }
    }
  }
}
