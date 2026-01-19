import 'package:flutter/material.dart';
import 'package:app_driver/models/sales_model.dart';
import 'package:app_driver/services/sales_service.dart';

class SalesProvider extends ChangeNotifier {
  final SalesService _salesService = SalesService();

  List<Client> _clients = [];
  List<dynamic> _todaysSales = []; // Lista de ventas de hoy
  bool _isLoading = false;

  List<Client> get clients => _clients;
  List<dynamic> get todaysSales => _todaysSales;
  bool get isLoading => _isLoading;

  Future<void> loadClients() async {
    _isLoading = true;
    notifyListeners();
    try {
      _clients = await _salesService.getClients();
    } catch (e) {
      // print('Provider Error Clients: $e'); // Debugging enabled
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTodaysSales() async {
    try {
      _todaysSales = await _salesService.getTodaysSales();
      notifyListeners();
    } catch (e) {
      // print(e); // Error ignored
    }
  }

  Future<void> makeSale(SaleRequest request) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _salesService.registerSale(request);
      // Recargar historial después de venta exitosa
      await loadTodaysSales();
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> linkQrToClient(int clientId, String qrCode) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _salesService.linkQrToClient(clientId, qrCode);
      await loadClients(); // Reload to get updated QR
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> validateQr(String code) async {
    try {
      return await _salesService.validateQr(code);
    } catch (e) {
      rethrow;
    }
  }
}
