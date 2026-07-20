class CategoryModel {
  final String id;
  final String name;
  final String color;
  final String slug;
  final int priority;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.slug,
    required this.priority,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#000000',
      slug: json['slug'] ?? '',
      priority: json['priority'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'color': color,
      'slug': slug,
      'priority': priority,
    };
  }
}
