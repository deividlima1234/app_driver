import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_driver/providers/sales_provider.dart';
import 'package:app_driver/models/sales_model.dart';
import 'package:app_driver/providers/route_provider.dart';
import 'package:app_driver/widgets/app_drawer.dart';
import 'package:app_driver/widgets/no_route_placeholder.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final LatLng _initialPosition = const LatLng(-12.046374, -77.042793);
  final MapController _mapController = MapController();

  // Filters
  String _searchQuery = '';
  String? _selectedZone;
  final Set<String> _selectedStatuses = {
    'ACTIVO',
    'FRECUENTE',
    'ALERTA'
  }; // All selected by default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesProvider>(context, listen: false).loadClients();
    });
  }

  // --- Helpers ---
  void _fitClientBounds(List<Client> clients) {
    if (clients.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(
      clients
          .where((c) => c.latitude != null && c.longitude != null)
          .map((c) => LatLng(c.latitude!, c.longitude!))
          .toList(),
    );

    _mapController.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(50),
    ));
  }

  Color _getMarkerColor(String status) {
    switch (status) {
      case 'FRECUENTE':
        return Colors.green;
      case 'ALERTA':
        return Colors.red;
      default:
        return Colors.blue; // ACTIVO
    }
  }

  List<Client> _getFilteredClients(List<Client> allClients) {
    return allClients.where((client) {
      // 1. Geolocation check
      if (client.latitude == null || client.longitude == null) return false;

      // 2. Status Filter
      if (!_selectedStatuses.contains(client.commercialStatus)) return false;

      // 3. Zone Filter
      if (_selectedZone != null && client.zone != _selectedZone) return false;

      // 4. Search Filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final name = client.name.toLowerCase();
        // final document = client.documentNumber?.toString() ?? ''; // Add fields if needed
        if (!name.contains(query)) return false;
      }

      return true;
    }).toList();
  }

  // --- Navigation ---
  Future<void> _launchNavigation(double lat, double lng) async {
    final googleMapsUrl = Uri.parse("google.navigation:q=$lat,$lng&mode=d");
    final wazeUrl = Uri.parse("waze://?ll=$lat,$lng&navigate=yes");

    try {
      if (await canLaunchUrl(wazeUrl)) {
        await launchUrl(wazeUrl);
      } else if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl);
      } else {
        final webUrl = Uri.parse(
            "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng");
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al abrir mapas: $e')));
      }
    }
  }

  // --- UI Components ---
  void _showClientDetails(Client client) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        client.name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child:
                          const Icon(Icons.close, color: Colors.grey, size: 20),
                    )
                  ],
                ),
                const Divider(height: 24),
                _buildDetailRow("DNI/RUC:", client.ruc ?? "No registrado"),
                const SizedBox(height: 8),
                _buildDetailRow("Zona:", client.zone ?? "Sin zona"),
                const SizedBox(height: 8),
                _buildDetailRow(
                    "Dirección:", client.address ?? "Sin dirección"),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!)),
                  child: Row(
                    children: [
                      Text("QR: ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700])),
                      Expanded(
                        child: Text(
                          client.qrCode ?? "Sin QR vinculado",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: 'monospace', color: Colors.grey[800]),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors
                        .grey[600], // Default grey for ACTIVO based on image
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    client.commercialStatus,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("📎 NAVEGAR CON:",
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _launchNavigation(
                            client.latitude!,
                            client
                                .longitude!), // Opens selector, or specific if tweaked
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                                0xFF4C3AE3), // Purple/Blue like Google Maps in image
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: const Text("Google Maps",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final wazeUrl = Uri.parse(
                              "waze://?ll=${client.latitude},${client.longitude}&navigate=yes");
                          if (await canLaunchUrl(wazeUrl)) {
                            await launchUrl(wazeUrl);
                          } else {
                            messenger.showSnackBar(const SnackBar(
                                content: Text("Waze no instalado")));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF00D6EA), // Cyan like Waze
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: const Text("Waze",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return RichText(
      text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
                text: "$label ",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            TextSpan(text: value),
          ]),
    );
  }

  void _showFilterModal(List<String> availableZones) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),

                // Zona
                const Text('ZONA',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blueGrey)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text('Todas las Zonas'),
                      value: _selectedZone,
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Todas las Zonas')),
                        ...availableZones.map(
                            (z) => DropdownMenuItem(value: z, child: Text(z)))
                      ],
                      onChanged: (val) {
                        setModalState(() => _selectedZone = val);
                        setState(() {});
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Status Checkboxes
                const Text('ESTADO COMERCIAL',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blueGrey)),
                const SizedBox(height: 8),
                _buildStatusCheckbox(
                    'ACTIVO', 'Activo (Estándar)', Colors.grey, setModalState),
                _buildStatusCheckbox('FRECUENTE', 'Frecuente (VIP)',
                    Colors.green, setModalState),
                _buildStatusCheckbox(
                    'ALERTA', 'Alerta (Deuda)', Colors.red, setModalState),

                const SizedBox(height: 24),

                // Search QR (Placeholder per image)
                const Text('BUSCAR QR',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blueGrey)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    hintText: 'Escanee o escriba código...',
                    hintStyle: const TextStyle(fontFamily: 'monospace'),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                  ),
                  // Currently just placeholder logic, can bind if needed
                ),

                const SizedBox(height: 24),

                // Search Client
                const Text('BUSCAR CLIENTE',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blueGrey)),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Nombre o DNI...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!)),
                  ),
                  onChanged: (val) {
                    setModalState(() => _searchQuery = val);
                    setState(() {}); // Update parent
                  },
                  controller: TextEditingController(text: _searchQuery),
                ),

                const Spacer(),

                // Limpiar Filtros
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setModalState(() {
                        _searchQuery = '';
                        _selectedZone = null;
                        _selectedStatuses
                            .addAll(['ACTIVO', 'FRECUENTE', 'ALERTA']);
                      });
                      setState(() {});
                    },
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    label: const Text('Limpiar Filtros',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCheckbox(
      String status, String label, Color color, StateSetter setModalState) {
    final isSelected = _selectedStatuses.contains(status);
    return InkWell(
      onTap: () {
        setModalState(() {
          if (isSelected) {
            if (_selectedStatuses.length > 1) _selectedStatuses.remove(status);
          } else {
            _selectedStatuses.add(status);
          }
        });
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  border:
                      Border.all(color: isSelected ? Colors.blue : Colors.grey),
                  borderRadius: BorderRadius.circular(4)),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Container(
                width: 12,
                height: 12,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(fontSize: 16, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);

    // Block if no route
    if (routeProvider.currentRoute == null ||
        routeProvider.currentRoute!.status == 'CLOSED') {
      return Scaffold(
        appBar: AppBar(title: const Text('Geo. Clientes')),
        drawer: const AppDrawer(),
        body: const NoRoutePlaceholder(),
      );
    }

    final salesProvider = Provider.of<SalesProvider>(context);
    final filteredClients = _getFilteredClients(salesProvider.clients);

    // Auto-fit bounds when clients load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (filteredClients.isNotEmpty && salesProvider.clients.isNotEmpty) {
        // Only fit if we haven't manipulated map manually yet? Simple version:
        // _fitClientBounds(filteredClients);
      }
    });

    // Extract available zones
    final zones = salesProvider.clients
        .map((c) => c.zone)
        .where((z) => z != null)
        .toSet()
        .cast<String>()
        .toList();
    zones.sort();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Geo. Clientes',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white.withOpacity(0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              Provider.of<SalesProvider>(context, listen: false).loadClients();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Actualizando clientes y mapa...')),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text('${filteredClients.length} visible(s)'),
              backgroundColor: Colors.blue[50],
              labelStyle: const TextStyle(
                  color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFilterModal(zones),
        icon: const Icon(Icons.filter_list, color: Colors.white),
        label: const Text("Filtros", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      body: salesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialPosition,
                initialZoom: 13.0,
                onMapReady: () {
                  if (salesProvider.clients.isNotEmpty) {
                    _fitClientBounds(salesProvider.clients);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}@2x.png', // CartoDB Positron (High Res)
                  userAgentPackageName: 'com.example.app_driver',
                  tileProvider: CachedTileProvider(),
                ),
                MarkerLayer(
                  markers: filteredClients.map((client) {
                    return Marker(
                      point: LatLng(client.latitude!, client.longitude!),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () => _showClientDetails(client),
                        child: Container(
                          decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4)
                              ]),
                          child: Icon(
                            Icons.location_on,
                            color: _getMarkerColor(client.commercialStatus),
                            size: 32,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}

class CachedTileProvider extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return CachedNetworkImageProvider(
      getTileUrl(coordinates, options),
    );
  }
}
