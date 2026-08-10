import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/service_booking.dart';
import '../../../providers/provider_bookings_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/provider/provider_tab_header.dart';
import '../../../widgets/provider/status_chip.dart';
import '../../../widgets/provider/tab_state_placeholder.dart';
import 'booking_detail_screen.dart';

/// Read-only history of bookings the provider rejected — kept out of the
/// main Bookings tab, but still viewable here since the underlying request
/// is stale and can no longer be acted on.
class RejectedRequestsScreen extends StatefulWidget {
  static const routeName = '/provider/jobs/rejected';

  const RejectedRequestsScreen({super.key});

  @override
  State<RejectedRequestsScreen> createState() => _RejectedRequestsScreenState();
}

class _RejectedRequestsScreenState extends State<RejectedRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProviderBookingsProvider>().markRejectedSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rejected = context.watch<ProviderBookingsProvider>().bookings.where((b) => b.isRejected).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'Rejected Requests',
        subtitle: rejected.isEmpty ? 'No rejected requests' : '${rejected.length} request${rejected.length == 1 ? '' : 's'}',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: rejected.isEmpty
          ? const TabStatePlaceholder(
              icon: Icons.inbox_rounded,
              color: kPrimaryColor,
              title: 'No rejected requests',
              message: 'Requests you reject will show up here for reference.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rejected.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _RejectedCard(booking: rejected[index]),
            ),
    );
  }
}

class _RejectedCard extends StatelessWidget {
  final ServiceBooking booking;

  const _RejectedCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    const color = Colors.red;

    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: const Color(0xFFF4F7FB),
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      transitionDuration: const Duration(milliseconds: 420),
      closedBuilder: (context, openContainer) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: const Color(0xFF0A4FA8).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: openContainer,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.requestTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16.5, color: Color(0xFF1A2233), height: 1.2),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.person_outline_rounded, size: 13, color: Colors.grey[500]),
                                        const SizedBox(width: 3),
                                        Expanded(
                                          child: Text(
                                            booking.clientName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey[500], fontSize: 12.5, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.cancel_rounded, size: 13, color: color),
                                    SizedBox(width: 4),
                                    Text('Rejected', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (booking.serviceDetail.trim().isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              booking.serviceDetail,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700], fontSize: 13.5, height: 1.35),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFF6F8FC), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (booking.clientAddressTitle != null) _InfoRow(icon: Icons.location_on_rounded, text: booking.clientAddressTitle!),
                                if (booking.clientAddressTitle != null) const SizedBox(height: 6),
                                _InfoRow(icon: Icons.payments_rounded, text: 'Final Rs ${booking.finalAmount.toStringAsFixed(0)}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const StatusChip(label: 'Rejected', color: color),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      openBuilder: (context, closeContainer) {
        return BookingDetailScreen(booking: booking, onClose: closeContainer, readOnly: true);
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: kPrimaryColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF3A4658), fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
