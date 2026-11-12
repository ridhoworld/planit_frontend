class ApiConfig {
  /// Alamat server API PlanIt
  /// Backend aktif di server: http://202.93.244.226:8001/api
  static const String serverUrl = 'http://202.93.244.226:8001/api';

  static String get defaultBaseUrl {
    return serverUrl;
  }

  static String baseUrl = defaultBaseUrl;
}
