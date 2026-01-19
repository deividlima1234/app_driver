import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_driver/providers/auth_provider.dart';
import 'package:app_driver/models/auth_model.dart'; // Import User model
import 'package:app_driver/screens/dashboard_screen.dart';
import 'package:app_driver/screens/map_screen.dart';
import 'package:app_driver/screens/history_screen.dart';
import 'package:app_driver/screens/close_route_screen.dart';
import 'package:app_driver/screens/field_sales_screen.dart';
import 'package:intl/intl.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Drawer(
      child: Column(
        children: [
          // 1. Header (Simplificado - Branding)
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF0D47A1),
              image: DecorationImage(
                  image: AssetImage('assets/images/header_bg.png'),
                  fit: BoxFit.cover,
                  opacity: 0.2),
            ),
            child: Container(
              alignment: Alignment.bottomLeft,
              child: const Row(
                children: [
                  Icon(Icons.local_shipping_rounded,
                      color: Colors.white, size: 40),
                  SizedBox(width: 12),
                  Text(
                    'SIGLO-F',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // 2. Navigation Items (Scrollable)
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(context, Icons.dashboard, 'Mi Ruta',
                    () => const DashboardScreen()),
                _buildNavItem(context, Icons.shopping_cart, 'Vender',
                    () => const FieldSalesScreen()),
                _buildNavItem(context, Icons.map, 'Geo. Clientes',
                    () => const MapScreen()),
                _buildNavItem(context, Icons.lock_clock, 'Cerrar Ruta',
                    () => const CloseRouteScreen()),
                _buildNavItem(context, Icons.history, 'Historial Liquidaciones',
                    () => const LiquidationHistoryScreen()),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.info_outline, color: Colors.blueGrey),
                  title: const Text('Acerca de',
                      style: TextStyle(color: Colors.blueGrey)),
                  onTap: () => _showAboutModal(context),
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: Colors.red),
                  title: const Text('Cerrar Sesión',
                      style: TextStyle(color: Colors.red)),
                  onTap: () => _confirmLogout(context, authProvider),
                ),
              ],
            ),
          ),

          // 3. User Profile Footer
          if (user != null) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () => _showProfileModal(context, user),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                color: Colors.grey[50], // Slight contrast
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF1E88E5),
                      child: Text(
                        (user.fullName ?? user.username)[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName ?? user.username,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user.roles.isNotEmpty
                                ? user.roles.first
                                : 'Conductor',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title,
      Widget Function() page) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: TextStyle(color: Colors.grey[800])),
      onTap: () {
        // Use pushReplacement to ensure the drawer is always accessible from the new root
        // and we don't build a huge stack of identical pages.
        Navigator.pop(context); // Close drawer first animation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => page()),
        );
      },
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro que deseas salir?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Close dialog
              authProvider.logout();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (route) => false);
            },
            child: const Text('Salir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProfileModal(BuildContext context, User user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle for drag
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: const Color(0xFF1E88E5),
                    child: Text(
                      (user.fullName ?? user.username)[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user.fullName ?? user.username,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Text(
                      user.roles.isNotEmpty ? user.roles.first : 'Conductor',
                      style: TextStyle(
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),

            // Details List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text("INFORMACIÓN DE CUENTA",
                      style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  _buildDetailTile(
                      Icons.perm_identity, "ID de Usuario", "#${user.id}"),
                  _buildDetailTile(
                      Icons.person_outline, "Nombre de Usuario", user.username),
                  _buildDetailTile(Icons.badge_outlined, "Nombre Completo",
                      user.fullName ?? "No registrado"),
                  _buildDetailTile(Icons.verified_user_outlined, "Estado",
                      user.active ? "Activo" : "Inactivo",
                      color: user.active ? Colors.green : Colors.red),
                  if (user.createdAt != null)
                    _buildDetailTile(
                        Icons.calendar_month_outlined,
                        "Fecha de Registro",
                        DateFormat('dd/MM/yyyy • hh:mm a')
                            .format(user.createdAt!)),
                ],
              ),
            ),

            // Footer Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Cerrar"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value,
      {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color ?? Colors.black87)),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showAboutModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Icon(Icons.local_shipping_rounded,
                size: 48, color: Color(0xFF0D47A1)),
            const SizedBox(height: 16),
            const Text(
              'SIGLO-F Driver',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Versión 1.0.0',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            _buildCreditRow("Desarrollado por", "Eddam Eloy"),
            const SizedBox(height: 12),
            _buildCreditRow("Corporación", "EddamCore © 2026"),
            const SizedBox(height: 40),
            const Text(
              "Todos los derechos reservados",
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
