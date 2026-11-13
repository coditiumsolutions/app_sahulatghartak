import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/service_booking.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/provider_bookings_provider.dart';
import '../../../utils/constants.dart';
import '../../../utils/contact_actions.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/date_time_formatter.dart';
import '../../../utils/status_progress.dart';
import '../../../widgets/app_toast.dart';
import '../../../widgets/provider/provider_tab_header.dart';
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

  bool _isActiveBooking(ServiceBooking b) =>
      b.status == 'Pending' ||
      b.status == 'Accepted' ||
      b.status == 'In Progress';
  bool _isCompletedBooking(ServiceBooking b) =>
      b.status == 'Completed' || b.status == 'Closed';
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
        subtitle: bookings.isEmpty
            ? 'No bookings yet'
            : '${bookings.length} booking${bookings.length == 1 ? '' : 's'}',
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
                        message:
                            'Bookings appear here once you accept a service request from a customer.',
                      ),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: StatusFilterTabs(
                            labels: const ['Active', 'Completed', 'Cancelled'],
                            counts: [
                              active.length,
                              completed.length,
                              cancelled.length
                            ],
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
                                    title: 'No ${const [
                                      'active',
                                      'completed',
                                      'cancelled'
                                    ][_selectedTab]} bookings',
                                    message: tabEmptyMessages[_selectedTab],
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 16),
                                    itemCount: displayed.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) =>
                                        _BookingCard(booking: displayed[index]),
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
    final bookingsProvider = context.watch<ProviderBookingsProvider>();
    final isStarting = bookingsProvider.updatingUid == booking.uid;
    final canStartJob = booking.status == 'Accepted';
    final canComplete = booking.status == 'In Progress';

    return OpenContainer(
      closedElevation: 0,
      openElevation: 0,
      closedColor: const Color(0xFFF4F7FB),
      openColor: const Color(0xFFF4F7FB),
      closedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      transitionDuration: const Duration(milliseconds: 380),
      closedBuilder: (context, openContainer) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF0A4FA8).withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 6))
            ],
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
                          Text(
                            booking.requestTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16.5,
                                color: Color(0xFF1A2233),
                                height: 1.2),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 13, color: Colors.grey[500]),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  booking.onsiteName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600),
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
                              style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 13.5,
                                  height: 1.35),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF6F8FC),
                                borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_fullAddress(booking) != null) ...[
                                  _InfoRow(
                                      icon: Icons.location_on_rounded,
                                      text: _fullAddress(booking)!,
                                      maxLines: 3),
                                  const SizedBox(height: 6),
                                ],
                                if (formatScheduledDateTime(
                                        booking.preferredServiceDate,
                                        booking.preferredServiceTime) !=
                                    null) ...[
                                  _InfoRow(
                                    icon: Icons.event_rounded,
                                    text: formatScheduledDateTime(
                                        booking.preferredServiceDate,
                                        booking.preferredServiceTime)!,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                _InfoRow(
                                    icon: Icons.payments_rounded,
                                    text:
                                        'Final ${formatCurrency(booking.finalAmount)}'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          StatusProgressBar(
                            steps: kBookingStatusSteps,
                            currentStep: bookingStatusStep(booking.status),
                            activeColor: color,
                            terminalLabel:
                                isBookingStatusTerminal(booking.status)
                                    ? booking.status
                                    : null,
                            terminalColor: Colors.red,
                            compact: true,
                          ),
                          if (booking.onsiteMobile != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => callNumber(
                                      context, booking.onsiteMobile!),
                                  icon: const Icon(Icons.call_rounded,
                                      size: 16, color: kAccentColor),
                                  label: const Text('Call',
                                      style: TextStyle(
                                          color: kAccentColor,
                                          fontWeight: FontWeight.w700)),
                                ),
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  onPressed: () => openWhatsApp(
                                      context, booking.onsiteMobile!),
                                  icon: const Icon(Icons.chat,
                                      size: 16, color: Color(0xFF25D366)),
                                  label: const Text('WhatsApp',
                                      style: TextStyle(
                                          color: Color(0xFF25D366),
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                          if (canStartJob) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kAccentColor,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                ),
                                onPressed: isStarting
                                    ? null
                                    : () async {
                                        final success = await bookingsProvider
                                            .startJob(booking);
                                        if (!context.mounted) return;
                                        showAppToast(
                                          context,
                                          success
                                              ? 'Job started'
                                              : (bookingsProvider.error ??
                                                  'Failed to start job'),
                                          type: success
                                              ? AppToastType.success
                                              : AppToastType.error,
                                        );
                                      },
                                icon: isStarting
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      )
                                    : const Icon(Icons.play_arrow_rounded,
                                        size: 18),
                                label: Text(
                                    isStarting ? 'Starting…' : 'Start Job'),
                              ),
                            ),
                          ],
                          if (canComplete) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700),
                                ),
                                onPressed: () => showBookingCompletionDialog(
                                    context,
                                    booking: booking,
                                    provider: bookingsProvider),
                                icon: const Icon(
                                    Icons.check_circle_outline_rounded,
                                    size: 18),
                                label: const Text('Mark as Complete'),
                              ),
                            ),
                          ],
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

/// Joins the client's full address (not just the address title, e.g. "Home")
/// so the provider has enough detail to judge distance/travel time. Returns
/// null when the booking has no address fields populated yet (e.g. status
/// hasn't reached Accepted - see api.txt's contact-fields note).
String? _fullAddress(ServiceBooking booking) {
  final parts = [
    booking.clientFullAddress,
    booking.clientArea,
    booking.clientCity
  ].whereType<String>().where((s) => s.trim().isNotEmpty).toList();
  return parts.isEmpty ? null : parts.join(', ');
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final int maxLines;

  const _InfoRow({required this.icon, required this.text, this.maxLines = 1});

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
            style: const TextStyle(
                color: Color(0xFF3A4658),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.3),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
