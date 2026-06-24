class ServiceRequest {
  final int id;
  final int categoryId;
  final String categoryName;
  final int customerId;
  final String customerName;
  final String customerMobile;
  final String requestTitle;
  final String description;
  final String serviceAddress;
  final double latitude;
  final double longitude;
  final DateTime requestDate;
  final String status;

  const ServiceRequest({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.requestTitle,
    required this.description,
    required this.serviceAddress,
    required this.latitude,
    required this.longitude,
    required this.requestDate,
    required this.status,
  });

  factory ServiceRequest.fromJson(Map<String, dynamic> json) {
    return ServiceRequest(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      customerId: json['customerId'] as int,
      customerName: json['customerName'] as String,
      customerMobile: json['customerMobile'] as String,
      requestTitle: json['requestTitle'] as String,
      description: json['description'] as String,
      serviceAddress: json['serviceAddress'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      requestDate: DateTime.parse(json['requestDate'] as String),
      status: json['status'] as String,
    );
  }
}
