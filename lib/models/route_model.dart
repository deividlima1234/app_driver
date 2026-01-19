class DriverInfo {
  final String fullName;

  DriverInfo({required this.fullName});

  factory DriverInfo.fromJson(Map<String, dynamic> json) {
    return DriverInfo(
      fullName: json['fullName'] ?? 'Desconocido',
    );
  }
}

class Vehicle {
  final String plate;
  final String brand;
  final String model;

  Vehicle({
    required this.plate,
    required this.brand,
    required this.model,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      plate: json['plate'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
    );
  }
}

class Product {
  final int id;
  final String name;
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.price,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Producto Desconocido',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class StockItem {
  final int id;
  int currentQuantity;
  final int initialQuantity;
  final int returnQuantity;
  final Product product;

  StockItem({
    required this.id,
    required this.currentQuantity,
    required this.initialQuantity,
    required this.returnQuantity,
    required this.product,
  });

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] ?? 0,
      currentQuantity: json['currentQuantity'] ?? 0,
      initialQuantity: json['initialQuantity'] ?? 0,
      returnQuantity: json['returnQuantity'] ?? 0,
      product: Product.fromJson(json['product'] ?? {}),
    );
  }
}

class RouteModel {
  final int id;
  final String status; // OPEN, CLOSED
  final DateTime? openedAt;
  final DriverInfo driver;
  final Vehicle vehicle;
  final List<StockItem> stock;

  RouteModel({
    required this.id,
    required this.status,
    required this.openedAt,
    required this.driver,
    required this.vehicle,
    required this.stock,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'UNKNOWN',
      openedAt:
          json['openedAt'] != null ? DateTime.tryParse(json['openedAt']) : null,
      driver: DriverInfo.fromJson(json['driver'] ?? {}),
      vehicle: Vehicle.fromJson(json['vehicle'] ?? {}),
      stock: (json['stock'] as List<dynamic>?)
              ?.map((e) => StockItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}
