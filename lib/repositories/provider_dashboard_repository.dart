import 'package:flutter/material.dart';

import '../models/provider/availability_slot.dart';
import '../models/provider/chat_message.dart';
import '../models/provider/document_item.dart';
import '../models/provider/earnings_summary.dart';
import '../models/provider/job.dart';
import '../models/provider/notification_item.dart';
import '../models/provider/quote.dart';
import '../models/provider/review.dart';
import '../models/provider/service_item.dart';
import '../models/provider/support_ticket.dart';
import '../models/provider/wallet_transaction.dart';

/// Provides dummy/mock data for the Provider Dashboard.
/// Replace with real API calls when backend endpoints are ready.
class ProviderDashboardRepository {
  List<Quote> getQuotes() {
    return const [
      Quote(id: 'q1', requestId: 5, customerName: 'Fahad Mehmood', amount: 1500, eta: '30 mins', status: QuoteStatus.pending),
      Quote(id: 'q2', requestId: 6, customerName: 'Ayesha Noor', amount: 3200, eta: '1 hour', status: QuoteStatus.accepted),
      Quote(id: 'q3', requestId: 7, customerName: 'Usman Sheikh', amount: 800, eta: '20 mins', status: QuoteStatus.rejected),
      Quote(id: 'q4', requestId: 8, customerName: 'Zainab Malik', amount: 2100, eta: '45 mins', status: QuoteStatus.pending),
    ];
  }

  List<Job> getActiveJobs() {
    final now = DateTime.now();
    return [
      Job(id: 'j1', customerName: 'Imran Qureshi', serviceType: 'Pipe Leakage Repair', address: 'Bahria Town, Lahore', distanceKm: 3.2, bookingAmount: 2500, status: JobStatus.accepted, date: now),
      Job(id: 'j2', customerName: 'Nadia Hussain', serviceType: 'Fan Installation', address: 'Wapda Town, Lahore', distanceKm: 1.8, bookingAmount: 1200, status: JobStatus.onTheWay, date: now),
      Job(id: 'j3', customerName: 'Kamran Aslam', serviceType: 'AC Servicing', address: 'Iqbal Town, Lahore', distanceKm: 5.0, bookingAmount: 1800, status: JobStatus.started, date: now),
    ];
  }

  List<Job> getJobHistory() {
    final now = DateTime.now();
    return [
      Job(id: 'h1', customerName: 'Tariq Mahmood', serviceType: 'Tap Replacement', address: 'DHA Phase 2, Lahore', distanceKm: 2.0, bookingAmount: 1000, status: JobStatus.completed, date: now.subtract(const Duration(hours: 3)), rating: 5.0),
      Job(id: 'h2', customerName: 'Rabia Saeed', serviceType: 'Wiring Fix', address: 'Cantt, Lahore', distanceKm: 3.5, bookingAmount: 1600, status: JobStatus.completed, date: now.subtract(const Duration(days: 1)), rating: 4.5),
      Job(id: 'h3', customerName: 'Asad Raza', serviceType: 'Water Tank Repair', address: 'Township, Lahore', distanceKm: 4.4, bookingAmount: 3000, status: JobStatus.completed, date: now.subtract(const Duration(days: 5)), rating: 4.8),
      Job(id: 'h4', customerName: 'Mehwish Ali', serviceType: 'Bathroom Fittings', address: 'Garden Town, Lahore', distanceKm: 2.7, bookingAmount: 2200, status: JobStatus.completed, date: now.subtract(const Duration(days: 20)), rating: 5.0),
    ];
  }

  EarningsSummary getEarningsSummary() {
    return const EarningsSummary(
      today: 8500,
      weekly: 42000,
      monthly: 165000,
      total: 980000,
      dailyChart: [
        DailyEarning(dayLabel: 'Mon', amount: 5200),
        DailyEarning(dayLabel: 'Tue', amount: 6800),
        DailyEarning(dayLabel: 'Wed', amount: 4100),
        DailyEarning(dayLabel: 'Thu', amount: 7300),
        DailyEarning(dayLabel: 'Fri', amount: 8500),
        DailyEarning(dayLabel: 'Sat', amount: 9200),
        DailyEarning(dayLabel: 'Sun', amount: 3900),
      ],
      monthlyChart: [
        MonthlyEarning(monthLabel: 'Jan', amount: 120000),
        MonthlyEarning(monthLabel: 'Feb', amount: 98000),
        MonthlyEarning(monthLabel: 'Mar', amount: 145000),
        MonthlyEarning(monthLabel: 'Apr', amount: 132000),
        MonthlyEarning(monthLabel: 'May', amount: 158000),
        MonthlyEarning(monthLabel: 'Jun', amount: 165000),
      ],
    );
  }

