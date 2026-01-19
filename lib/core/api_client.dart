import 'package:dio/dio.dart';
import 'package:app_driver/config/constants.dart';
import 'package:app_driver/core/storage_manager.dart';

class ApiClient {
  late Dio _dio;
  final StorageManager _storageManager = StorageManager();

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storageManager.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Aquí se puede manejar errores globales (ej: 401 Logout)
        if (e.response?.statusCode == 401) {
          // TODO: Implementar lógica de logout automático
        }
        return handler.next(e);
      },
    ));
  }

  Dio get client => _dio;
}
