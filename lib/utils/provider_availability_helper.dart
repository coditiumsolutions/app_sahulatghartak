import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/provider_dashboard_provider.dart';

String _formatTime(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

TimeOfDay? _parseTime(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

/// Prompts for the available-from/to timing when going online. Timing is
/// optional from the provider's point of view: "Skip" proceeds with the
/// previously saved timing (or a sensible default), "Save" uses whatever
/// is currently picked. Returns a two-item [from, to] list, or null if the
/// dialog was dismissed without a choice.
Future<List<String>?> _promptAvailabilityTiming(BuildContext context, ProviderDashboardProvider dashboard) async {
  TimeOfDay start = _parseTime(dashboard.availableFrom) ?? const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay end = _parseTime(dashboard.availableTo) ?? const TimeOfDay(hour: 18, minute: 0);

  return showDialog<List<String>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: const Text('Available Timing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Optionally set the hours you want to receive requests. You can skip this and use the default timing.'),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available From'),
              trailing: Text(start.format(dialogContext)),
              onTap: () async {
                final picked = await showTimePicker(context: dialogContext, initialTime: start);
                if (picked != null) setDialogState(() => start = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available To'),
              trailing: Text(end.format(dialogContext)),
              onTap: () async {
                final picked = await showTimePicker(context: dialogContext, initialTime: end);
                if (picked != null) setDialogState(() => end = picked);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop([_formatTime(start), _formatTime(end)]),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop([_formatTime(start), _formatTime(end)]),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

/// Toggles the current provider's Online/Offline status, prompting for
/// optional available-timing when going online, then calls the availability
/// API and surfaces a snackbar on failure.
Future<void> toggleProviderOnlineStatus(BuildContext context, bool value) async {
  final dashboard = context.read<ProviderDashboardProvider>();
  final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
  if (providerUid == null) return;

  String? availableFrom;
  String? availableTo;

  if (value) {
    final timing = await _promptAvailabilityTiming(context, dashboard);
    if (timing == null) return; // dialog dismissed without a choice
    availableFrom = timing[0];
    availableTo = timing[1];
  }

  final success = await dashboard.setOnline(providerUid, value, availableFrom: availableFrom, availableTo: availableTo);
  if (!context.mounted) return;
  if (!success) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dashboard.availabilityError ?? 'Failed to update status.')));
  }
}
