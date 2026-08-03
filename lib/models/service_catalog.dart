/// Parent service catalog entry (backend `Services` table). Not to be
/// confused with the legacy [Service] model in `models/service.dart`, which
/// is a separate, unrelated hardcoded catalog used only by the Featured
/// Services carousel.
class ServiceCatalog {
  final int id;
  final String name;
  final String? description;
  final int displayOrder;
  final DateTime createdOn;

  const ServiceCatalog({
    required this.id,
    required this.name,
    required this.description,
    required this.displayOrder,
    required this.createdOn,
  });

  factory ServiceCatalog.fromJson(Map<String, dynamic> json) {
    return ServiceCatalog(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      displayOrder: json['displayOrder'] as int,
      createdOn: DateTime.parse(json['createdOn'] as String),
    );
  }
}
