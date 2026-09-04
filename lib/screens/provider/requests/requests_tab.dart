import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/service_booking.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/provider_bookings_provider.dart';
import '../../../utils/cancel_reasons.dart';
import '../../../utils/constants.dart';
import '../../../widgets/provider/provider_tab_header.dart';
import '../../../widgets/reason_dialog.dart';
import '../../../widgets/provider/tab_state_placeholder.dart';
import '../jobs/booking_detail_screen.dart';
import '../jobs/rejected_requests_screen.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRequests());
  }

  void _loadRequests() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid != null) {
      context.read<ProviderBookingsProvider>().loadBookings(providerUid);
    }
  }

  void _viewDetails(BuildContext context, ServiceBooking booking) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => BookingDetailScreen(booking: booking)));
  }

  Future<void> _accept(BuildContext context, ServiceBooking booking) async {
    final provider = context.read<ProviderBookingsProvider>();
    final success = await provider.respond(booking, true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Booking accepted' : (provider.error ?? 'Failed to accept booking'))),
    );
  }

  Future<void> _reject(BuildContext context, ServiceBooking booking) async {
    final reason = await showReasonDialog(
      context,
      title: 'Reject Booking',
      message: 'Are you sure you want to reject this booking for "${booking.requestTitle}"? This cannot be undone.',
      confirmLabel: 'Yes, Reject',
      reasons: kProviderCancelReasons,
      icon: Icons.cancel_outlined,
      color: Colors.red,
    );
    if (reason == null || !context.mounted) return;

    final provider = context.read<ProviderBookingsProvider>();
    final success = await provider.respond(booking, false, reason: reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? 'Booking rejected' : (provider.error ?? 'Failed to reject booking'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingsProvider = context.watch<ProviderBookingsProvider>();
    final requests = bookingsProvider.bookings.where((b) => b.status == 'Pending').toList();
    final unviewedRejectedCount = bookingsProvider.unviewedRejectedCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'Incoming Requests',
        subtitle: requests.isEmpty ? 'No requests right now' : '${requests.length} request${requests.length == 1 ? '' : 's'} waiting',
        trailing: IconButton(
          icon: Badge(
            isLabelVisible: unviewedRejectedCount > 0,
            label: Text('$unviewedRejectedCount'),
            child: const Icon(Icons.history_rounded, color: Colors.white),
          ),
          tooltip: 'Rejected Requests',
          onPressed: () => Navigator.of(context).pushNamed(RejectedRequestsScreen.routeName),
        ),
      ),
      body: bookingsProvider.loading && requests.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : bookingsProvider.error != null && requests.isEmpty
              ? RefreshIndicator(
                  onRefresh: () async => _loadRequests(),
                  child: TabStatePlaceholder(
                    icon: Icons.wifi_off_rounded,
                    color: Colors.red,
                    title: 'Couldn\'t load requests',
                    message: bookingsProvider.error,
                    onRetry: _loadRequests,
                  ),
                )
              : requests.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () async => _loadRequests(),
                      child: const TabStatePlaceholder(
                        icon: Icons.inbox_rounded,
                        color: kPrimaryColor,
                        title: 'No requests yet',
                        message: 'New job assignments from staff will show up here as soon as they come in.',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => _loadRequests(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = requests[index];
                          final updating = bookingsProvider.updatingUid == booking.uid;
                          return _IncomingRequestCard(
                            booking: booking,
                            updating: updating,
                            onViewDetails: () => _viewDetails(context, booking),
                            onAccept: () => _accept(context, booking),
                            onReject: () => _reject(context, booking),
                          );
                        },
                      ),
                    ),
    );
  }
}

/// Incoming-request card matching the customer side's white-card/left-rail
/// style ([lib/screens/service_requests_screen.dart]'s `_RequestCard`).
class _IncomingRequestCard extends StatelessWidget {
  final ServiceBooking booking;
  final bool updating;
  final VoidCallback onViewDetails;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _IncomingRequestCard({
    required this.booking,
    required this.updating,
    required this.onViewDetails,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    const statusColor = Colors.blueGrey;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: const Color(0xFF0A4FA8).withValues(alpha: 0.06), blurRadius: 18, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: statusColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [kPrimaryColor, kPrimaryColor.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            booking.clientName.isNotEmpty ? booking.clientName[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 17),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking.clientName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1A2233))),
                              const SizedBox(height: 2),
                              Text(booking.requestTitle, style: TextStyle(color: Colors.grey[500], fontSize: 12.5, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.hourglass_top_rounded, size: 13, color: statusColor),
                              SizedBox(width: 4),
                              Text('Pending', style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (booking.serviceDetail.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        booking.serviceDetail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.35),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFF6F8FC), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 16, color: kPrimaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  [booking.clientAddressTitle, booking.clientFullAddress, booking.clientArea, booking.clientCity]
                                      .whereType<String>()
                                      .join(', '),
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF3A4658), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.payments_rounded, size: 16, color: kPrimaryColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Est. Rs ${booking.estimatedAmount.toStringAsFixed(0)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Color(0xFF3A4658), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          'Requested ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.createdOn)}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11.5, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kPrimaryColor,
                              side: BorderSide(color: kPrimaryColor.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: updating ? null : onViewDetails,
                            child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: updating ? null : onAccept,
                            child: updating
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Accept', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Material(
                          color: Colors.red.withValues(alpha: 0.08),
                          shape: const CircleBorder(),
                          child: IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                            tooltip: 'Reject',
                            onPressed: updating ? null : onReject,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
