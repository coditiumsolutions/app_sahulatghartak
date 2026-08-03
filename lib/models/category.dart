class Category {
  final int id;
  final int serviceId;
  final String serviceName;
  final String name;
  final String? description;
  final DateTime createdOn;

  const Category({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.name,
    required this.description,
    required this.createdOn,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      serviceId: json['serviceId'] as int,
      serviceName: json['serviceName'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdOn: DateTime.parse(json['createdOn'] as String),
    );
  }
}
