import 'package:flutter/material.dart';

import '../models/provider_profile_model.dart';
import '../services/provider_profile_api_service.dart';
import '../services/provider_service_request_api_service.dart';
import '../models/provider/availability_slot.dart';
import '../models/provider/chat_message.dart';
import '../models/provider/document_item.dart';
import '../models/provider/earnings_summary.dart';
import '../models/provider/job.dart';
import '../models/provider/notification_item.dart';
import '../models/provider/quote.dart';
import '../models/provider/review.dart';
import '../models/provider/service_item.dart';
import '../models/provider/service_request.dart';
import '../models/provider/support_ticket.dart';
import '../models/provider/wallet_transaction.dart';
import '../repositories/provider_dashboard_repository.dart';

class ProviderDashboardProvider extends ChangeNotifier {
  final ProviderDashboardRepository _repo = ProviderDashboardRepository();
  final ProviderServiceRequestApiService _serviceRequestApiService = ProviderServiceRequestApiService();
  final ProviderProfileApiService _profileApiService = ProviderProfileApiService();

  ProviderDashboardProvider() {
    _quotes = _repo.getQuotes();
    _activeJobs = _repo.getActiveJobs();
    _jobHistory = _repo.getJobHistory();
    _earningsSummary = _repo.getEarningsSummary();
    _walletBalance = _repo.getWalletBalance();
    _walletTransactions = _repo.getWalletTransactions();
    _reviews = _repo.getReviews();
    _notifications = _repo.getNotifications();
    _chatThreads = _repo.getChatThreads();
    _availabilitySlots = _repo.getAvailabilitySlots();
    _serviceOfferings = _repo.getServiceOfferings();
    _documents = _repo.getDocuments();
    _supportTickets = _repo.getSupportTickets();
  }

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  void setOnline(bool value) {
    _isOnline = value;
    notifyListeners();
  }

  List<ServiceRequest> _incomingRequests = [];
  List<ServiceRequest> get incomingRequests => _incomingRequests;

  bool _requestsLoading = false;
  bool get requestsLoading => _requestsLoading;

  String? _requestsError;
  String? get requestsError => _requestsError;

  Future<void> loadIncomingRequests(int providerId) async {
    _requestsLoading = true;
    _requestsError = null;
    notifyListeners();

    try {
      _incomingRequests = await _serviceRequestApiService.fetchByProvider(providerId);
    } catch (e) {
      _requestsError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _requestsLoading = false;
      notifyListeners();
    }
  }

  void rejectRequest(int requestId) {
    _incomingRequests = _incomingRequests.where((r) => r.id != requestId).toList();
    notifyListeners();
  }

  late List<Quote> _quotes;
  List<Quote> get quotes => _quotes;

  void sendQuote(ServiceRequest request, double amount, String eta) {
    _quotes = [
      Quote(id: 'q${DateTime.now().millisecondsSinceEpoch}', requestId: request.id, customerName: request.customerName, amount: amount, eta: eta, status: QuoteStatus.pending),
      ..._quotes,
    ];
    _incomingRequests = _incomingRequests.where((r) => r.id != request.id).toList();
    notifyListeners();
  }

  late List<Job> _activeJobs;
  List<Job> get activeJobs => _activeJobs;

  late List<Job> _jobHistory;
  List<Job> get jobHistory => _jobHistory;

  void advanceJobStatus(String jobId) {
    final index = _activeJobs.indexWhere((j) => j.id == jobId);
    if (index == -1) return;
    final job = _activeJobs[index];
    final next = job.status.next;
    if (next == null) return;

    if (next == JobStatus.completed) {
      _jobHistory = [job.copyWith(status: JobStatus.completed), ..._jobHistory];
      _activeJobs = List.of(_activeJobs)..removeAt(index);
    } else {
      final updated = List.of(_activeJobs);
      updated[index] = job.copyWith(status: next);
      _activeJobs = updated;
    }
    notifyListeners();
  }

  late EarningsSummary _earningsSummary;
  EarningsSummary get earningsSummary => _earningsSummary;

  late double _walletBalance;
  double get walletBalance => _walletBalance;

  late List<WalletTransaction> _walletTransactions;
  List<WalletTransaction> get walletTransactions => _walletTransactions;

