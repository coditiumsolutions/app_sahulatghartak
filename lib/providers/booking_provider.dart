import 'package:flutter/material.dart';
import '../models/booking.dart';
import '../database/db_helper.dart';

class BookingProvider extends ChangeNotifier {
  final DBHelper _db = DBHelper();
  List<Booking> _bookings = [];

  BookingProvider() {
    loadBookings();
  }

  List<Booking> get bookings => List.unmodifiable(_bookings);

  Future<void> loadBookings() async {
    _bookings = await _db.getBookings();
    notifyListeners();
  }

  Future<void> addBooking(Booking booking) async {
    final id = await _db.insertBooking(booking);
    booking.id = id;
    _bookings.insert(0, booking);
    notifyListeners();
  }
}
