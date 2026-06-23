class Booking {
  int? id;
  final String customerName;
  final String mobile;
  final String address;
  final String city;
  final String serviceName;
  final String serviceDate;
  final String serviceTime;
  final String notes;

  Booking({
    this.id,
    required this.customerName,
    required this.mobile,
    required this.address,
    required this.city,
    required this.serviceName,
    required this.serviceDate,
    required this.serviceTime,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerName': customerName,
      'mobile': mobile,
      'address': address,
      'city': city,
      'serviceName': serviceName,
      'serviceDate': serviceDate,
      'serviceTime': serviceTime,
      'notes': notes,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as int?,
      customerName: map['customerName'] ?? '',
      mobile: map['mobile'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      serviceName: map['serviceName'] ?? '',
      serviceDate: map['serviceDate'] ?? '',
      serviceTime: map['serviceTime'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