  bool requestWithdrawal(double amount) {
    if (amount <= 0 || amount > _walletBalance) return false;
    _walletBalance -= amount;
    _walletTransactions = [
      WalletTransaction(id: 'w${DateTime.now().millisecondsSinceEpoch}', type: TransactionType.withdrawal, amount: amount, description: 'Withdrawal to bank account', date: DateTime.now()),
      ..._walletTransactions,
    ];
    notifyListeners();
    return true;
  }

  late List<Review> _reviews;
  List<Review> get reviews => _reviews;
  double get averageRating => _reviews.isEmpty ? 0 : _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;

  late List<NotificationItem> _notifications;
  List<NotificationItem> get notifications => _notifications;
  int get unreadNotificationCount => _notifications.where((n) => !n.isRead).length;

  void markNotificationRead(String id) {
    _notifications = _notifications.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList();
    notifyListeners();
  }

  late List<ChatThread> _chatThreads;
  List<ChatThread> get chatThreads => _chatThreads;

  void sendChatMessage(String threadId, String text, {MessageType type = MessageType.text}) {
    final index = _chatThreads.indexWhere((t) => t.id == threadId);
    if (index == -1) return;
    final thread = _chatThreads[index];
    final message = ChatMessage(id: 'm${DateTime.now().millisecondsSinceEpoch}', text: text, type: type, isMe: true, time: DateTime.now());
    final updated = List.of(_chatThreads);
    updated[index] = ChatThread(
      id: thread.id,
      customerName: thread.customerName,
      lastMessage: text,
      lastMessageTime: message.time,
      unreadCount: 0,
      messages: [...thread.messages, message],
    );
    _chatThreads = updated;
    notifyListeners();
  }

  late List<AvailabilitySlot> _availabilitySlots;
  List<AvailabilitySlot> get availabilitySlots => _availabilitySlots;

  void addAvailabilitySlot(AvailabilitySlot slot) {
    _availabilitySlots = [..._availabilitySlots, slot];
    notifyListeners();
  }

  void updateAvailabilitySlot(AvailabilitySlot slot) {
    _availabilitySlots = _availabilitySlots.map((s) => s.id == slot.id ? slot : s).toList();
    notifyListeners();
  }

  void deleteAvailabilitySlot(String id) {
    _availabilitySlots = _availabilitySlots.where((s) => s.id != id).toList();
    notifyListeners();
  }

  late List<ServiceCategoryOffering> _serviceOfferings;
  List<ServiceCategoryOffering> get serviceOfferings => _serviceOfferings;

  void toggleSubService(String categoryName, String subServiceName) {
    _serviceOfferings = _serviceOfferings.map((category) {
      if (category.categoryName != categoryName) return category;
      final updatedSubs = category.subServices.map((s) {
        if (s.name != subServiceName) return s;
        return s.copyWith(isSelected: !s.isSelected);
      }).toList();
      return category.copyWith(subServices: updatedSubs);
    }).toList();
    notifyListeners();
  }

  late List<DocumentItem> _documents;
  List<DocumentItem> get documents => _documents;

  void uploadDocument(String name) {
    _documents = [
      DocumentItem(id: 'd${DateTime.now().millisecondsSinceEpoch}', name: name, status: DocumentStatus.pending, uploadedAt: DateTime.now()),
      ..._documents,
    ];
    notifyListeners();
  }

  late List<SupportTicket> _supportTickets;
  List<SupportTicket> get supportTickets => _supportTickets;

  void createSupportTicket({required TicketCategory category, required String subject, required String description}) {
    _supportTickets = [
      SupportTicket(id: 't${DateTime.now().millisecondsSinceEpoch}', category: category, subject: subject, description: description, status: TicketStatus.open, createdAt: DateTime.now()),
      ..._supportTickets,
    ];
    notifyListeners();
  }

  ProviderProfileModel? _profile;
  ProviderProfileModel? get profile => _profile;

  bool _profileLoading = false;
  bool get profileLoading => _profileLoading;

  String? _profileError;
  String? get profileError => _profileError;

  Future<void> loadProfile(int userId) async {
    _profileLoading = true;
    _profileError = null;
    notifyListeners();

    try {
      _profile = await _profileApiService.fetchById(userId);
    } catch (e) {
      _profileError = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _profileLoading = false;
      notifyListeners();
    }
  }

  void updateProfile(ProviderProfileModel updated) {
    _profile = updated;
    notifyListeners();
  }

  // Home screen summary counters.
  int get completedJobsToday => _jobHistory.where((j) => j.date.day == DateTime.now().day && j.date.month == DateTime.now().month && j.date.year == DateTime.now().year).length;
}
