import 'package:xml/xml.dart';

class XmpData {
  final XmlDocument _xmlDocument;

  XmpData(String xmlDoc) : _xmlDocument = XmlDocument.parse(xmlDoc);

  void deleteField(int index) {
    final nodeToDelete = xmlElements[index];
    nodeToDelete.parentElement?.children.remove(nodeToDelete);
  }

// TODO: this not good, as maps do not guarantee order but we are deleting based on the index
  Map<String, String> get fields {
    return {
      for (var element in xmlElements) element.qualifiedName: element.innerText,
    };
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
