import 'package:app_driver/core/api_client.dart';
import 'package:app_driver/models/liquidation_model.dart';
import 'package:dio/dio.dart';

class LiquidationService {
  final ApiClient _apiClient = ApiClient();

  Future<LiquidationResponse> closeRoute(
      int routeId, List<Map<String, dynamic>> savedStock) async {
    try {
      final response = await _apiClient.client.post(
        '/liquidation/close',
        data: {
          'routeId': routeId,
          'savedStock': savedStock,
        },
      );
      return LiquidationResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al cerrar ruta: ${e.toString()}');
    }
  }

  Future<ObservedLiquidation?> getObservedLiquidation() async {
    try {
      final response = await _apiClient.client.get('/liquidation/observed');
      if (response.statusCode == 204 || response.data == null) {
        return null;
      }
      // Assuming endpoint returns a single object if observed, or 204/empty if none
      // If it returns a list, take the first one
      if (response.data is List && (response.data as List).isNotEmpty) {
        return ObservedLiquidation.fromJson(response.data[0]);
      } else if (response.data is Map<String, dynamic>) {
        return ObservedLiquidation.fromJson(response.data);
      }
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return null;
      }
      // throw Exception('Error checking observation: ${e.toString()}');
      return null; // Fail safe to allow normal flow if check fails
    }
  }

  Future<LiquidationPage> getHistory({
    int page = 0,
    int size = 10,
    String? status,
    String? startDate,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'size': size,
      };
      if (status != null && status != 'Todos') queryParams['status'] = status;
      if (startDate != null) queryParams['startDate'] = startDate;

      final response = await _apiClient.client
          .get('/liquidation/history', queryParameters: queryParams);
      return LiquidationPage.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener historial: ${e.toString()}');
    }
  }
}
