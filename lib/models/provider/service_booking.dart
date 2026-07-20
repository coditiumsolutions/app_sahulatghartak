class ServiceBooking {
  final int uid;
  final int requestUid;
  final String requestTitle;
  final int clientUid;
  final String clientName;
  final int providerUid;
  final String providerName;
  final String serviceDetail;
  final double estimatedAmount;
  final double visitCharges;
  final double additionalCharges;
  final double deductions;
  final double finalAmount;
  final double customerPaid;
  final String paymentMode;
  final double customerRemaining;
  final String commissionType;
  final double commissionValue;
  final double commissionAmount;
  final double providerEarning;
  final String status;
  final DateTime createdOn;

  const ServiceBooking({
    required this.uid,
    required this.requestUid,
    required this.requestTitle,
    required this.clientUid,
    required this.clientName,
    required this.providerUid,
    required this.providerName,
    required this.serviceDetail,
    required this.estimatedAmount,
    required this.visitCharges,
    required this.additionalCharges,
    required this.deductions,
    required this.finalAmount,
    required this.customerPaid,
    required this.paymentMode,
    required this.customerRemaining,
    required this.commissionType,
    required this.commissionValue,
    required this.commissionAmount,
    required this.providerEarning,
    required this.status,
    required this.createdOn,
  });

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    return ServiceBooking(
      uid: json['uid'] as int,
      requestUid: json['requestUid'] as int,
      requestTitle: json['requestTitle'] as String? ?? '',
      clientUid: json['clientUid'] as int,
      clientName: json['clientName'] as String? ?? '',
      providerUid: json['providerUid'] as int,
      providerName: json['providerName'] as String? ?? '',
      serviceDetail: json['serviceDetail'] as String? ?? '',
      estimatedAmount: (json['estimatedAmount'] as num?)?.toDouble() ?? 0,
      visitCharges: (json['visitCharges'] as num?)?.toDouble() ?? 0,
      additionalCharges: (json['additionalCharges'] as num?)?.toDouble() ?? 0,
      deductions: (json['deductions'] as num?)?.toDouble() ?? 0,
      finalAmount: (json['finalAmount'] as num?)?.toDouble() ?? 0,
      customerPaid: (json['customerPaid'] as num?)?.toDouble() ?? 0,
      paymentMode: json['paymentMode'] as String? ?? 'CashToProvider',
      customerRemaining: (json['customerRemaining'] as num?)?.toDouble() ?? 0,
      commissionType: json['commissionType'] as String? ?? 'Percent',
      commissionValue: (json['commissionValue'] as num?)?.toDouble() ?? 0,
      commissionAmount: (json['commissionAmount'] as num?)?.toDouble() ?? 0,
      providerEarning: (json['providerEarning'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'Pending',
      createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn'] as String) : DateTime.now(),
    );
  }
}
