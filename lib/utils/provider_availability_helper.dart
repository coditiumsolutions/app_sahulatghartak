import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/provider_dashboard_provider.dart';
import 'platform_date_picker.dart';

const _brandDark = Color(0xFF0A4FA8);
const _brandBlue = Color(0xFF016EE3);

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
      builder: (dialogContext, setDialogState) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: _brandDark.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_brandDark, _brandBlue]),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Available Timing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                            SizedBox(height: 2),
                            Text('Set your active hours for new requests', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optional — skip to keep receiving requests around the clock, or your previously saved timing.',
                        style: TextStyle(fontSize: 12.5, color: Colors.grey[600], height: 1.4, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      _TimingRow(
                        icon: Icons.wb_sunny_rounded,
                        label: 'Available From',
                        time: start.format(dialogContext),
                        onTap: () async {
                          final picked = await showPlatformTimePicker(dialogContext, initialTime: start);
                          if (picked != null) setDialogState(() => start = picked);
                        },
                      ),
                      const SizedBox(height: 10),
                      _TimingRow(
                        icon: Icons.nights_stay_rounded,
                        label: 'Available To',
                        time: end.format(dialogContext),
                        onTap: () async {
                          final picked = await showPlatformTimePicker(dialogContext, initialTime: end);
                          if (picked != null) setDialogState(() => end = picked);
                        },
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.of(dialogContext).pop([_formatTime(start), _formatTime(end)]),
                              child: const Text('Skip'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.of(dialogContext).pop([_formatTime(start), _formatTime(end)]),
                              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TimingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimingRow({required this.icon, required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF6F8FC),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: _brandBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 17, color: _brandBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF1A2233))),
              ),
              Text(time, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: _brandBlue)),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
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
