class Folder {
  final String id;
  final String name;
  final List<String> images;

  Folder({
    required this.id,
    required this.name,
    List<String>? images,
  }) : images = images ?? [];
}
