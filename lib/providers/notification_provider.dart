import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import '../services/api_service.dart';

class NotificationProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  String? _errorMessage;
  List<NotificationItem> _notifications = [];
  int _unreadCount = 0;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<NotificationItem> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.get('/notifications');
      final List<dynamic> list = res['notifications'] ?? [];
      _notifications = list.map((n) => NotificationItem.fromJson(n)).toList();
      _unreadCount = res['unread_count'] is int
          ? res['unread_count']
          : int.tryParse(res['unread_count']?.toString() ?? '0') ?? 0;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _api.post('/notifications/$id/read', {});
      final item = _notifications.firstWhere((n) => n.id == id);
      if (!item.isRead) {
        item.isRead = true;
        _unreadCount = (_unreadCount - 1).clamp(0, 9999);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _api.post('/notifications/read-all', {});
      for (var n in _notifications) {
        n.isRead = true;
      }
      _unreadCount = 0;
      notifyListeners();
    } catch (_) {}
  }
}

