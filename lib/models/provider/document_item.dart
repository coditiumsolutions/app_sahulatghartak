enum DocumentStatus { pending, verified, rejected }

extension DocumentStatusX on DocumentStatus {
  String get label {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
    }
  }
}

class DocumentItem {
  final String id;
  final String name;
  final DocumentStatus status;
  final DateTime uploadedAt;

  const DocumentItem({
    required this.id,
    required this.name,
    required this.status,
    required this.uploadedAt,
  });

  DocumentItem copyWith({DocumentStatus? status, DateTime? uploadedAt}) {
    return DocumentItem(
      id: id,
      name: name,
      status: status ?? this.status,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
