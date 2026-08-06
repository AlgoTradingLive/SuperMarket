class Subcategory {
  final int id;
  final String name;
  final String section;
  final String icon;

  Subcategory({
    required this.id,
    required this.name,
    required this.section,
    required this.icon,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'] ?? '',
      section: json['section'] ?? '',
      icon: json['icon'] ?? '',
    );
  }
}
