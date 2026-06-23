import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/booking_provider.dart';

class BookingsListScreen extends StatelessWidget {
  static const routeName = '/bookings';
  const BookingsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bookings = context.watch<BookingProvider>().bookings;
    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings'), backgroundColor: Colors.yellow),
      body: bookings.isEmpty
          ? const Center(child: Text('No bookings yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: bookings.length,
              itemBuilder: (context, idx) {
                final b = bookings[idx];
                return Card(
                  child: ListTile(
                    title: Text(b.serviceName),
                    subtitle: Text('${b.customerName} • ${b.city}'),
                    trailing: Text('${b.serviceTime}\n${DateTime.parse(b.serviceDate).toLocal().toString().split(' ').first}'),
                  ),
                );
              },
            ),
    );
  }
}
