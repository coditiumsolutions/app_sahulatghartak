import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/provider/document_item.dart';
import '../../../providers/provider_dashboard_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/provider/status_chip.dart';

class DocumentsScreen extends StatelessWidget {
  static const routeName = '/provider/documents';
  const DocumentsScreen({super.key});

  Color _statusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.verified:
        return Colors.green;
      case DocumentStatus.rejected:
        return Colors.red;
    }
  }

  Future<void> _uploadDocument(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Upload Document'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Document Name')),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                context.read<ProviderDashboardProvider>().uploadDocument(name);
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final documents = context.watch<ProviderDashboardProvider>().documents;

    return Scaffold(
      appBar: AppBar(title: const Text('Documents'), backgroundColor: kPrimaryColor),
      floatingActionButton: FloatingActionButton(onPressed: () => _uploadDocument(context), backgroundColor: kPrimaryColor, child: const Icon(Icons.upload_file)),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final document = documents[index];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.description, color: kPrimaryColor),
              title: Text(document.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Uploaded ${DateFormat('dd MMM yyyy').format(document.uploadedAt)}'),
              trailing: StatusChip(label: document.status.label, color: _statusColor(document.status)),
            ),
          );
        },
      ),
    );
  }
}
