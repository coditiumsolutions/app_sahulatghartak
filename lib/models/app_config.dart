/// `GET /api/v1/app/config` - a bare snake_case object, not the usual
/// `{ success, message, data }` envelope.
class AppConfig {
  final String minimumRequiredVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String storeUrl;
  final String updateMessage;

  /// Latest admin release (`app_unblock`) that applies to this caller, or
  /// null. Used to pull a release the silent push may have missed.
  final DateTime? lastUnblockAt;

  const AppConfig({
    required this.minimumRequiredVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.storeUrl,
    required this.updateMessage,
    this.lastUnblockAt,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
        minimumRequiredVersion:
            json['minimum_required_version'] as String? ?? '0.0.0',
        latestVersion: json['latest_version'] as String? ?? '0.0.0',
        forceUpdate: json['force_update'] as bool? ?? false,
        storeUrl: json['store_url'] as String? ?? '',
        updateMessage: json['update_message'] as String? ?? '',
        lastUnblockAt:
            DateTime.tryParse((json['last_unblock_at'] ?? '').toString())
                ?.toUtc(),
      );
}
