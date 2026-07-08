class CustomerServiceRequest {
  final int uid;
  final int clientUid;
  final String clientName;
  final int categoryUid;
  final String categoryName;
  final int clientAddressUid;
  final String addressTitle;
  final String serviceTitle;
  final String serviceDescription;
  final String preferredServiceDate;
  final String preferredServiceTime;
  final bool isUrgent;
  final String contactPerson;
  final String contactNo;
  final double estimatedBudget;
  final String status;
  final String? remarks;
  final DateTime createdOn;

  const CustomerServiceRequest({
    required this.uid,
    required this.clientUid,
    required this.clientName,
    required this.categoryUid,
    required this.categoryName,
    required this.clientAddressUid,
    required this.addressTitle,
    required this.serviceTitle,
    required this.serviceDescription,
    required this.preferredServiceDate,
    required this.preferredServiceTime,
    required this.isUrgent,
    required this.contactPerson,
    required this.contactNo,
    required this.estimatedBudget,
    required this.status,
    this.remarks,
    required this.createdOn,
  });

  factory CustomerServiceRequest.fromJson(Map<String, dynamic> json) {
    return CustomerServiceRequest(
      uid: json['uid'] as int,
      clientUid: json['clientUid'] as int,
      clientName: json['clientName'] as String? ?? '',
      categoryUid: json['categoryUid'] as int,
      categoryName: json['categoryName'] as String? ?? '',
      clientAddressUid: json['clientAddressUid'] as int,
      addressTitle: json['addressTitle'] as String? ?? '',
      serviceTitle: json['serviceTitle'] as String? ?? '',
      serviceDescription: json['serviceDescription'] as String? ?? '',
      preferredServiceDate: json['preferredServiceDate'] as String? ?? '',
      preferredServiceTime: json['preferredServiceTime'] as String? ?? '',
      isUrgent: json['isUrgent'] as bool? ?? false,
      contactPerson: json['contactPerson'] as String? ?? '',
      contactNo: json['contactNo'] as String? ?? '',
      estimatedBudget: (json['estimatedBudget'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? 'Pending',
      remarks: json['remarks'] as String?,
      createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn'] as String) : DateTime.now(),
    );
  }
}
