class ProviderDocumentsModel {
  final int providerUid;
  final String? profilePhotoPath;
  final String? cnicFrontImagePath;
  final String? cnicBackImagePath;
  final bool isVerified;
  final DateTime? verifiedOn;
  final int? verifiedBy;
  final String? verificationRemarks;
  final DateTime? createdOn;
  final DateTime? updatedOn;

  const ProviderDocumentsModel({
    required this.providerUid,
    this.profilePhotoPath,
    this.cnicFrontImagePath,
    this.cnicBackImagePath,
    required this.isVerified,
    this.verifiedOn,
    this.verifiedBy,
    this.verificationRemarks,
    this.createdOn,
    this.updatedOn,
  });

  factory ProviderDocumentsModel.fromJson(Map<String, dynamic> json) {
    return ProviderDocumentsModel(
      providerUid: json['providerUid'] as int,
      profilePhotoPath: json['profilePhotoPath'] as String?,
      cnicFrontImagePath: json['cnicFrontImagePath'] as String?,
      cnicBackImagePath: json['cnicBackImagePath'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      verifiedOn: json['verifiedOn'] != null ? DateTime.parse(json['verifiedOn'] as String) : null,
      verifiedBy: json['verifiedBy'] as int?,
      verificationRemarks: json['verificationRemarks'] as String?,
      createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn'] as String) : null,
      updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn'] as String) : null,
    );
  }
}
