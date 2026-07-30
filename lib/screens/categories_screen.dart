import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/service_provider.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/service_card.dart';

class CategoriesScreen extends StatefulWidget {
  static const routeName = '/categories';

  /// True when hosted inside [MainNavigationShell], which already provides
  /// the bottom navigation bar.
  final bool embedded;

  const CategoriesScreen({Key? key, this.embedded = false}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final services = context.watch<ServiceProvider>().services.where((s) => s.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Categories'), backgroundColor: Colors.yellow),
      bottomNavigationBar: widget.embedded ? null : const AppBottomNavigation(currentIndex: -1),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(children: [
          TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search services'),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 1.1, crossAxisSpacing: 12, mainAxisSpacing: 12),
              itemCount: services.length,
              itemBuilder: (context, idx) => ServiceCard(service: services[idx]),
            ),
          ),
        ]),
      ),
    );
  }
}
