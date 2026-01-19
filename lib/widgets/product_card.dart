import 'package:flutter/material.dart';
import 'package:app_driver/models/route_model.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  final StockItem stockItem;

  const ProductCard({super.key, required this.stockItem});

  @override
  Widget build(BuildContext context) {
    // Formato de moneda para Perú (S/.)
    final currencyFormat =
        NumberFormat.currency(locale: 'es_PE', symbol: 'S/.');

    final isExhausted = stockItem.currentQuantity == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Icono o Imagen del producto
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isExhausted
                    ? Colors.grey[300]
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.propane_tank, // Icono genérico de balón de gas
                color:
                    isExhausted ? Colors.grey : Theme.of(context).primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            // Detalles del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stockItem.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currencyFormat.format(stockItem.product.price),
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Cantidad
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isExhausted)
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('AGOTADO',
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)))
                else
                  Text(
                    '${stockItem.currentQuantity}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                Text(
                  'Inicial: ${stockItem.initialQuantity}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
