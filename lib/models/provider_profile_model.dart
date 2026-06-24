class ProviderProfileModel {
  final int uid;
  final int userUid;
  final String fullName;
  final int categoryUid;
  final String cnic;
  final int experienceYears;
  final double rating;
  final bool isVerified;

  const ProviderProfileModel({
    required this.uid,
    required this.userUid,
    required this.fullName,
    required this.categoryUid,
    required this.cnic,
    required this.experienceYears,
    required this.rating,
    required this.isVerified,
  });

  factory ProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return ProviderProfileModel(
      uid: json['uid'] as int,
      userUid: json['userUid'] as int,
      fullName: json['fullName'] as String,
      categoryUid: json['categoryUid'] as int,
      cnic: json['cnic'] as String,
      experienceYears: json['experienceYears'] as int,
      rating: (json['rating'] as num).toDouble(),
      isVerified: json['isVerified'] as bool,
    );
  }

  ProviderProfileModel copyWith({String? fullName, String? cnic, int? experienceYears}) {
    return ProviderProfileModel(
      uid: uid,
      userUid: userUid,
      fullName: fullName ?? this.fullName,
      categoryUid: categoryUid,
      cnic: cnic ?? this.cnic,
      experienceYears: experienceYears ?? this.experienceYears,
      rating: rating,
      isVerified: isVerified,
    );
  }
}