  double getWalletBalance() => 12000;

  List<WalletTransaction> getWalletTransactions() {
    final now = DateTime.now();
    return [
      WalletTransaction(id: 'w1', type: TransactionType.credit, amount: 2500, description: 'Job payment - Imran Qureshi', date: now.subtract(const Duration(hours: 2))),
      WalletTransaction(id: 'w2', type: TransactionType.withdrawal, amount: 5000, description: 'Withdrawal to bank account', date: now.subtract(const Duration(days: 2))),
      WalletTransaction(id: 'w3', type: TransactionType.credit, amount: 1800, description: 'Job payment - Kamran Aslam', date: now.subtract(const Duration(days: 3))),
      WalletTransaction(id: 'w4', type: TransactionType.credit, amount: 1000, description: 'Job payment - Tariq Mahmood', date: now.subtract(const Duration(days: 4))),
    ];
  }

  List<Review> getReviews() {
    final now = DateTime.now();
    return [
      Review(id: 'rv1', customerName: 'Tariq Mahmood', rating: 5.0, reviewText: 'Excellent service, very professional and on time.', date: now.subtract(const Duration(hours: 3))),
      Review(id: 'rv2', customerName: 'Rabia Saeed', rating: 4.5, reviewText: 'Good work, fixed the wiring issue quickly.', date: now.subtract(const Duration(days: 1))),
      Review(id: 'rv3', customerName: 'Asad Raza', rating: 4.8, reviewText: 'Very satisfied, will book again.', date: now.subtract(const Duration(days: 5))),
      Review(id: 'rv4', customerName: 'Mehwish Ali', rating: 5.0, reviewText: 'Polite and skilled, highly recommended.', date: now.subtract(const Duration(days: 20))),
    ];
  }

  List<NotificationItem> getNotifications() {
    final now = DateTime.now();
    return [
      NotificationItem(id: 'n1', type: NotificationType.newRequest, message: 'You have a new service request from Ahmed Khan.', time: now.subtract(const Duration(minutes: 5))),
      NotificationItem(id: 'n2', type: NotificationType.quoteAccepted, message: 'Ayesha Noor accepted your quote of Rs 3,200.', time: now.subtract(const Duration(hours: 1)), isRead: true),
      NotificationItem(id: 'n3', type: NotificationType.paymentReceived, message: 'You received Rs 2,500 for job #j1.', time: now.subtract(const Duration(hours: 2)), isRead: true),
      NotificationItem(id: 'n4', type: NotificationType.accountVerified, message: 'Your CNIC document has been verified.', time: now.subtract(const Duration(days: 1)), isRead: true),
      NotificationItem(id: 'n5', type: NotificationType.system, message: 'App updated with new features. Check them out!', time: now.subtract(const Duration(days: 2)), isRead: true),
    ];
  }

