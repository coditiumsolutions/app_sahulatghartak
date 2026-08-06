class ServiceTitle {
  final int id;
  final int categoryId;
  final String categoryName;
  final String title;
  final String? description;
  final DateTime createdOn;

  const ServiceTitle({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.title,
    required this.description,
    required this.createdOn,
  });

  factory ServiceTitle.fromJson(Map<String, dynamic> json) {
    return ServiceTitle(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdOn: DateTime.parse(json['createdOn'] as String),
    );
  }
}
