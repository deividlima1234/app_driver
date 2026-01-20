import 'dart:io';
import 'package:dio/dio.dart';
import 'package:app_driver/core/api_client.dart';
import 'package:app_driver/models/auth_model.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  Future<AuthResponse> login(String username, String password) async {
    try {
      final response = await _apiClient.client.post(
        '/auth/authenticate',
        data: {
          'username': username,
          'password': password,
        },
      );

      return AuthResponse.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 403) {
          throw Exception('Credenciales inválidas');
        } else {
          throw Exception('Error de conexión: ${e.message}');
        }
      }
      rethrow;
    }
  }

  Future<User> getMe() async {
    try {
      final response = await _apiClient.client.get('/users/me');
      return User.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener perfil: ${e.toString()}');
    }
  }

  Future<void> uploadProfilePicture(File file) async {
    try {
      String fileName = file.path.split('/').last;

      // Determine content type roughly or just let Dio handle it/default
      // Ideally use mime package but simple filename usually works for servers

      FormData formData = FormData.fromMap({
        // 'file' key as requested
        "file": await MultipartFile.fromFile(file.path, filename: fileName),
      });

      await _apiClient.client.post(
        '/users/me/picture',
        data: formData,
        // Content-Type multipart is handled automatically by Dio when passing FormData
      );
    } catch (e) {
      throw Exception('Error al subir imagen: ${e.toString()}');
    }
  }
}
