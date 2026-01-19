import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:app_driver/providers/sales_provider.dart';
import 'package:app_driver/models/sales_model.dart';
import 'package:app_driver/providers/route_provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_driver/widgets/app_drawer.dart';
import 'package:app_driver/widgets/no_route_placeholder.dart';
import 'package:app_driver/screens/qr_scanner_screen.dart';

class FieldSalesScreen extends StatefulWidget {
  const FieldSalesScreen({super.key});

  @override
  State<FieldSalesScreen> createState() => _FieldSalesScreenState();
}

class _FieldSalesScreenState extends State<FieldSalesScreen> {
  // GPS
  // final MapController _mapController = MapController(); // Unused
  // final LatLng _initialPosition = const LatLng(-12.046374, -77.042793); // Unused
  LatLng? _currentLocation;
  bool _gpsServiceEnabled = false;

  // Form State
  Client? _selectedClient;
  final Map<int, int> _quantities = {}; // ProductID -> Quantity
  String _paymentMethod = 'CASH'; // CASH, YAPE, PLIN, CREDIT

  @override
  void initState() {
    super.initState();
    _checkGps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesProvider>(context, listen: false).loadClients();
      Provider.of<SalesProvider>(context, listen: false).loadTodaysSales();
    });
  }

  // --- GPS ---
  Future<void> _checkGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    setState(() => _gpsServiceEnabled = serviceEnabled);
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {}
  }

  // --- Actions ---
  void _updateQuantity(int productId, int delta, int maxStock) {
    setState(() {
      int current = _quantities[productId] ?? 0;
      int next = current + delta;
      if (next < 0) next = 0;
      if (next > maxStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No hay suficiente stock'),
              duration: Duration(milliseconds: 500)),
        );
        return;
      }
      if (next == 0) {
        _quantities.remove(productId);
      } else {
        _quantities[productId] = next;
      }
    });
  }

  Future<void> _submitSale() async {
    if (_selectedClient == null || _quantities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione cliente y productos')),
      );
      return;
    }

    // Prepare Items
    List<SaleItem> items = [];
    _quantities.forEach((pid, qty) {
      items.add(SaleItem(productId: pid, quantity: qty));
    });

    final request = SaleRequest(
      routeId:
          Provider.of<RouteProvider>(context, listen: false).currentRoute!.id,
      clientId: _selectedClient!.id,
      paymentMethod: _paymentMethod,
      latitude: _currentLocation?.latitude ?? 0.0,
      longitude: _currentLocation?.longitude ?? 0.0,
      items: items,
    );

    try {
      await Provider.of<SalesProvider>(context, listen: false)
          .makeSale(request);

      // Update local stock
      if (!mounted) return;
      final routeProvider = Provider.of<RouteProvider>(context, listen: false);
      for (var item in items) {
        routeProvider.updateLocalStock(item.productId, item.quantity);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta registrada con éxito')),
        );
        setState(() {
          _quantities.clear();
          _selectedClient = null;
          _paymentMethod = 'CASH';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  // --- QR Logic ---
  // State for new card linking
  String? _pendingQrCode;

  Future<void> _startScan() async {
    final code = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (code != null && code is String) {
      _processScannedCode(code);
    }
  }

  Future<void> _processScannedCode(String code) async {
    // Navigator.pop(context); // Scanner screen already popped
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);

    try {
      // 1. Validate Token with Backend
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Validando código...'),
          duration: Duration(seconds: 1)));

      final tokenData = await salesProvider.validateQr(code);
      final status = tokenData['status'];

      if (status == 'ASIGNADO') {
        // Flow A: Auto-complete
        final clientData = tokenData['client'];
        if (clientData != null) {
          final clientId = clientData['id'];
          try {
            // Find in local list
            final localClient =
                salesProvider.clients.firstWhere((c) => c.id == clientId);
            setState(() {
              _selectedClient = localClient;
              _pendingQrCode = null; // Clear any pending
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cliente identificado: ${localClient.name}'),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          } catch (e) {
            // Client not in local list (maybe different route?)
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Este QR pertenece a un cliente fuera de tu lista.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }
      } else if (status == 'DISPONIBLE') {
        // Flow B: New Card (Link)
        setState(() {
          _pendingQrCode = code;
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Row(children: [
                Icon(Icons.credit_card, color: Colors.blue),
                SizedBox(width: 8),
                Text("Tarjeta Nueva Detectada")
              ]),
              content: const Text(
                  "Este código QR está disponible. Por favor, selecciona un cliente en la pantalla y presiona 'Vincular Tarjeta'."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Entendido"))
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Estado de QR desconocido: $status'),
                backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error al validar QR: $e"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _linkPendingQr() async {
    if (_selectedClient == null || _pendingQrCode == null) return;

    try {
      await Provider.of<SalesProvider>(context, listen: false)
          .linkQrToClient(_selectedClient!.id, _pendingQrCode!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("¡Tarjeta vinculada exitosamente!"),
            backgroundColor: Colors.green),
      );

      // Refresh local client to show checkmark
      final updatedClient = Provider.of<SalesProvider>(context, listen: false)
          .clients
          .firstWhere((c) => c.id == _selectedClient!.id);

      setState(() {
        _selectedClient = updatedClient;
        _pendingQrCode = null; // Clear pending after success
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error al vincular: $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  // --- UI Components ---
  Widget _buildClientSection(SalesProvider salesProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1. Seleccionar Cliente',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[900],
                      ),
                ),
                ElevatedButton.icon(
                  onPressed: _startScan,
                  icon: const Icon(Icons.qr_code_scanner, size: 16),
                  label: const Text('Escanear QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF1E1E2C), // Dark color from image
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),

            // Pending QR Banner
            if (_pendingQrCode != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  children: [
                    const Row(children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text(
                              "Tarjeta Nueva Detectada. Selecciona un cliente para vincularla.",
                              style: TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold)))
                    ]),
                    if (_selectedClient != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _linkPendingQr,
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue),
                            child: Text("Vincular a ${_selectedClient!.name}",
                                style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                      )
                  ],
                ),
              ),

            DropdownButtonFormField<Client>(
              decoration: const InputDecoration(
                hintText: 'Seleccione cliente...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              isExpanded: true,
              value: _selectedClient,
              items: salesProvider.clients.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(c.name, overflow: TextOverflow.ellipsis),
                      if (c.qrCode != null)
                        const Row(
                          children: [
                            SizedBox(width: 8),
                            Icon(Icons.qr_code_2,
                                color: Colors.green, size: 20),
                          ],
                        )
                    ],
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedClient = v),
            ),

            // Linked Status or Reset
            if (_selectedClient != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(children: [
                  if (_selectedClient!.qrCode != null) ...[
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text("Tiene tarjeta vinculada",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                  ] else ...[
                    const Icon(Icons.circle_outlined,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("No tiene tarjeta vinculada",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]))
                  ]
                ]),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection(RouteProvider routeProvider) {
    final stockItems = routeProvider.currentRoute?.stock ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2. Productos en Camión',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[900],
                  ),
            ),
            const SizedBox(height: 16),
            if (stockItems.isEmpty)
              const Center(child: Text('No hay stock disponible')),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stockItems.length,
              separatorBuilder: (ctx, i) => const Divider(),
              itemBuilder: (ctx, i) {
                final item = stockItems[i];
                final qty = _quantities[item.product.id] ?? 0;

                return Row(
                  children: [
                    // Product Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.product.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                  'S/. ${item.product.price.toStringAsFixed(2)}',
                                  style: TextStyle(color: Colors.grey[700])),
                              const SizedBox(width: 8),
                              Text('• Stock: ${item.currentQuantity}',
                                  style: TextStyle(
                                      color: item.currentQuantity < 5
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.w500)),
                            ],
                          )
                        ],
                      ),
                    ),
                    // Controls
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300)),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            color: Colors.blue,
                            onPressed: () => _updateQuantity(
                                item.product.id, -1, item.currentQuantity),
                            constraints: const BoxConstraints(
                                minHeight: 36, minWidth: 36),
                            padding: EdgeInsets.zero,
                          ),
                          Container(
                            width: 30,
                            alignment: Alignment.center,
                            child: Text('$qty',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            color: Colors.blue,
                            onPressed: () => _updateQuantity(
                                item.product.id, 1, item.currentQuantity),
                            constraints: const BoxConstraints(
                                minHeight: 36, minWidth: 36),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    )
                  ],
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryPanel(
      RouteProvider routeProvider, SalesProvider salesProvider) {
    // Calculate Total
    double total = 0;
    int itemsCount = 0;
    _quantities.forEach((pid, qty) {
      final stockItem = routeProvider.currentRoute?.stock.firstWhere(
          (s) => s.product.id == pid,
          orElse: () => throw Exception('Product not found'));
      if (stockItem != null) {
        total += stockItem.product.price * qty;
        itemsCount += qty;
      }
    });

    return Card(
      elevation: 4,
      color: const Color(0xFF0F111A), // Dark background
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.credit_card, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Resumen',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items', style: TextStyle(color: Colors.grey)),
                Text('$itemsCount un.',
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.grey),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                Text('S/. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Método de Pago',
                style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: ['CASH', 'YAPE', 'PLIN', 'CREDIT'].map((method) {
                final isSelected = _paymentMethod == method;
                final label = method == 'CASH'
                    ? 'EFECTIVO'
                    : (method == 'CREDIT' ? 'CRÉDITO' : method);

                return InkWell(
                  onTap: () => setState(() => _paymentMethod = method),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4C6EF5)
                            : const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color:
                                isSelected ? Colors.blue : Colors.transparent)),
                    child: Text(label,
                        style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: salesProvider.isLoading ? null : _submitSale,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600], // Muted grey in mockup
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: salesProvider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Cobrar Venta',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryState(SalesProvider salesProvider) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(children: [
              Icon(Icons.history, color: Colors.indigo[900]),
              const SizedBox(width: 8),
              Text('Historial de Ventas Hoy',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.indigo[900])),
            ]),
            const SizedBox(height: 16),
            if (salesProvider.todaysSales.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                    child: Text('Aún no has registrado ventas.',
                        style: TextStyle(
                            color: Colors.grey, fontStyle: FontStyle.italic))),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: salesProvider.todaysSales.length,
                separatorBuilder: (ctx, i) => const Divider(height: 32),
                itemBuilder: (ctx, i) {
                  final sale = salesProvider.todaysSales[i];

                  // 1. Cabecera (Cliente y Hora)
                  final clientName =
                      sale['client']?['fullName'] ?? 'Cliente Desconocido';
                  final dateStr = sale['createdAt'];
                  String timeLabel = "";
                  if (dateStr != null) {
                    try {
                      final dt = DateTime.parse(dateStr).toLocal();
                      timeLabel = DateFormat('h:mm a').format(dt);
                    } catch (_) {}
                  }

                  // 2. Método de Pago y Total
                  final paymentMethodMap = {
                    'CASH': 'EFECTIVO',
                    'YAPE': 'YAPE',
                    'PLIN': 'PLIN',
                    'CREDIT': 'CRÉDITO'
                  };
                  final rawMethod = sale['paymentMethod'] ?? 'CASH';
                  final methodLabel = paymentMethodMap[rawMethod] ?? rawMethod;
                  final totalAmount = sale['totalAmount'] ?? 0.0;

                  // 3. Detalles
                  final details = (sale['details'] as List<dynamic>?) ?? [];
                  final itemQuantity = details.fold<int>(
                      0, (sum, d) => sum + (d['quantity'] as int? ?? 0));
                  final uniqueProducts = details.length;

                  // 4. Ubicación
                  final double? lat = sale['latitude'];
                  final double? lng = sale['longitude'];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(clientName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12)),
                            child: Text(timeLabel,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Details List
                      if (details.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[200]!)),
                          child: Column(
                            children: details.map((d) {
                              final pName = d['product']?['name'] ?? 'Producto';
                              final qty = d['quantity'] ?? 0;
                              final subtotal = d['subtotal'] ?? 0.0;
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    Text('$qty x ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue)),
                                    Expanded(
                                        child: Text(pName,
                                            style: TextStyle(
                                                color: Colors.grey[800]))),
                                    Text('S/. $subtotal',
                                        style:
                                            TextStyle(color: Colors.grey[600]))
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Footer Row (Location + Summary)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Location Link
                          if (lat != null && lng != null)
                            InkWell(
                              onTap: () async {
                                final uri = Uri.parse(
                                    'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                }
                              },
                              child: const Row(children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.redAccent),
                                SizedBox(width: 4),
                                Text("Ver mapa",
                                    style: TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 13,
                                        decoration: TextDecoration.underline))
                              ]),
                            )
                          else
                            const SizedBox(),

                          // Totals
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('$itemQuantity u. ($uniqueProducts prod.)',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                              Row(children: [
                                Text(methodLabel,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey)),
                                const SizedBox(width: 8),
                                Text('S/. ${totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.blueAccent)),
                              ])
                            ],
                          )
                        ],
                      )
                    ],
                  );
                },
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);
    final routeProvider = Provider.of<RouteProvider>(context);

    // Route Status Check
    if (routeProvider.currentRoute == null ||
        routeProvider.currentRoute!.status == 'CLOSED') {
      return Scaffold(
        extendBodyBehindAppBar: true,
        drawer: const AppDrawer(),
        appBar: AppBar(title: const Text('Ventas')),
        body: const NoRoutePlaceholder(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Light grey background
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Venta en Campo',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
                'Ruta #${routeProvider.currentRoute!.id} • ${_gpsServiceEnabled ? 'GPS Activo' : 'Buscando GPS...'}',
                style: TextStyle(
                    fontSize: 12,
                    color: _gpsServiceEnabled
                        ? Colors.green[100]
                        : Colors.amber[100])),
          ],
        ),
        backgroundColor: const Color(0xFF0D47A1), // Standard Dark Blue
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildClientSection(salesProvider),
            const SizedBox(height: 16),
            _buildProductsSection(routeProvider),
            const SizedBox(height: 16),
            _buildSummaryPanel(routeProvider, salesProvider),
            const SizedBox(height: 16),
            _buildHistoryState(salesProvider),
          ],
        ),
      ),
    );
  }
}
