import 'package:app_driver/models/liquidation_model.dart';
import 'package:flutter/material.dart';
import 'package:app_driver/services/liquidation_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:app_driver/providers/route_provider.dart';
import 'package:app_driver/widgets/app_drawer.dart';
import 'package:app_driver/widgets/no_route_placeholder.dart';

class LiquidationHistoryScreen extends StatefulWidget {
  const LiquidationHistoryScreen({super.key});

  @override
  State<LiquidationHistoryScreen> createState() =>
      _LiquidationHistoryScreenState();
}

class _LiquidationHistoryScreenState extends State<LiquidationHistoryScreen> {
  final _liquidationService = LiquidationService();
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _fmt = NumberFormat.currency(symbol: 'S/. ');

  // State
  final List<LiquidationHistoryItem> _items = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String _statusFilter = 'Todos';
  DateTime? _startDateFilter;

  @override
  void initState() {
    super.initState();
    _loadHistory(reset: true);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory({bool reset = false}) async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      if (reset) {
        _items.clear();
        _currentPage = 0;
        _hasMore = true;
      }
    });

    try {
      final String? dateStr = _startDateFilter != null
          ? DateFormat('yyyy-MM-ddTHH:mm:ss').format(_startDateFilter!)
          : null;

      final pageData = await _liquidationService.getHistory(
        page: _currentPage,
        size: 10,
        status: _statusFilter == 'Todos' ? null : _statusFilter,
        startDate: dateStr,
      );

      setState(() {
        _items.addAll(pageData.content);
        _hasMore = !pageData.last;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'OBSERVED':
        return Colors.amber;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.blue; // PENDING
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'APPROVED':
        return 'Aprobado';
      case 'OBSERVED':
        return 'Observado';
      case 'REJECTED':
        return 'Rechazado';
      case 'PENDING':
        return 'Pendiente';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final routeProvider = Provider.of<RouteProvider>(context);

    if (routeProvider.currentRoute == null ||
        routeProvider.currentRoute!.status == 'CLOSED') {
      return Scaffold(
        appBar: AppBar(title: const Text('Historial')),
        drawer: const AppDrawer(),
        body: const NoRoutePlaceholder(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Light bg
      appBar: AppBar(title: const Text('Historial de Liquidaciones')),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _items.isEmpty && !_isLoading
                ? const Center(
                    child: Text('No se encontraron liquidaciones.',
                        style: TextStyle(color: Colors.grey)))
                : RefreshIndicator(
                    onRefresh: () async => _loadHistory(reset: true),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return const Center(
                              child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ));
                        }
                        return _buildHistoryCard(_items[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("FILTROS",
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            children: [
              // Status Dropdown
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      isExpanded: true,
                      items: [
                        'Todos',
                        'PENDING',
                        'APPROVED',
                        'OBSERVED',
                        'REJECTED'
                      ]
                          .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s == 'Todos' ? s : _getStatusLabel(s),
                                  overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _statusFilter = val);
                          _loadHistory(reset: true);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Date Picker
              Expanded(
                flex: 3,
                child: InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDateFilter ?? DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime.now());
                    if (picked != null) {
                      setState(() => _startDateFilter = picked);
                      _loadHistory(reset: true);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            _startDateFilter == null
                                ? 'Desde dd/mm/aaaa'
                                : DateFormat('dd/MM/yyyy')
                                    .format(_startDateFilter!),
                            style: TextStyle(
                                color: _startDateFilter == null
                                    ? Colors.grey
                                    : Colors.black)),
                        const Icon(Icons.calendar_today,
                            size: 16, color: Colors.grey)
                      ],
                    ),
                  ),
                ),
              ),
              // Clear Date
              if (_startDateFilter != null)
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      setState(() => _startDateFilter = null);
                      _loadHistory(reset: true);
                    })
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(LiquidationHistoryItem item) {
    final color = _getStatusColor(item.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 6)),
            color: Colors.white,
            borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy • hh:mm a').format(item.createdAt),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusLabel(item.status),
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text("Liquidación #${item.id}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Amounts Grid
            Row(
              children: [
                _buildAmountCol("EFECTIVO", item.totalCash, false),
                _buildAmountCol("DIGITAL", item.totalDigital, false),
                _buildAmountCol(
                    "TOTAL", item.totalCash + item.totalDigital, true),
              ],
            ),
            // Admin Note
            if (item.adminNote != null && item.adminNote!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.amber[50], // Soft amber bg
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 16, color: Colors.amber[800]),
                      const SizedBox(width: 4),
                      Text("OBSERVACIÓN",
                          style: TextStyle(
                              color: Colors.amber[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 11))
                    ]),
                    const SizedBox(height: 4),
                    Text(item.adminNote!,
                        style: TextStyle(color: Colors.amber[900])),
                  ],
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCol(String label, double amount, bool isTotal) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: isTotal ? Colors.indigo : Colors.grey,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(_fmt.format(amount),
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isTotal ? Colors.indigo : Colors.black87)),
        ],
      ),
    );
  }
}
