class ObservedLiquidation {
  final int id;
  final String status;
  final String adminNote;

  ObservedLiquidation({
    required this.id,
    required this.status,
    required this.adminNote,
  });

  factory ObservedLiquidation.fromJson(Map<String, dynamic> json) {
    return ObservedLiquidation(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'OBSERVED',
      adminNote: json['adminNote'] ?? 'Sin nota del administrador',
    );
  }
}

class LiquidationResponse {
  final double totalCash;
  final double totalDigital;
  final int totalItemsSold;
  final String status;

  LiquidationResponse({
    required this.totalCash,
    required this.totalDigital,
    required this.totalItemsSold,
    required this.status,
  });

  factory LiquidationResponse.fromJson(Map<String, dynamic> json) {
    return LiquidationResponse(
      totalCash: (json['totalCash'] as num?)?.toDouble() ?? 0.0,
      totalDigital: (json['totalDigital'] as num?)?.toDouble() ?? 0.0,
      totalItemsSold: json['totalItemsSold'] ?? 0,
      status: json['status'] ?? 'PENDING',
    );
  }
}

class LiquidationHistoryItem {
  final int id;
  final String status;
  final DateTime createdAt;
  final double totalCash;
  final double totalDigital;
  final String? adminNote;

  LiquidationHistoryItem({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.totalCash,
    required this.totalDigital,
    this.adminNote,
  });

  factory LiquidationHistoryItem.fromJson(Map<String, dynamic> json) {
    return LiquidationHistoryItem(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'UNKNOWN',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      totalCash: (json['totalCash'] as num?)?.toDouble() ?? 0.0,
      totalDigital: (json['totalDigital'] as num?)?.toDouble() ?? 0.0,
      adminNote: json['adminNote'],
    );
  }
}

class LiquidationPage {
  final List<LiquidationHistoryItem> content;
  final int totalPages;
  final int number;
  final bool last;

  LiquidationPage({
    required this.content,
    required this.totalPages,
    required this.number,
    required this.last,
  });

  factory LiquidationPage.fromJson(Map<String, dynamic> json) {
    return LiquidationPage(
      content: (json['content'] as List<dynamic>?)
              ?.map((e) => LiquidationHistoryItem.fromJson(e))
              .toList() ??
          [],
      totalPages: json['totalPages'] ?? 0,
      number: json['number'] ?? 0,
      last: json['last'] ?? true,
    );
  }
}
