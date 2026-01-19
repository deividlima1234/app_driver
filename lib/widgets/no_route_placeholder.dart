import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_driver/providers/auth_provider.dart';
import 'package:app_driver/providers/route_provider.dart';

class NoRoutePlaceholder extends StatelessWidget {
  const NoRoutePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    // Get user from auth provider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);

    final user = authProvider.user;
    final name = user?.fullName ?? user?.username ?? 'Conductor';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.no_transfer, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Hola, $name',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tu ruta no está activa',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              routeProvider.error ??
                  'Regresa más tarde o contacta a tu supervisor para asignación.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => routeProvider.loadCurrentRoute(),
              child: const Text('Actualizar Estado'),
            ),
          ],
        ),
      ),
    );
  }
}
