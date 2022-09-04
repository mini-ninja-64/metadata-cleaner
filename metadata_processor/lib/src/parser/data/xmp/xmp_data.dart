import 'package:xml/xml.dart';

class XmpField {
  final String name;
  final String content;

  const XmpField(this.name, this.content);
}

class XmpData {
  final XmlDocument _xmlDocument;

  XmpData(String xmpDocument) : _xmlDocument = XmlDocument.parse(xmpDocument);

  void deleteField(int index) {
    final nodeToDelete = xmlElements[index];
    nodeToDelete.parentElement?.children.remove(nodeToDelete);
  }

  List<XmpField> get fields {
    return [
      for (var element in xmlElements) XmpField(element.qualifiedName, element.innerText),
    ];
  }

  List<XmlElement> get xmlElements {
    return _xmlDocument.descendantElements
        .where((element) => element.nodeType == XmlNodeType.ELEMENT)
        .where((element) => element.children
            .every((element) => element.nodeType == XmlNodeType.TEXT))
        .toList();
  }

  @override
  String toString() {
    return _xmlDocument.toString();
  }
}
