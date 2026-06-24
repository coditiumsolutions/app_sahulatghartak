enum JobStatus { accepted, onTheWay, started, completed }

extension JobStatusX on JobStatus {
  String get label {
    switch (this) {
      case JobStatus.accepted:
        return 'Accepted';
      case JobStatus.onTheWay:
        return 'On The Way';
      case JobStatus.started:
        return 'Started';
      case JobStatus.completed:
        return 'Completed';
    }
  }

  JobStatus? get next {
    switch (this) {
      case JobStatus.accepted:
        return JobStatus.onTheWay;
      case JobStatus.onTheWay:
        return JobStatus.started;
      case JobStatus.started:
        return JobStatus.completed;
      case JobStatus.completed:
        return null;
    }
  }
}

class Job {
  final String id;
  final String customerName;
  final String serviceType;
  final String address;
  final double distanceKm;
  final double bookingAmount;
  final JobStatus status;
  final DateTime date;
  final double? rating;

  const Job({
    required this.id,
    required this.customerName,
    required this.serviceType,
    required this.address,
    required this.distanceKm,
    required this.bookingAmount,
    required this.status,
    required this.date,
    this.rating,
  });

  Job copyWith({JobStatus? status}) {
    return Job(
      id: id,
      customerName: customerName,
      serviceType: serviceType,
      address: address,
      distanceKm: distanceKm,
      bookingAmount: bookingAmount,
      status: status ?? this.status,
      date: date,
      rating: rating,
    );
  }
}
