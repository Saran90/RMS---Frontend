/// A menu category model.
class MenuCategory {
  const MenuCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
    this.description,
  });

  final String id;
  final String name;
  final int displayOrder;
  final String? description;

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        displayOrder: (json['display_order'] as num?)?.toInt() ?? 0,
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'display_order': displayOrder,
        if (description != null) 'description': description,
      };

  MenuCategory copyWith(
      {String? name, String? description, int? displayOrder}) {
    return MenuCategory(
      id: id,
      name: name ?? this.name,
      displayOrder: displayOrder ?? this.displayOrder,
      description: description ?? this.description,
    );
  }
}
