class CategoryModel {
  final String id;
  final String name;
  final String color;
  final String slug;
  final int priority;
  final String? layout;
  final bool? isHorizontal;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.slug,
    required this.priority,
    this.layout,
    this.isHorizontal,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '#000000',
      slug: json['slug'] ?? '',
      priority: json['priority'] ?? 0,
      layout: json['layout'] ?? json['orientation'] ?? json['cardType'],
      isHorizontal: json['isHorizontal'] ?? json['is_horizontal'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'color': color,
      'slug': slug,
      'priority': priority,
      if (layout != null) 'layout': layout,
      if (isHorizontal != null) 'isHorizontal': isHorizontal,
    };
  }
}

