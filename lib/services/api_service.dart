import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  String? get token => _token;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (!rememberMe) {
      // If remember me is disabled, do not restore token from disk across cold starts
      await prefs.remove('auth_token');
      _token = null;
    } else {
      _token = prefs.getString('auth_token');
    }
  }

  Future<void> setToken(String? token, {bool persist = true}) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null && persist) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  Map<String, String> _headers({bool isJson = true}) {
    final headers = <String, String>{
      'Accept': 'application/json',
    };
    if (isJson) {
      headers['Content-Type'] = 'application/json';
    }
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    var url = '${ApiConfig.baseUrl}/$cleanPath';

    if (queryParams != null && queryParams.isNotEmpty) {
      final cleanParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
      final uri = Uri.parse(url);
      return uri.replace(queryParameters: cleanParams);
    }

    return Uri.parse(url);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? queryParams}) async {
    final uri = _buildUri(path, queryParams);
    final response = await http.get(uri, headers: _headers(isJson: false));
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    final response = await http.post(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    final response = await http.put(
      uri,
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = _buildUri(path);
    final response = await http.delete(uri, headers: _headers(isJson: false));
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      body = {'message': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      final message = body is Map && body.containsKey('message')
          ? body['message']
          : 'Terjadi kesalahan sistem (${response.statusCode})';
      throw Exception(message);
    }
  }
}
