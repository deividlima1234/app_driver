import 'package:app_driver/core/api_client.dart';
import 'package:app_driver/models/sales_model.dart';

class SalesService {
  final ApiClient _apiClient = ApiClient();

  Future<List<Client>> getClients() async {
    try {
      final response = await _apiClient.client.get('/clients');
      return (response.data as List).map((e) => Client.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error al cargar clientes: $e');
    }
  }

  Future<void> registerSale(SaleRequest request) async {
    try {
      await _apiClient.client.post('/sales', data: request.toJson());
    } catch (e) {
      throw Exception('Error al registrar venta: $e');
    }
  }

  Future<List<dynamic>> getTodaysSales() async {
    try {
      final response = await _apiClient.client.get('/sales/my-sales');
      // Asumiendo que retorna una lista de ventas
      return response.data as List<dynamic>;
    } catch (e) {
      // print('Error fetching history: $e'); // Error ignored
      return [];
    }
  }

  Future<void> linkQrToClient(int clientId, String qrCode) async {
    try {
      await _apiClient.client.put('/clients/$clientId', data: {
        'tokenQr': {'code': qrCode}
      });
    } catch (e) {
      throw Exception('Error al vincular QR: $e');
    }
  }

  Future<Map<String, dynamic>> validateQr(String code) async {
    try {
      final response = await _apiClient.client.get('/tokens/$code');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Error al validar QR: $e');
    }
  }
}
