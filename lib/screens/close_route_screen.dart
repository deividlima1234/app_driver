import 'package:app_driver/models/liquidation_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_driver/providers/route_provider.dart';
import 'package:app_driver/services/liquidation_service.dart';
import 'package:app_driver/models/route_model.dart';
import 'package:intl/intl.dart';
import 'package:app_driver/widgets/app_drawer.dart';
import 'package:app_driver/widgets/no_route_placeholder.dart';

class CloseRouteScreen extends StatefulWidget {
  const CloseRouteScreen({super.key});

  @override
  State<CloseRouteScreen> createState() => _CloseRouteScreenState();
}

class _CloseRouteScreenState extends State<CloseRouteScreen> {
  final _liquidationService = LiquidationService();
  final Map<int, TextEditingController> _controllers = {};

  bool _isLoading = true; // Initial loading to check observed status
  bool _isConverting = false; // Loading during submit
  ObservedLiquidation? _observedData;
  LiquidationResponse? _successResponse;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    try {
      final observed = await _liquidationService.getObservedLiquidation();
      if (mounted) {
        setState(() {
          _observedData = observed;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fail silently or show error? For now, allow proceed if check fails
      }
    }
  }

  @override
  void dispose() {
    _controllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _submitClose(RouteModel route) async {
    setState(() => _isConverting = true);
    try {
      final List<Map<String, dynamic>> savedStock = [];

      for (var stockItem in route.stock) {
        final text = _controllers[stockItem.product.id]?.text ?? '0';
        final qty = int.tryParse(text) ?? 0;

        if (qty > stockItem.currentQuantity) {
          throw Exception(
              'Error en ${stockItem.product.name}: No puedes devolver más ($qty) de lo que tienes (${stockItem.currentQuantity})');
        }

        savedStock.add({
          'productId': stockItem.product.id,
          'quantity': qty,
        });
      }

      final response =
          await _liquidationService.closeRoute(route.id, savedStock);

      if (mounted) {
        setState(() {
          _successResponse = response;
          _isConverting = false;
        });
        // Reload route to update dashboard status if user navigates back later
        Provider.of<RouteProvider>(context, listen: false).loadCurrentRoute();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConverting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error: ${e.toString().replaceAll("Exception: ", "")}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shared AppBar Title based on state
    String title = 'Cerrar Mi Ruta';
    if (_observedData != null) title = 'Liquidación Observada';
    if (_successResponse != null) title = 'Ruta Cerrada';

    // 4. Form State (Normal Flow) needs Route
    final routeProvider = Provider.of<RouteProvider>(context);
    final route = routeProvider.currentRoute;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: const AppDrawer(),
      body: _buildBody(route),
    );
  }

  Widget _buildBody(RouteModel? route) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_observedData != null) {
      return _buildObservedState();
    }

    if (_successResponse != null) {
      return _buildSuccessState();
    }

    if (route == null) {
      return const NoRoutePlaceholder();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Info
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.local_shipping_outlined, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text("Información de Cierre",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ]),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Vehículo y Ruta",
                          style: TextStyle(color: Colors.indigo, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(route.vehicle.plate,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.indigo)),
                          const SizedBox(width: 8),
                          Text("#${route.id}",
                              style: TextStyle(
                                  fontSize: 14, color: Colors.indigo[300])),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                    "Declara la mercadería que estás devolviendo al almacén (Stock Físico). El sistema calculará tus ventas.",
                    style: TextStyle(fontSize: 13, color: Colors.grey))
              ],
            ),
          ),

          // Stock List
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 10)
                ]),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.inventory_2_outlined, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text("Inventario Retornado",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                ]),
                const SizedBox(height: 8),
                const Text(
                    "Ingresa la cantidad que regresa físicamente en el camión.",
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(height: 16),
                ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: route.stock.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final stockItem = route.stock[index];
                      final product = stockItem.product;
                      if (!_controllers.containsKey(product.id)) {
                        _controllers[product.id] =
                            TextEditingController(text: '0');
                      }
                      final controller = _controllers[product.id]!;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text('Máx: ${stockItem.currentQuantity}',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      controller.text =
                                          stockItem.currentQuantity.toString();
                                    },
                                    child: const Text("Todo",
                                        style: TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 50,
                                    child: TextField(
                                      controller: controller,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                          isDense: true,
                                          border: InputBorder.none,
                                          hintText: "0"),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    })
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConverting ? null : () => _submitClose(route),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD50000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: _isConverting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Cerrar Ruta y Liquidar',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObservedState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 80, color: Colors.orange),
          const SizedBox(height: 20),
          const Text(
            'Tu liquidación tiene observaciones',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!)),
            child: Column(
              children: [
                const Text("NOTA DEL ADMINISTRADOR:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.orange)),
                const SizedBox(height: 8),
                Text(
                  _observedData!.adminNote,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Text("Por favor, acércate a caja o contacta al administrador.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    final fmt = NumberFormat.currency(symbol: 'S/. ');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const SizedBox(height: 20),
            const Text("¡Ruta Cerrada!",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const SizedBox(height: 10),
            const Text("Entrega este efectivo a caja y espera tu confirmación.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 40),

            // Cash Card
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.green.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 5))
                  ]),
              child: Column(
                children: [
                  const Text("EFECTIVO A ENTREGAR",
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(fmt.format(_successResponse!.totalCash),
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87)),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Digital (Yape/Plin):"),
                      Text(fmt.format(_successResponse!.totalDigital),
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Items Vendidos:"),
                      Text("${_successResponse!.totalItemsSold} un.",
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Go back to dashboard
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text("Entendido, Volver al Inicio"),
              ),
            )
          ],
        ),
      ),
    );
  }
}
