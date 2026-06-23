import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/service.dart';
import '../providers/service_provider.dart';
import 'booking_screen.dart';

class ServiceDetailScreen extends StatelessWidget {
  static const routeName = '/service-detail';
  const ServiceDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as int?;
    final service = context.read<ServiceProvider>().services.firstWhere((s) => s.id == args);

    return Scaffold(
      appBar: AppBar(title: Text(service.name), backgroundColor: Colors.yellow),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 200, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey.shade200), child: Center(child: Icon(service.iconData, size: 80, color: Theme.of(context).primaryColor))),
          const SizedBox(height: 16),
          Text(service.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(service.description),
          const SizedBox(height: 12),
          Text('Starting Price: PKR ${service.startingPrice.toStringAsFixed(0)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.green)),
          const SizedBox(height: 12),
          Text('Benefits', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const ListTile(leading: Icon(Icons.check), title: Text('Experienced Professionals')),
          const ListTile(leading: Icon(Icons.check), title: Text('Quality Assured')),
          const ListTile(leading: Icon(Icons.check), title: Text('On-time Service')),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.of(context).pushNamed(BookingScreen.routeName, arguments: service), child: const Text('Book Now'))),
        ]),
      ),
    );
  }
}
