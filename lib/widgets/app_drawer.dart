import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:app_driver/providers/auth_provider.dart';
import 'package:app_driver/models/auth_model.dart'; // Import User model
import 'package:app_driver/config/constants.dart';
import 'package:app_driver/screens/dashboard_screen.dart';
import 'package:app_driver/screens/map_screen.dart';
import 'package:app_driver/screens/history_screen.dart';
import 'package:app_driver/screens/close_route_screen.dart';
import 'package:app_driver/screens/field_sales_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

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

  void _showProfileModal(BuildContext context, User userBase) {
    // Trigger refresh immediately
    // Note: We use the provider without listening (listen: false) to call the method,
    // but the UI inside Consumer will rebuild when it notifies.
    context.read<AuthProvider>().refreshUser();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Use fresh user if available, otherwise fallback to passed user
          final user = auth.user ?? userBase;
          final isLoading = auth.isLoadingProfile;

          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // 1. Elegant Header with Gradient
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 140,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        ),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -0,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: () => _showImageOptions(context, auth, user),
                            child: CircleAvatar(
                              radius: 54, // Outer border
                              backgroundColor: Colors.white,
                              child: FutureBuilder<String?>(
                                  future: auth.getToken(),
                                  builder: (context, snapshot) {
                                    // Construct URL
                                    String? imageUrl = user.profilePictureUrl;
                                    if (imageUrl != null &&
                                        !imageUrl.startsWith('http')) {
                                      // Remove leading slash if present to avoid double slash,
                                      // assuming baseUrl ends with /v1 (no trailing slash usually, but let's be safe)
                                      // Actually AppConstants.baseUrl is .../api/v1
                                      // relative url from backend is /api/v1/users/...
                                      // wait, if backend returns /api/v1/users/..., and baseUrl is .../api/v1
                                      // we might duplicate /api/v1 if we just join them.
                                      // Let's assume baseUrl is the HOST part mostly if the path is full.
                                      // But AppConstants.baseUrl includes /api/v1.
                                      // If the returned URL is also /api/v1/..., we should strip it or just use the host.
                                      // Simpler: Just resolve against the base.
                                      // But base is 'https://ccalarce-backend.onrender.com/api/v1'.
                                      // user.profilePictureUrl is '/api/v1/users/15/picture'.
                                      // If we combine, we get .../api/v1/api/v1... WRONG.
                                      // We need the root host.
                                      // Hacky fix: Replace /api/v1 in baseUrl with empty to get host, or just parse Uri.

                                      final uri =
                                          Uri.parse(AppConstants.baseUrl);
                                      final host =
                                          "${uri.scheme}://${uri.host}"; // e.g. https://ccalarce-backend.onrender.com
                                      imageUrl = "$host$imageUrl";
                                    }

                                    return CircleAvatar(
                                      radius: 50,
                                      backgroundColor: const Color(0xFFE3F2FD),
                                      backgroundImage:
                                          (imageUrl != null && snapshot.hasData)
                                              ? CachedNetworkImageProvider(
                                                  imageUrl,
                                                  headers: {
                                                    'Authorization':
                                                        'Bearer ${snapshot.data}'
                                                  },
                                                )
                                              : null,
                                      child: user.profilePictureUrl == null
                                          ? Text(
                                              (user.fullName ??
                                                      user.username)[0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                  fontSize: 40,
                                                  color: Color(0xFF1565C0),
                                                  fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    );
                                  }),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: const Icon(Icons.camera_alt,
                                size: 20, color: Color(0xFF1565C0)),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Main Info
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  ),

                Text(
                  user.fullName ?? user.username,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Text(
                    user.roles.isNotEmpty ? user.roles.first : 'Conductor',
                    style: const TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. User Details Cards
                Expanded(
                  child: Container(
                    color: Colors.grey[50],
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      children: [
                        _buildSectionHeader("INFORMACIÓN PERSONAL"),
                        _buildInfoCard([
                          _buildInfoRow(Icons.person_outline,
                              "Nombre de Usuario", user.username),
                          const Divider(height: 1, indent: 50),
                          _buildInfoRow(Icons.badge_outlined, "ID de Empleado",
                              "#${user.id}"),
                        ]),
                        const SizedBox(height: 20),
                        _buildSectionHeader("ESTADO DE CUENTA"),
                        _buildInfoCard([
                          _buildInfoRow(
                            Icons.verified_user_outlined,
                            "Estado",
                            user.active ? "Activo" : "Inactivo",
                            valueColor:
                                user.active ? Colors.green[700] : Colors.red,
                          ),
                          if (user.createdAt != null) ...[
                            const Divider(height: 1, indent: 50),
                            _buildInfoRow(
                                Icons.calendar_today_outlined,
                                "Miembro desde",
                                DateFormat('MMM yyyy').format(user.createdAt!)),
                          ]
                        ]),
                      ],
                    ),
                  ),
                ),

                // 4. Close Button area
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Cerrar",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF757575),
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF616161)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF757575))),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? const Color(0xFF212121))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageOptions(BuildContext context, AuthProvider auth, User user) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          if (user.profilePictureUrl != null)
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: const Text('Ver foto de perfil'),
              onTap: () {
                Navigator.pop(ctx);
                _viewProfilePicture(context, auth, user);
              },
            ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Tomar foto'),
            onTap: () async {
              Navigator.pop(ctx);
              _handleImageSelection(context, auth, ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text(
                'Multimedia'), // 'Galería' renamed per request or style
            onTap: () async {
              Navigator.pop(ctx);
              _handleImageSelection(context, auth, ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleImageSelection(
      BuildContext context, AuthProvider auth, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: source);
    if (photo != null && context.mounted) {
      _uploadImage(context, auth, File(photo.path));
    }
  }

  void _viewProfilePicture(BuildContext context, AuthProvider auth, User user) {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<String?>(
          future: auth.getToken(),
          builder: (context, snapshot) {
            String? imageUrl = user.profilePictureUrl;
            if (imageUrl != null && !imageUrl.startsWith('http')) {
              final uri = Uri.parse(AppConstants.baseUrl);
              final host = "${uri.scheme}://${uri.host}";
              imageUrl = "$host$imageUrl";
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Imagen con Zoom
                  InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4,
                    child: Container(
                      width: double.infinity,
                      height: 400, // Fixed height or adjust
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                        image: (imageUrl != null && snapshot.hasData)
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(
                                  imageUrl,
                                  headers: {
                                    'Authorization': 'Bearer ${snapshot.data}'
                                  },
                                ),
                                fit: BoxFit.contain,
                              )
                            : null,
                      ),
                    ),
                  ),

                  // Footer Profesional
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5))
                          ]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user.fullName ?? user.username,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFF0D47A1),
                                borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              user.roles.isNotEmpty
                                  ? user.roles.first
                                  : 'Conductor',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  // Close Button
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 30),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  )
                ],
              ),
            );
          }),
    );
  }

  Future<void> _uploadImage(
      BuildContext context, AuthProvider auth, File file) async {
    try {
      await auth.uploadProfilePicture(file);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir imagen: $e')),
        );
      }
    }
  }

  void _showAboutModal(BuildContext context) {
    Future.microtask(() async {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!context.mounted) return;

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
              Text(
                'Versión ${packageInfo.version}',
                style: const TextStyle(color: Colors.grey),
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
    });
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
