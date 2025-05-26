import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import 'package:bus_ticket_scanner/models/auth_response.dart';
import 'package:bus_ticket_scanner/services/api_client.dart';

class AuthProvider with ChangeNotifier {
  final Logger _logger = Logger();
  final FlutterSecureStorage storage;
  final String baseUrl;

  bool _isAuthenticated = false;
  String? _token;
  String? _operatorName;
  String? _operatorEmail;
  String? _lastError;

  AuthProvider(
      {required this.storage, required this.baseUrl, required Dio dio}) {
    _loadToken();
  }

  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get operatorName => _operatorName;
  String? get operatorEmail => _operatorEmail;
  String? get lastError => _lastError;

  Future<void> _loadToken() async {
    try {
      _logger.i('Loading token from secure storage');
      _token = await storage.read(key: 'auth_token');
      _operatorName = await storage.read(key: 'operator_name');
      _operatorEmail = await storage.read(key: 'operator_email');
      _isAuthenticated = _token != null;
      _logger.i('Token loaded - authenticated: $_isAuthenticated');
      notifyListeners();
    } catch (e) {
      _logger.e('Error loading token: $e');
      _lastError = 'Failed to load session';
    }
  }

  Future<void> login(String email, String password) async {
    try {
      _logger.i('Attempting login with email: $email');
      _lastError = null;
      notifyListeners();

      final response = await ApiClient.post(
        '/api/operator/login',
        data: {'email': email, 'password': password},
      );

      final authResponse = AuthResponse.fromJson(response.data);

      if (authResponse.success) {
        _logger.i('Login successful for ${authResponse.user.email}');
        _token = authResponse.token;
        _operatorName = authResponse.user.name;
        _operatorEmail = authResponse.user.email;
        _isAuthenticated = true;

        await Future.wait([
          storage.write(key: 'auth_token', value: _token),
          storage.write(key: 'operator_name', value: _operatorName),
          storage.write(key: 'operator_email', value: _operatorEmail),
        ]);

        notifyListeners();
      } else {
        throw Exception(authResponse.message);
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message'] ?? _getDioErrorMessage(e);
      _logger.e('Login Dio error: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      _logger.e('Unexpected login error: $e');
      throw Exception('Login failed. Please try again');
    }
  }

  String _getDioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Connection timeout. Please try again';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request cancelled';
      default:
        return 'Network error. Please check your connection';
    }
  }

  Future<void> logout() async {
    try {
      _logger.i('Logging out user');
      await Future.wait([
        storage.delete(key: 'auth_token'),
        storage.delete(key: 'operator_name'),
        storage.delete(key: 'operator_email'),
      ]);
      _token = null;
      _operatorName = null;
      _operatorEmail = null;
      _isAuthenticated = false;
      notifyListeners();
    } catch (e) {
      _logger.e('Error during logout: $e');
      throw Exception('Failed to logout properly');
    }
  }
}
