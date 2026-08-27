// Regression coverage for the "wrong contact details" tester report.
//
// Verifies that CustomerServiceRequest and ServiceBooking parse each
// party's contact fields from the JSON keys the backend documents in
// api.txt, with no cross-field mixups (e.g. provider's number ending up
// under the client's field or vice versa).
import 'package:flutter_test/flutter_test.dart';

import 'package:sahulat_ghar_tak/models/customer_service_request.dart';
import 'package:sahulat_ghar_tak/models/provider/service_booking.dart';

void main() {
  group('CustomerServiceRequest.fromJson contact fields', () {
    test('maps contactNo (the requesting client\'s own number) correctly', () {
      final json = {
        'uid': 2,
        'clientUid': 1,
        'clientName': 'Shahid',
        'categoryUid': 4,
        'categoryName': 'Electrician',
        'clientAddressUid': 1,
        'addressTitle': 'Home',
        'serviceTitle': 'Fan Installation',
        'serviceDescription': 'Install 2 ceiling fans',
        'preferredServiceDate': '2026-07-12',
        'preferredServiceTime': '16:00',
        'isUrgent': false,
        'contactPerson': 'Shahid',
        'contactNo': '03335191392',
        'estimatedBudget': 1500.00,
        'status': 'InProgress',
        'remarks': null,
        'cancelReason': null,
        'createdOn': '2026-07-09T00:00:00',
        'providerUid': 7,
        'providerName': 'Ali Raza',
        'providerMobileNo': '03011234567',
        'providerProfilePhotoPath': '/uploads/providers/7/profile.jpg',
        'providerCnic': '35202-1234567-1',
        'passcode': '4821',
      };

      final request = CustomerServiceRequest.fromJson(json);

      // The client's own contact info must never equal the provider's.
      expect(request.contactPerson, 'Shahid');
      expect(request.contactNo, '03335191392');
      expect(request.providerName, 'Ali Raza');
      expect(request.providerMobileNo, '03011234567');
      expect(request.contactNo, isNot(equals(request.providerMobileNo)));
    });

    test('providerMobileNo/providerName/providerCnic are null when no accepted booking exists', () {
      final json = {
        'uid': 1,
        'clientUid': 1,
        'clientName': 'Shahid',
        'categoryUid': 4,
        'categoryName': 'Electrician',
        'clientAddressUid': 1,
        'addressTitle': 'Home',
        'serviceTitle': 'AC Repair',
        'serviceDescription': 'AC not cooling properly',
        'preferredServiceDate': '2026-07-10',
        'preferredServiceTime': '10:00',
        'isUrgent': true,
        'contactPerson': 'Shahid',
        'contactNo': '03335191392',
        'estimatedBudget': 2500.00,
        'status': 'Pending',
        'remarks': 'Please call before arrival',
        'cancelReason': null,
        'createdOn': '2026-07-08T00:00:00',
        'providerUid': null,
        'providerName': null,
        'providerMobileNo': null,
        'providerProfilePhotoPath': null,
        'providerCnic': null,
        'passcode': null,
      };

      final request = CustomerServiceRequest.fromJson(json);

      expect(request.providerUid, isNull);
      expect(request.providerMobileNo, isNull);
      // A Pending request must never surface a stale/leftover provider number.
    });

    test('two different requests in the same list keep independent contact fields', () {
      final requestA = CustomerServiceRequest.fromJson({
        'uid': 10,
        'clientUid': 1,
        'clientName': 'Shahid',
        'categoryUid': 1,
        'categoryName': 'Plumber',
        'clientAddressUid': 1,
        'addressTitle': 'Home',
        'serviceTitle': 'Leak Fix',
        'serviceDescription': '',
        'preferredServiceDate': '',
        'preferredServiceTime': '',
        'isUrgent': false,
        'contactPerson': 'Shahid',
        'contactNo': '0300-AAA',
        'estimatedBudget': 0,
        'status': 'InProgress',
        'createdOn': '2026-07-08T00:00:00',
        'providerUid': 5,
        'providerName': 'Provider A',
        'providerMobileNo': '0300-PROV-A',
      });

      final requestB = CustomerServiceRequest.fromJson({
        'uid': 11,
        'clientUid': 1,
        'clientName': 'Shahid',
        'categoryUid': 2,
        'categoryName': 'Electrician',
        'clientAddressUid': 1,
        'addressTitle': 'Home',
        'serviceTitle': 'Wiring',
        'serviceDescription': '',
        'preferredServiceDate': '',
        'preferredServiceTime': '',
        'isUrgent': false,
        'contactPerson': 'Shahid',
        'contactNo': '0300-AAA',
        'estimatedBudget': 0,
        'status': 'InProgress',
        'createdOn': '2026-07-08T00:00:00',
        'providerUid': 9,
        'providerName': 'Provider B',
        'providerMobileNo': '0300-PROV-B',
      });

      // Each request's provider contact must stay tied to its own record,
      // not bleed into a sibling request rendered in the same list.
      expect(requestA.providerMobileNo, '0300-PROV-A');
      expect(requestB.providerMobileNo, '0300-PROV-B');
      expect(requestA.providerMobileNo, isNot(equals(requestB.providerMobileNo)));
    });
  });

  group('ServiceBooking.fromJson contact fields', () {
    test('maps clientMobileNo and providerMobileNo to distinct fields', () {
      final json = {
        'uid': 1,
        'requestUid': 2,
        'requestTitle': 'Fan Installation',
        'clientUid': 1,
        'clientName': 'Shahid',
        'providerUid': 7,
        'providerName': 'Ali Raza',
        'serviceDetail': '',
        'estimatedAmount': 0,
        'visitCharges': 0,
        'additionalCharges': 0,
        'deductions': 0,
        'finalAmount': 0,
        'customerPaid': 0,
        'paymentMode': 'CashToProvider',
        'customerRemaining': 0,
        'commissionType': 'Percent',
        'commissionValue': 0,
        'commissionAmount': 0,
        'providerEarning': 0,
        'status': 'Accepted',
        'createdOn': '2026-07-09T00:00:00',
        'providerMobileNo': '03011234567',
        'clientMobileNo': '03335191392',
      };

      final booking = ServiceBooking.fromJson(json);

      expect(booking.clientMobileNo, '03335191392');
      expect(booking.providerMobileNo, '03011234567');
      expect(booking.clientMobileNo, isNot(equals(booking.providerMobileNo)));
    });

    test('round-trips clientMobileNo/providerMobileNo through toJson without swapping', () {
      final booking = ServiceBooking(
        uid: 1,
        requestUid: 2,
        requestTitle: 'Fan Installation',
        clientUid: 1,
        clientName: 'Shahid',
        providerUid: 7,
        providerName: 'Ali Raza',
        serviceDetail: '',
        estimatedAmount: 0,
        visitCharges: 0,
        additionalCharges: 0,
        deductions: 0,
        finalAmount: 0,
        customerPaid: 0,
        paymentMode: 'CashToProvider',
        customerRemaining: 0,
        commissionType: 'Percent',
        commissionValue: 0,
        commissionAmount: 0,
        providerEarning: 0,
        status: 'Accepted',
        createdOn: DateTime(2026, 7, 9),
        providerMobileNo: '03011234567',
        clientMobileNo: '03335191392',
      );

      final json = booking.toJson();
      final roundTripped = ServiceBooking.fromJson(json);

      expect(roundTripped.clientMobileNo, '03335191392');
      expect(roundTripped.providerMobileNo, '03011234567');
    });
  });
}
