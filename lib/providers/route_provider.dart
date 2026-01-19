import 'package:flutter/material.dart';
import 'package:app_driver/models/route_model.dart';
import 'package:app_driver/services/route_service.dart';

class RouteProvider extends ChangeNotifier {
  final RouteService _routeService = RouteService();

  RouteModel? _currentRoute;
  bool _isLoading = false;
  String? _error;
  bool _hasLiquidationObservation = false;

  RouteModel? get currentRoute => _currentRoute;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasLiquidationObservation => _hasLiquidationObservation;

  Future<void> loadCurrentRoute() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentRoute = await _routeService.getCurrentRoute();
      _hasLiquidationObservation = false; // Si carga ruta, todo OK
    } catch (e) {
      // Si falla cargar ruta, verificamos si es por tema de liquidación
      // print('Error loading route: $e'); // Debug removed

      try {
        final observations = await _routeService.getLiquidationObservations();
        if (observations.isNotEmpty) {
          _hasLiquidationObservation = true;
          _currentRoute = null;
        } else {
          _error = "No se pudo cargar la ruta activa. Contacte a soporte.";
          _currentRoute = null;
        }
      } catch (obsError) {
        // Si fallan ambos
        _error = "Error de conexión. No se pudo verificar el estado.";
        _currentRoute = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Método para actualizar stock localmente después de una venta (optimistic update)
  void updateLocalStock(int productId, int quantitySold) {
    if (_currentRoute != null) {
      // Buscamos el StockItem que contiene el producto con ese ID
      final itemIndex = _currentRoute!.stock
          .indexWhere((item) => item.product.id == productId);

      if (itemIndex != -1) {
        _currentRoute!.stock[itemIndex].currentQuantity -= quantitySold;
        notifyListeners();
      }
    }
  }
}
