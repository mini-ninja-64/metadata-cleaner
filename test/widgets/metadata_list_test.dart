import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metadata_cleaner/widgets/metadata_list.dart';
import 'package:metadata_processor/metadata_processor.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FileMetadata])
import 'metadata_list_test.mocks.dart';

void main() {
  var mockMetadata = MockFileMetadata();
  const mockTags = [
    ImmutableMetadataTag("mock tag 1", "tag content 1"),
    ImmutableMetadataTag("mock tag 2", "tag content 2"),
    ImmutableMetadataTag("mock tag 3", "tag content 3"),
    ImmutableMetadataTag("mock tag 4", "tag content 4"),
    ImmutableMetadataTag("mock tag 5", "tag content 5"),
    ImmutableMetadataTag("mock tag 6", "tag content 6")
  ];

  testWidgets('Metadata list renders all tags in metadata',
      (WidgetTester tester) async {
    // given
    when(mockMetadata.allTags).thenReturn(mockTags);

    // when
    await tester.pumpWidget(MaterialApp(
        home: Material(child: MetadataList(metadata: mockMetadata))));

    // then
    for (final tag in mockTags) {
      expect(find.text(tag.name), findsOneWidget);
      expect(find.text(tag.content), findsOneWidget);
    }
  });

  testWidgets('Metadata list re renders when a widget is deleted',
      (WidgetTester tester) async {
    // given
    when(mockMetadata.allTags).thenReturn(mockTags);

    // when
    await tester.pumpWidget(MaterialApp(
        home: Material(child: MetadataList(metadata: mockMetadata))));

    // then
    expect(find.text(mockTags.first.name), findsOneWidget);
    expect(find.text(mockTags.first.content), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_rounded).first);
    when(mockMetadata.allTags).thenReturn(mockTags.sublist(1));
    await tester.pump();

    expect(find.text(mockTags.first.name), findsNothing);
    expect(find.text(mockTags.first.content), findsNothing);
  });
}
