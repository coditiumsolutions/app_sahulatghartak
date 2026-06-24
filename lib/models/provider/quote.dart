enum QuoteStatus { pending, accepted, rejected }

class Quote {
  final String id;
  final int requestId;
  final String customerName;
  final double amount;
  final String eta;
  final QuoteStatus status;

  const Quote({
    required this.id,
    required this.requestId,
    required this.customerName,
    required this.amount,
    required this.eta,
    required this.status,
  });

  Quote copyWith({QuoteStatus? status}) {
    return Quote(
      id: id,
      requestId: requestId,
      customerName: customerName,
      amount: amount,
      eta: eta,
      status: status ?? this.status,
    );
  }
}
