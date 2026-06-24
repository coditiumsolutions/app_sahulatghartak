import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/availability_slot.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';

const _days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

class AvailabilityScheduleScreen extends StatelessWidget {
  static const routeName = '/provider/schedule';
  const AvailabilityScheduleScreen({Key? key}) : super(key: key);

  Future<void> _editSlot(BuildContext context, {AvailabilitySlot? existing}) async {
    String day = existing?.day ?? _days.first;
    TimeOfDay start = existing?.startTime ?? const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay end = existing?.endTime ?? const TimeOfDay(hour: 18, minute: 0);

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Schedule' : 'Update Schedule'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: day,
                decoration: const InputDecoration(labelText: 'Day'),
                items: _days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                onChanged: (v) => setDialogState(() => day = v ?? day),
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('Start Time'),
                trailing: Text(start.format(dialogContext)),
                onTap: () async {
                  final picked = await showTimePicker(context: dialogContext, initialTime: start);
                  if (picked != null) setDialogState(() => start = picked);
                },
              ),
              ListTile(
                title: const Text('End Time'),
                trailing: Text(end.format(dialogContext)),
                onTap: () async {
                  final picked = await showTimePicker(context: dialogContext, initialTime: end);
                  if (picked != null) setDialogState(() => end = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final dashboard = context.read<ProviderDashboardProvider>();
                if (existing == null) {
                  dashboard.addAvailabilitySlot(AvailabilitySlot(id: 's${DateTime.now().millisecondsSinceEpoch}', day: day, startTime: start, endTime: end));
                } else {
                  dashboard.updateAvailabilitySlot(existing.copyWith(startTime: start, endTime: end));
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final slots = dashboard.availabilitySlots;

    return Scaffold(
      appBar: AppBar(title: const Text('Availability Schedule'), backgroundColor: kPrimaryColor),
      floatingActionButton: FloatingActionButton(onPressed: () => _editSlot(context), backgroundColor: kPrimaryColor, child: const Icon(Icons.add)),
      body: slots.isEmpty
          ? const Center(child: Text('No schedule configured yet.'))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: slots.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final slot = slots[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: kPrimaryColor),
                    title: Text(slot.day, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${slot.startTime.format(context)} - ${slot.endTime.format(context)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editSlot(context, existing: slot)),
                        IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => dashboard.deleteAvailabilitySlot(slot.id)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
