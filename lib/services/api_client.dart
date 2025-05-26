import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class ApiClient {
  static final Logger _logger = Logger();
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://n7gjzkm4-3001.euw.devtunnels.ms',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  static Future<Response> post(String path, {dynamic data}) async {
    try {
      _logger.i('POST $path\nRequest Data: $data');
      final response = await _dio.post(path, data: data);
      _logger.i('Response: ${response.statusCode} - ${response.data}');
      return response;
    } on DioException catch (e) {
      _logger.e('Dio Error: ${e.message}\n${e.response?.data}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      rethrow;
    }
  }

  static Future<Response> put(String path,
      {dynamic data, String? token}) async {
    try {
      _logger.i('PUT $path\nRequest Data: $data');
      final options = token != null
          ? Options(headers: {'Authorization': 'Bearer $token'})
          : null;
      final response = await _dio.put(path, data: data, options: options);
      _logger.i('Response: ${response.statusCode} - ${response.data}');
      return response;
    } on DioException catch (e) {
      _logger.e('Dio Error: ${e.message}\n${e.response?.data}');
      rethrow;
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      rethrow;
    }
  }
}
