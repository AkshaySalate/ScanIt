import 'package:hive/hive.dart';

part 'folder.g.dart';

@HiveType(typeId: 0)
class Folder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  final List<String> images;

  @HiveField(3)
  Map<String, List<String>> imageTags; // NEW: key=image path, value=list of tags

  Folder({
    required this.id,
    required this.name,
    List<String>? images,
    Map<String, List<String>>? imageTags,
  })  : images = images ?? [],
        imageTags = imageTags ?? {};
}

