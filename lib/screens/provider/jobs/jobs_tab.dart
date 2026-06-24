import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/job.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/provider/status_chip.dart';

class JobsTab extends StatelessWidget {
  const JobsTab({Key? key}) : super(key: key);

  Color _statusColor(JobStatus status) {
    switch (status) {
      case JobStatus.accepted:
        return Colors.blueGrey;
      case JobStatus.onTheWay:
        return Colors.orange;
      case JobStatus.started:
        return kAccentColor;
      case JobStatus.completed:
        return Colors.green;
    }
  }

  String _actionLabel(JobStatus status) {
    switch (status) {
      case JobStatus.accepted:
        return 'Mark On The Way';
      case JobStatus.onTheWay:
        return 'Start Job';
      case JobStatus.started:
        return 'Complete Job';
      case JobStatus.completed:
        return 'Done';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final jobs = dashboard.activeJobs;

    if (jobs.isEmpty) {
      return const Center(child: Text('No active jobs.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(job.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(job.serviceType, style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    StatusChip(label: job.status.label, color: _statusColor(job.status)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(job.address, style: TextStyle(color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                    Text('${job.distanceKm} km', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Rs ${job.bookingAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.navigation, size: 18),
                        label: const Text('Navigate'),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening navigation...'))),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Calling customer...'))),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => dashboard.advanceJobStatus(job.id),
                    child: Text(_actionLabel(job.status)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
