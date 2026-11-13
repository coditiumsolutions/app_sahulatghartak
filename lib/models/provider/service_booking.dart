class ServiceBooking {
  final int uid;
  final int requestUid;
  final String requestTitle;
  final String? preferredServiceDate;
  final String? preferredServiceTime;
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
  final String? rejectReason;
  final String? cancelReason;
  final String? passcode;
  final DateTime? acceptedOn;
  final DateTime? completedOn;
  final DateTime createdOn;
  final String? providerMobileNo;
  final String? providerProfilePhotoPath;
  final String? providerCnic;
  final String? clientMobileNo;

  /// The request's on-site contact (api.txt v3.45). Free text from the request
  /// form / admin portal, NOT the account holder. Null while Pending or blank.
  final String? contactPerson;
  final String? contactNo;
  final String? clientAddressTitle;
  final String? clientFullAddress;
  final String? clientArea;
  final String? clientCity;

  /// Client's saved address pin, when they dropped one — nullable, and
  /// always both-or-neither (added api.txt v3.23, same both-or-neither
  /// convention as `/client-addresses`). Both null means the client never
  /// dropped a pin for that address, so the map icon simply doesn't show.
  final double? clientLatitude;
  final double? clientLongitude;

  const ServiceBooking({
    required this.uid,
    required this.requestUid,
    required this.requestTitle,
    this.preferredServiceDate,
    this.preferredServiceTime,
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
    this.rejectReason,
    this.cancelReason,
    this.passcode,
    this.acceptedOn,
    this.completedOn,
    required this.createdOn,
    this.providerMobileNo,
    this.providerProfilePhotoPath,
    this.providerCnic,
    this.clientMobileNo,
    this.contactPerson,
    this.contactNo,
    this.clientAddressTitle,
    this.clientFullAddress,
    this.clientArea,
    this.clientCity,
    this.clientLatitude,
    this.clientLongitude,
  });

  static String? _nonBlank(String? v) =>
      (v == null || v.trim().isEmpty) ? null : v.trim();

  /// Who the provider should ask for on site: the request's on-site contact,
  /// falling back to the account holder for older bookings.
  String get onsiteName => _nonBlank(contactPerson) ?? clientName;

  /// Number to call / WhatsApp: the on-site contact's, else the account
  /// holder's. Null until the booking is accepted.
  String? get onsiteMobile => _nonBlank(contactNo) ?? clientMobileNo;

  /// True when the on-site contact is a different person from the account
  /// holder (e.g. an admin booked on someone's behalf).
  bool get hasDistinctOnsiteContact =>
      _nonBlank(contactPerson) != null &&
      _nonBlank(contactPerson) != clientName.trim();

  /// True when the client dropped a pin for this address, so the map icon
  /// can be shown. Both fields are always null-together (see api.txt).
  bool get hasClientLocation =>
      clientLatitude != null && clientLongitude != null;

  /// True for the "Rejected" status. The backend never returns rejected
  /// bookings from GET /service-bookings (staff-only), so these only exist
  /// via the /respond endpoint's response and are persisted locally — see
  /// [RejectedBookingsStore].
  bool get isRejected => status == 'Rejected';

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'requestUid': requestUid,
      'requestTitle': requestTitle,
      'preferredServiceDate': preferredServiceDate,
      'preferredServiceTime': preferredServiceTime,
      'clientUid': clientUid,
      'clientName': clientName,
      'providerUid': providerUid,
      'providerName': providerName,
      'serviceDetail': serviceDetail,
      'estimatedAmount': estimatedAmount,
      'visitCharges': visitCharges,
      'additionalCharges': additionalCharges,
      'deductions': deductions,
      'finalAmount': finalAmount,
      'customerPaid': customerPaid,
      'paymentMode': paymentMode,
      'customerRemaining': customerRemaining,
      'commissionType': commissionType,
      'commissionValue': commissionValue,
      'commissionAmount': commissionAmount,
      'providerEarning': providerEarning,
      'status': status,
      'rejectReason': rejectReason,
      'cancelReason': cancelReason,
      'passcode': passcode,
      'acceptedOn': acceptedOn?.toIso8601String(),
      'completedOn': completedOn?.toIso8601String(),
      'createdOn': createdOn.toIso8601String(),
      'providerMobileNo': providerMobileNo,
      'providerProfilePhotoPath': providerProfilePhotoPath,
      'providerCnic': providerCnic,
      'clientMobileNo': clientMobileNo,
      'contactPerson': contactPerson,
      'contactNo': contactNo,
      'clientAddressTitle': clientAddressTitle,
      'clientFullAddress': clientFullAddress,
      'clientArea': clientArea,
      'clientCity': clientCity,
      'clientLatitude': clientLatitude,
      'clientLongitude': clientLongitude,
    };
  }

  factory ServiceBooking.fromJson(Map<String, dynamic> json) {
    return ServiceBooking(
      uid: json['uid'] as int,
      requestUid: json['requestUid'] as int,
      requestTitle: json['requestTitle'] as String? ?? '',
      preferredServiceDate: json['preferredServiceDate'] as String?,
      preferredServiceTime: json['preferredServiceTime'] as String?,
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
      rejectReason: json['rejectReason'] as String?,
      cancelReason: json['cancelReason'] as String?,
      passcode: json['passcode'] as String?,
      acceptedOn: json['acceptedOn'] != null
          ? DateTime.parse(json['acceptedOn'] as String)
          : null,
      completedOn: json['completedOn'] != null
          ? DateTime.parse(json['completedOn'] as String)
          : null,
      createdOn: json['createdOn'] != null
          ? DateTime.parse(json['createdOn'] as String)
          : DateTime.now(),
      providerMobileNo: json['providerMobileNo'] as String?,
      providerProfilePhotoPath: json['providerProfilePhotoPath'] as String?,
      providerCnic: json['providerCnic'] as String?,
      clientMobileNo: json['clientMobileNo'] as String?,
      contactPerson: json['contactPerson'] as String?,
      contactNo: json['contactNo'] as String?,
      clientAddressTitle: json['clientAddressTitle'] as String?,
      clientFullAddress: json['clientFullAddress'] as String?,
      clientArea: json['clientArea'] as String?,
      clientCity: json['clientCity'] as String?,
      clientLatitude: (json['clientLatitude'] as num?)?.toDouble(),
      clientLongitude: (json['clientLongitude'] as num?)?.toDouble(),
    );
  }
}
