import 'package:app_driver/core/api_client.dart';
import 'package:app_driver/models/route_model.dart';

class RouteService {
  final ApiClient _apiClient = ApiClient();

  Future<RouteModel> getCurrentRoute() async {
    try {
      final response = await _apiClient.client.get('/routes/current');
      return RouteModel.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener ruta: ${e.toString()}');
    }
  }

  Future<List<dynamic>> getLiquidationObservations() async {
    try {
      final response = await _apiClient.client.get('/liquidation/observed');
      // Asumiendo que retorna una lista de observaciones
      return response.data as List<dynamic>;
    } catch (e) {
      // Si falla, asumimos que no hay observaciones bloqueantes o manejamos el error silenciosamente
      return [];
    }
  }
}
