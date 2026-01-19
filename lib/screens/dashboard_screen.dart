import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:app_driver/providers/auth_provider.dart';
import 'package:app_driver/providers/route_provider.dart';
import 'package:app_driver/widgets/product_card.dart';
import 'package:app_driver/screens/field_sales_screen.dart';
import 'package:app_driver/screens/close_route_screen.dart';
import 'package:app_driver/widgets/app_drawer.dart';
import 'package:app_driver/widgets/no_route_placeholder.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar ruta al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RouteProvider>(context, listen: false).loadCurrentRoute();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);

    // Lógica de redirección automática si hay observaciones
    if (routeProvider.hasLiquidationObservation && !routeProvider.isLoading) {
      // Podríamos navegar automáticamente, pero mejor mostramos una pantalla de bloqueo explícita
      // para que el usuario entienda qué pasa. El diseño actual maneja esto en el body.
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Ruta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => routeProvider.loadCurrentRoute(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: routeProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : routeProvider.hasLiquidationObservation
              ? _buildLiquidationAlert(context)
              : routeProvider.currentRoute == null
                  ? _buildNoRouteState(context, routeProvider)
                  : _buildDashboardContent(context, routeProvider),
    );
  }

  Widget _buildLiquidationAlert(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded,
                size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            Text(
              'Liquidación Observada',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tu última liquidación tiene observaciones pendientes. Debes corregirlas para continuar.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CloseRouteScreen()),
                );
              },
              icon: const Icon(Icons.edit_document),
              label: const Text('IR A CORREGIR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNoRouteState(BuildContext context, RouteProvider provider) {
    return const NoRoutePlaceholder();
  }

  Widget _buildDashboardContent(BuildContext context, RouteProvider provider) {
    final route = provider.currentRoute!;
    final dateFormat = DateFormat('HH:mm a');

    return Column(
      children: [
        // Header Card
        Card(
          margin: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor,
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.driver.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Inicio: ${route.openedAt != null ? dateFormat.format(route.openedAt!) : "--:--"}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white54)),
                      child: Text(
                        route.status,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 24),
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${route.vehicle.brand} ${route.vehicle.model}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        Text(
                          route.vehicle.plate,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Título Inventario
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Inventario a Bordo',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Lista de Inventario
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: route.stock.length,
            itemBuilder: (context, index) {
              final stockItem = route.stock[index];
              return ProductCard(stockItem: stockItem);
            },
          ),
        ),

        // Botones de Acción
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FieldSalesScreen()),
                    );
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('VENTA'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CloseRouteScreen()),
                    );
                  },
                  icon: const Icon(Icons.assignment_return),
                  label: const Text('LIQUIDAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey[800],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
