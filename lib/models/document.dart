import 'package:hive/hive.dart';

part 'document.g.dart';

@HiveType(typeId: 1) // Make sure typeId is unique (Folder is 0)
class Document extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String filePath; // Could be image or PDF path

  @HiveField(3)
  String folderId; // Links document to a folder

  @HiveField(4)
  List<String> tags;

  @HiveField(5)
  String? ocrText; // Searchable text after OCR

  @HiveField(6)
  DateTime createdDate;

  Document({
    required this.id,
    required this.title,
    required this.filePath,
    required this.folderId,
    List<String>? tags,
    this.ocrText,
    DateTime? createdDate,
  })  : tags = tags ?? [],
        createdDate = createdDate ?? DateTime.now();
}
