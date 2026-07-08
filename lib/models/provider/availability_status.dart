class ProviderAvailabilityStatus {
  final int uid;
  final int providerUid;
  final bool isOnline;
  final String? availableFrom;
  final String? availableTo;
  final String? availableTiming;

  const ProviderAvailabilityStatus({
    required this.uid,
    required this.providerUid,
    required this.isOnline,
    this.availableFrom,
    this.availableTo,
    this.availableTiming,
  });

  factory ProviderAvailabilityStatus.fromJson(Map<String, dynamic> json) {
    return ProviderAvailabilityStatus(
      uid: json['uid'] as int,
      providerUid: json['providerUid'] as int,
      isOnline: json['isOnline'] as bool,
      availableFrom: json['availableFrom'] as String?,
      availableTo: json['availableTo'] as String?,
      availableTiming: json['availableTiming'] as String?,
    );
  }
}
