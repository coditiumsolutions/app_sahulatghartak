class Review {
  final String id;
  final String customerName;
  final double rating;
  final String reviewText;
  final DateTime date;

  const Review({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.reviewText,
    required this.date,
  });
}
