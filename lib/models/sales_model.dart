class Client {
  final int id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String commercialStatus; // ACTIVO, FRECUENTE, ALERTA
  final String? qrCode;
  final String? zone;
  final String? ruc;

  Client({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    required this.commercialStatus,
    this.qrCode,
    this.zone,
    this.ruc,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      name: json['fullName'] ?? json['name'] ?? 'Cliente Sin Nombre',
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      commercialStatus: json['commercialStatus'] ?? 'ACTIVO',
      qrCode: json['tokenQr']?['code'],
      zone: json['zone'],
      ruc: json['ruc'] ?? json['documentNumber'],
    );
  }
}

class SaleItem {
  final int productId;
  int quantity;

  SaleItem({required this.productId, required this.quantity});

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}

class SaleRequest {
  final int routeId;
  final int clientId;
  final String paymentMethod;
  final double latitude;
  final double longitude;
  final List<SaleItem> items;

  SaleRequest({
    required this.routeId,
    required this.clientId,
    required this.paymentMethod,
    required this.latitude,
    required this.longitude,
    required this.items,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'clientId': clientId,
      'paymentMethod': paymentMethod,
      'latitude': latitude,
      'longitude': longitude,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
