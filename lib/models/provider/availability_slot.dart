import 'package:flutter/material.dart';

class AvailabilitySlot {
  final String id;
  final String day;
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  const AvailabilitySlot({
    required this.id,
    required this.day,
    required this.startTime,
    required this.endTime,
  });

  AvailabilitySlot copyWith({TimeOfDay? startTime, TimeOfDay? endTime}) {
    return AvailabilitySlot(
      id: id,
      day: day,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }
}
