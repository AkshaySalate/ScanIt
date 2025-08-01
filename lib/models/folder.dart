import 'package:hive/hive.dart';

part 'folder.g.dart';

@HiveType(typeId: 0)
class Folder extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final List<String> images;

  Folder({
    required this.id,
    required this.name,
    List<String>? images,
  }) : images = images ?? [];
}
