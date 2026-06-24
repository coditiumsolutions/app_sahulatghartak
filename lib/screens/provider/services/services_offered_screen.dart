import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';

class ServicesOfferedScreen extends StatelessWidget {
  static const routeName = '/provider/services-offered';
  const ServicesOfferedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<ProviderDashboardProvider>();
    final offerings = dashboard.serviceOfferings;

    return Scaffold(
      appBar: AppBar(title: const Text('Services Offered'), backgroundColor: kPrimaryColor),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: offerings.length,
        itemBuilder: (context, index) {
          final category = offerings[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ExpansionTile(
              title: Text(category.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
              initiallyExpanded: index == 0,
              children: category.subServices
                  .map((sub) => CheckboxListTile(
                        title: Text(sub.name),
                        value: sub.isSelected,
                        activeColor: kPrimaryColor,
                        onChanged: (_) => dashboard.toggleSubService(category.categoryName, sub.name),
                      ))
                  .toList(),
            ),
          );
        },
      ),
    );
  }
}
