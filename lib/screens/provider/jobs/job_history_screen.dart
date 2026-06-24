import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/job.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';

enum _Filter { today, thisWeek, thisMonth, custom }

class JobHistoryScreen extends StatefulWidget {
  static const routeName = '/provider/job-history';
  const JobHistoryScreen({Key? key}) : super(key: key);

  @override
  State<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends State<JobHistoryScreen> {
  _Filter _filter = _Filter.thisMonth;
  DateTimeRange? _customRange;

  List<Job> _applyFilter(List<Job> jobs) {
    final now = DateTime.now();
    switch (_filter) {
      case _Filter.today:
        return jobs.where((j) => j.date.year == now.year && j.date.month == now.month && j.date.day == now.day).toList();
      case _Filter.thisWeek:
        final weekAgo = now.subtract(const Duration(days: 7));
        return jobs.where((j) => j.date.isAfter(weekAgo)).toList();
      case _Filter.thisMonth:
        return jobs.where((j) => j.date.year == now.year && j.date.month == now.month).toList();
      case _Filter.custom:
        if (_customRange == null) return jobs;
        return jobs.where((j) => j.date.isAfter(_customRange!.start.subtract(const Duration(days: 1))) && j.date.isBefore(_customRange!.end.add(const Duration(days: 1)))).toList();
    }
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(context: context, firstDate: now.subtract(const Duration(days: 365)), lastDate: now);
    if (range != null) {
      setState(() {
        _customRange = range;
        _filter = _Filter.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final jobs = _applyFilter(context.watch<ProviderDashboardProvider>().jobHistory);

    return Scaffold(
      appBar: AppBar(title: const Text('Job History'), backgroundColor: kPrimaryColor),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(label: const Text('Today'), selected: _filter == _Filter.today, onSelected: (_) => setState(() => _filter = _Filter.today)),
                ChoiceChip(label: const Text('This Week'), selected: _filter == _Filter.thisWeek, onSelected: (_) => setState(() => _filter = _Filter.thisWeek)),
                ChoiceChip(label: const Text('This Month'), selected: _filter == _Filter.thisMonth, onSelected: (_) => setState(() => _filter = _Filter.thisMonth)),
                ActionChip(avatar: const Icon(Icons.date_range, size: 16), label: const Text('Custom Range'), onPressed: _pickCustomRange),
              ],
            ),
          ),
          Expanded(
            child: jobs.isEmpty
                ? const Center(child: Text('No jobs found for this filter.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final job = jobs[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(job.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${job.serviceType} • ${DateFormat('dd MMM yyyy').format(job.date)}'),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Rs ${job.bookingAmount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (job.rating != null)
                                Row(children: [const Icon(Icons.star, size: 14, color: Colors.amber), Text(job.rating!.toStringAsFixed(1), style: const TextStyle(fontSize: 12))]),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
