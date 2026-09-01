class ClientDetailModel {
  final int uid;
  final int userUid;
  final String mobileNo;
  final String fullName;
  final String cnic;
  final String gender;

  const ClientDetailModel({
    required this.uid,
    required this.userUid,
    required this.mobileNo,
    required this.fullName,
    required this.cnic,
    required this.gender,
  });

  factory ClientDetailModel.fromJson(Map<String, dynamic> json) {
    return ClientDetailModel(
      uid: json['uid'] as int,
      userUid: json['userUid'] as int,
      mobileNo: json['mobileNo'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      cnic: json['cnic'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
    );
  }
}
