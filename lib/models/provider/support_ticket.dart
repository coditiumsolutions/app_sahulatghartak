enum TicketCategory { paymentIssue, customerComplaint, technicalIssue }

extension TicketCategoryX on TicketCategory {
  String get label {
    switch (this) {
      case TicketCategory.paymentIssue:
        return 'Payment Issue';
      case TicketCategory.customerComplaint:
        return 'Customer Complaint';
      case TicketCategory.technicalIssue:
        return 'Technical Issue';
    }
  }
}

enum TicketStatus { open, inProgress, resolved }

extension TicketStatusX on TicketStatus {
  String get label {
    switch (this) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
    }
  }
}

class SupportTicket {
  final String id;
  final TicketCategory category;
  final String subject;
  final String description;
  final TicketStatus status;
  final DateTime createdAt;

  const SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
  });
}
