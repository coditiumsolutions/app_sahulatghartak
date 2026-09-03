import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/service_booking.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/provider_bookings_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/status_progress.dart';
import '../../../widgets/provider/provider_tab_header.dart';
import '../../../widgets/provider/status_chip.dart';
import '../../../widgets/provider/tab_state_placeholder.dart';
import '../../../widgets/status_filter_tabs.dart';
import '../../../widgets/status_progress_bar.dart';
import 'booking_detail_screen.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBookings());
  }

  void _loadBookings() {
    final providerUid = context.read<AuthProvider>().currentUser?.providerUid;
    if (providerUid != null) {
      context.read<ProviderBookingsProvider>().loadBookings(providerUid);
    }
  }

  bool _isActiveBooking(ServiceBooking b) => b.status == 'Pending' || b.status == 'Accepted' || b.status == 'In Progress';
  bool _isCompletedBooking(ServiceBooking b) => b.status == 'Completed' || b.status == 'Closed';
  bool _isCancelledBooking(ServiceBooking b) => b.status == 'Cancelled';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProviderBookingsProvider>();
    // Rejected bookings move to a separate read-only history screen instead
    // of cluttering the active bookings list.
    final bookings = provider.bookings.where((b) => !b.isRejected).toList();
    final active = bookings.where(_isActiveBooking).toList();
    final completed = bookings.where(_isCompletedBooking).toList();
    final cancelled = bookings.where(_isCancelledBooking).toList();
    final tabLists = [active, completed, cancelled];
    final displayed = tabLists[_selectedTab];
    const tabEmptyMessages = [
      'Bookings appear here once you accept a service request from a customer.',
      'Bookings you\'ve completed will show up here.',
      'Bookings you\'ve cancelled will show up here.',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: ProviderTabHeader(
        title: 'My Bookings',
        subtitle: bookings.isEmpty ? 'No bookings yet' : '${bookings.length} booking${bookings.length == 1 ? '' : 's'}',
      ),
      body: provider.loading && bookings.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && bookings.isEmpty
              ? RefreshIndicator(
                  onRefresh: () async => _loadBookings(),
                  child: TabStatePlaceholder(
                    icon: Icons.wifi_off_rounded,
                    color: Colors.red,
                    title: 'Couldn\'t load bookings',
                    message: provider.error,
                    onRetry: _loadBookings,
                  ),
                )
              : bookings.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () async => _loadBookings(),
                      child: const TabStatePlaceholder(
                        icon: Icons.work_outline_rounded,
                        color: kPrimaryColor,
                        title: 'No bookings yet',
                        message: 'Bookings appear here once you accept a service request from a customer.',
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: StatusFilterTabs(
                            labels: const ['Active', 'Completed', 'Cancelled'],
                            counts: [active.length, completed.length, cancelled.length],
                            selectedIndex: _selectedTab,
                            activeColor: providerBrandBlue,
                            onChanged: (i) => setState(() => _selectedTab = i),
                          ),
                        ),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async => _loadBookings(),
                            child: displayed.isEmpty
                                ? TabStatePlaceholder(
                                    icon: Icons.work_outline_rounded,
                                    color: kPrimaryColor,
                                    title: 'No ${const ['active', 'completed', 'cancelled'][_selectedTab]} bookings',
                                    message: tabEmptyMessages[_selectedTab],
                                  )
                                : ListView.separated(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                                    itemCount: displayed.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) => _BookingCard(booking: displayed[index]),
                                  ),
                          ),
                        ),
                      ],
                    ),
    );
  }
}

/// A single booking card mirroring the customer side's `_RequestCard`: a
/// colored left rail for at-a-glance status, icon-led info rows, and an
/// [OpenContainer] container-transform into [BookingDetailScreen].
class _BookingCard extends StatelessWidget {
  final ServiceBooking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(booking.status);

    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      closedColor: const Color(0xFFF4F7FB),
      openColor: const Color(0xFFF4F7FB),
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      transitionDuration: const Duration(milliseconds: 280),
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
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(statusIcon(booking.status), size: 13, color: color),
                                    const SizedBox(width: 4),
                                    Text(booking.status, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11.5)),
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
                                if (booking.clientAddressTitle != null)
                                  _InfoRow(icon: Icons.location_on_rounded, text: booking.clientAddressTitle!),
                                if (booking.clientAddressTitle != null) const SizedBox(height: 6),
                                _InfoRow(icon: Icons.payments_rounded, text: 'Final Rs ${booking.finalAmount.toStringAsFixed(0)}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          StatusProgressBar(
                            steps: kBookingStatusSteps,
                            currentStep: bookingStatusStep(booking.status),
                            activeColor: color,
                            terminalLabel: isBookingStatusTerminal(booking.status) ? booking.status : null,
                            terminalColor: Colors.red,
                            compact: true,
                          ),
                          const SizedBox(height: 10),
                          StatusChip(label: booking.status, color: color),
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
        return BookingDetailScreen(booking: booking, onClose: closeContainer);
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
