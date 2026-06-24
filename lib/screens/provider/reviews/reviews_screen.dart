import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';

class ReviewsScreen extends StatelessWidget {
  static const routeName = '/provider/reviews';
  const ReviewsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final reviews = dashboard.reviews;

    return Scaffold(
      appBar: AppBar(title: const Text('Reviews & Ratings'), backgroundColor: kPrimaryColor),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(dashboard.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) => Icon(i < dashboard.averageRating.round() ? Icons.star : Icons.star_border, color: Colors.amber)),
                  ),
                  const SizedBox(height: 4),
                  Text('${reviews.length} reviews', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Customer Feedback', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...reviews.map((review) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(children: [const Icon(Icons.star, size: 16, color: Colors.amber), Text(review.rating.toStringAsFixed(1))]),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(review.reviewText),
                      const SizedBox(height: 6),
                      Text(DateFormat('dd MMM yyyy').format(review.date), style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
