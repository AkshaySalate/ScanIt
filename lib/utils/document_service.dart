import 'package:hive/hive.dart';
import 'package:scanit/models/document.dart';

class DocumentService {
  final Box<Document> _docBox = Hive.box<Document>('documents');

  Future<void> addDocument(Document doc) async {
    await _docBox.put(doc.id, doc);
  }

  Future<void> updateDocument(Document doc) async {
    await doc.save();
  }

  Future<void> deleteDocument(String id) async {
    await _docBox.delete(id);
  }

  List<Document> getDocumentsByFolder(String folderId) {
    return _docBox.values
        .where((doc) => doc.folderId == folderId)
        .toList();
  }

  List<Document> searchDocuments(String query) {
    final q = query.toLowerCase();
    return _docBox.values.where((doc) =>
    doc.title.toLowerCase().contains(q) ||
        doc.tags.any((tag) => tag.toLowerCase().contains(q)) ||
        (doc.ocrText?.toLowerCase().contains(q) ?? false)
    ).toList();
  }
}
