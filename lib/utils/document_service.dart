import 'package:hive/hive.dart';
import 'package:scanit/models/document.dart';

class DocumentService {
  final Box<Document> _docBox = Hive.box<Document>('documents');

  Future<void> addDocument(Document doc) => _docBox.put(doc.id, doc);

  Future<void> updateDocument(Document doc) => doc.save();

  Future<void> deleteDocument(String id) => _docBox.delete(id);

  List<Document> getDocumentsByFolder(String folderId) {
    final docs = _docBox.values.where((doc) => doc.folderId == folderId).toList();
    docs.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return docs;
  }

  List<Document> searchDocuments(String query, {String? folderId}) {
    final q = query.trim().toLowerCase();
    Iterable<Document> docs = _docBox.values;
    if (folderId != null) docs = docs.where((doc) => doc.folderId == folderId);

    return docs.where((doc) =>
    doc.title.toLowerCase().contains(q) ||
        doc.tags.any((tag) => tag.toLowerCase().contains(q)) ||
        (doc.ocrText?.toLowerCase().contains(q) ?? false)
    ).toList();
  }
}
