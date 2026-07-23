class OtpData {
  final String mobileNo;
  final String otpType;
  final DateTime expiryTime;
  final String? otp;

  const OtpData({
    required this.mobileNo,
    required this.otpType,
    required this.expiryTime,
    this.otp,
  });

  factory OtpData.fromJson(Map<String, dynamic> json) {
    return OtpData(
      mobileNo: json['mobileNo'] as String,
      otpType: json['otpType'] as String,
      expiryTime: DateTime.parse(json['expiryTime'] as String),
      otp: json['otp'] as String?,
    );
  }
}
