import 'package:flutter/material.dart';

/// Step labels for a customer's [CustomerServiceRequest] journey. These are
/// the exact literal values the API's computed `progressStatus` field uses
/// (see docs/status-workflow.md) — not derived from [CustomerServiceRequest.status],
/// which stays coarse (Pending/Assigned/Completed/Cancelled) on the backend.
const List<String> kRequestStatusSteps = ['Requested', 'Assigned', 'In Progress', 'Completed'];

/// Maps a [CustomerServiceRequest.progressStatus] value to its index in
/// [kRequestStatusSteps]. Null/unrecognized values resolve to step 0 — call
/// [isRequestCancelled] first to distinguish "not started" from "cancelled".
int requestProgressStep(String? progressStatus) {
  final index = kRequestStatusSteps.indexOf(progressStatus ?? '');
  return index < 0 ? 0 : index;
}

/// `progressStatus` is null exactly when the request or its linked booking
/// is Cancelled (the API omits the stage entirely rather than modeling
/// Cancelled as a step) — see docs/status-workflow.md.
bool isRequestCancelled(String? progressStatus) => progressStatus == null;

/// Step labels for a provider's [ServiceBooking] journey.
const List<String> kBookingStatusSteps = ['Requested', 'Accepted', 'In Progress', 'Completed'];

/// Maps a [ServiceBooking.status] string to its index in
/// [kBookingStatusSteps]. Unrecognized/initial statuses (e.g. "Pending")
/// resolve to step 0.
int bookingStatusStep(String status) {
  switch (status) {
    case 'Accepted':
      return 1;
    case 'In Progress':
      return 2;
    case 'Completed':
    case 'Closed':
      return 3;
    default:
      return 0;
  }
}

/// True when [status] is a terminal state (Cancelled/Rejected) that doesn't
/// fit the forward progression in [kBookingStatusSteps].
bool isBookingStatusTerminal(String status) => status == 'Cancelled' || status == 'Rejected';

const Color kBrandActiveColor = Color(0xFF016EE3);
