import '../../models/app_config.dart';
import '../../models/app_notification.dart';
import '../../services/app_config_api_service.dart';
import '../../services/notification_api_service.dart';

/// Thin pass-through to [NotificationApiService] / [AppConfigApiService].
class NotificationRepository {
  NotificationRepository(
      {NotificationApiService? apiService, AppConfigApiService? configService})
      : _apiService = apiService ?? NotificationApiService(),
        _configService = configService ?? AppConfigApiService();

  final NotificationApiService _apiService;
  final AppConfigApiService _configService;

  Future<void> registerToken({
    required int userId,
    required String userType,
    required String deviceToken,
    required String platform,
  }) =>
      _apiService.registerToken(
          userId: userId,
          userType: userType,
          deviceToken: deviceToken,
          platform: platform);

  Future<void> unregisterToken(String deviceToken) =>
      _apiService.unregisterToken(deviceToken);

  Future<NotificationPage> fetchInbox(
          {required int userId,
          required String userType,
          int page = 1,
          int pageSize = 20}) =>
      _apiService.fetchInbox(
          userId: userId, userType: userType, page: page, pageSize: pageSize);

  Future<int> fetchUnreadCount(
          {required int userId, required String userType}) =>
      _apiService.fetchUnreadCount(userId: userId, userType: userType);

  Future<void> markRead({required int id, required int userId}) =>
      _apiService.markRead(id: id, userId: userId);

  Future<void> markAllRead({required int userId, required String userType}) =>
      _apiService.markAllRead(userId: userId, userType: userType);

  Future<AppConfig> fetchAppConfig(String platform, {String? deviceToken}) =>
      _configService.fetchConfig(platform, deviceToken: deviceToken);
}
