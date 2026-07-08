class ProviderDetailModel {
  final int uid;
  final int userUid;
  final String mobileNo;
  final String fullName;
  final String cnic;
  final String gender;
  final int experienceYears;
  final String description;
  final bool isVerified;
  final double averageRating;
  final int totalReviews;
  final int totalJobsCompleted;
  final bool isAvailable;
  final String? availableTiming;
  final int categoryId;
  final String categoryName;
  final DateTime createdOn;

  const ProviderDetailModel({
    required this.uid,
    required this.userUid,
    required this.mobileNo,
    required this.fullName,
    required this.cnic,
    required this.gender,
    required this.experienceYears,
    required this.description,
    required this.isVerified,
    required this.averageRating,
    required this.totalReviews,
    required this.totalJobsCompleted,
    required this.isAvailable,
    this.availableTiming,
    required this.categoryId,
    required this.categoryName,
    required this.createdOn,
  });

  factory ProviderDetailModel.fromJson(Map<String, dynamic> json) {
    return ProviderDetailModel(
      uid: json['uid'] as int,
      userUid: json['userUid'] as int,
      mobileNo: json['mobileNo'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      cnic: json['cnic'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      experienceYears: json['experienceYears'] as int? ?? 0,
      description: json['description'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalJobsCompleted: json['totalJobsCompleted'] as int? ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? false,
      availableTiming: json['availableTiming'] as String?,
      categoryId: json['categoryId'] as int? ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
      createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn'] as String) : DateTime.now(),
    );
  }

  ProviderDetailModel copyWith({
    String? fullName,
    String? cnic,
    String? gender,
    int? experienceYears,
    String? description,
  }) {
    return ProviderDetailModel(
      uid: uid,
      userUid: userUid,
      mobileNo: mobileNo,
      fullName: fullName ?? this.fullName,
      cnic: cnic ?? this.cnic,
      gender: gender ?? this.gender,
      experienceYears: experienceYears ?? this.experienceYears,
      description: description ?? this.description,
      isVerified: isVerified,
      averageRating: averageRating,
      totalReviews: totalReviews,
      totalJobsCompleted: totalJobsCompleted,
      isAvailable: isAvailable,
      availableTiming: availableTiming,
      categoryId: categoryId,
      categoryName: categoryName,
      createdOn: createdOn,
    );
  }
}
