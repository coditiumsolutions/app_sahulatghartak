class ServiceProviderModel {
  final int id;
  final String fullName;
  final String mobileNo;
  final int categoryId;
  final String categoryName;
  final int experienceYears;
  final double rating;
  final bool isVerified;
  final String? profileImageUrl;
  final DateTime createdOn;

  const ServiceProviderModel({
    required this.id,
    required this.fullName,
    required this.mobileNo,
    required this.categoryId,
    required this.categoryName,
    required this.experienceYears,
    required this.rating,
    required this.isVerified,
    this.profileImageUrl,
    required this.createdOn,
  });

  factory ServiceProviderModel.fromJson(Map<String, dynamic> json) {
    return ServiceProviderModel(
      id: json['id'] as int,
      fullName: json['fullName'] as String,
      mobileNo: json['mobileNo'] as String,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      experienceYears: json['experienceYears'] as int,
      rating: (json['rating'] as num).toDouble(),
      isVerified: json['isVerified'] as bool,
      profileImageUrl: json['profileImageUrl'] as String?,
      createdOn: DateTime.parse(json['createdOn'] as String),
    );
  }
}