  List<ChatThread> getChatThreads() {
    final now = DateTime.now();
    return [
      ChatThread(
        id: 'c1',
        customerName: 'Imran Qureshi',
        lastMessage: 'Sure, see you in 10 minutes.',
        lastMessageTime: now.subtract(const Duration(minutes: 10)),
        unreadCount: 2,
        messages: [
          ChatMessage(id: 'm1', text: 'Hi, when will you arrive?', type: MessageType.text, isMe: false, time: now.subtract(const Duration(minutes: 20))),
          ChatMessage(id: 'm2', text: 'I am on my way, about 15 minutes away.', type: MessageType.text, isMe: true, time: now.subtract(const Duration(minutes: 18))),
          ChatMessage(id: 'm3', text: 'Sure, see you in 10 minutes.', type: MessageType.text, isMe: false, time: now.subtract(const Duration(minutes: 10))),
        ],
      ),
      ChatThread(
        id: 'c2',
        customerName: 'Nadia Hussain',
        lastMessage: '📍 Location shared',
        lastMessageTime: now.subtract(const Duration(hours: 1)),
        unreadCount: 0,
        messages: [
          ChatMessage(id: 'm4', text: '📍 Location shared', type: MessageType.location, isMe: false, time: now.subtract(const Duration(hours: 1))),
          ChatMessage(id: 'm5', text: 'Got it, thanks!', type: MessageType.text, isMe: true, time: now.subtract(const Duration(hours: 1))),
        ],
      ),
      ChatThread(
        id: 'c3',
        customerName: 'Kamran Aslam',
        lastMessage: 'Thank you for the great service!',
        lastMessageTime: now.subtract(const Duration(days: 1)),
        unreadCount: 0,
        messages: [
          ChatMessage(id: 'm6', text: 'Thank you for the great service!', type: MessageType.text, isMe: false, time: now.subtract(const Duration(days: 1))),
        ],
      ),
    ];
  }

  List<AvailabilitySlot> getAvailabilitySlots() {
    return [
      AvailabilitySlot(id: 'a1', day: 'Monday', startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 18, minute: 0)),
      AvailabilitySlot(id: 'a2', day: 'Tuesday', startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 18, minute: 0)),
      AvailabilitySlot(id: 'a3', day: 'Wednesday', startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 18, minute: 0)),
      AvailabilitySlot(id: 'a4', day: 'Thursday', startTime: const TimeOfDay(hour: 9, minute: 0), endTime: const TimeOfDay(hour: 18, minute: 0)),
      AvailabilitySlot(id: 'a5', day: 'Friday', startTime: const TimeOfDay(hour: 14, minute: 0), endTime: const TimeOfDay(hour: 20, minute: 0)),
    ];
  }

  List<ServiceCategoryOffering> getServiceOfferings() {
    return [
      ServiceCategoryOffering(categoryName: 'Plumbing', subServices: [
        ServiceSubItem(name: 'Pipe Leakage', isSelected: true),
        ServiceSubItem(name: 'Water Tank Repair', isSelected: true),
        ServiceSubItem(name: 'Bathroom Fittings', isSelected: true),
        ServiceSubItem(name: 'Drainage Cleaning', isSelected: false),
      ]),
      ServiceCategoryOffering(categoryName: 'Electrical', subServices: [
        ServiceSubItem(name: 'Wiring', isSelected: true),
        ServiceSubItem(name: 'Fan Installation', isSelected: false),
        ServiceSubItem(name: 'Switch Board Repair', isSelected: false),
      ]),
      ServiceCategoryOffering(categoryName: 'AC Repair', subServices: [
        ServiceSubItem(name: 'AC Servicing', isSelected: false),
        ServiceSubItem(name: 'Gas Refilling', isSelected: false),
      ]),
    ];
  }

  List<DocumentItem> getDocuments() {
    final now = DateTime.now();
    return [
      DocumentItem(id: 'd1', name: 'CNIC', status: DocumentStatus.verified, uploadedAt: now.subtract(const Duration(days: 30))),
      DocumentItem(id: 'd2', name: 'Police Verification', status: DocumentStatus.verified, uploadedAt: now.subtract(const Duration(days: 25))),
      DocumentItem(id: 'd3', name: 'Driving License', status: DocumentStatus.pending, uploadedAt: now.subtract(const Duration(days: 2))),
      DocumentItem(id: 'd4', name: 'Professional Certification', status: DocumentStatus.rejected, uploadedAt: now.subtract(const Duration(days: 10))),
    ];
  }

  List<SupportTicket> getSupportTickets() {
    final now = DateTime.now();
    return [
      SupportTicket(id: 't1', category: TicketCategory.paymentIssue, subject: 'Payment not received', description: 'I completed a job but the payment is not reflected in my wallet.', status: TicketStatus.inProgress, createdAt: now.subtract(const Duration(days: 1))),
      SupportTicket(id: 't2', category: TicketCategory.technicalIssue, subject: 'App crashing on job start', description: 'The app crashes when I tap Start Job button.', status: TicketStatus.resolved, createdAt: now.subtract(const Duration(days: 5))),
    ];
  }
}
