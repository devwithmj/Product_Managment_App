import 'dart:convert';

class PriceLog {
  final String id;
  final String productId;
  final double oldPrice;
  final double newPrice;
  final DateTime changeDate;
  final String? notes;

  PriceLog({
    required this.id,
    required this.productId,
    required this.oldPrice,
    required this.newPrice,
    required this.changeDate,
    this.notes,
  });

  // Create a Map from PriceLog
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'changeDate': changeDate.millisecondsSinceEpoch,
      'notes': notes,
    };
  }

  // Create PriceLog from Map
  factory PriceLog.fromMap(Map<String, dynamic> map) {
    return PriceLog(
      id: map['id'],
      productId: map['productId'],
      oldPrice:
          map['oldPrice'] is int
              ? (map['oldPrice'] as int).toDouble()
              : map['oldPrice'],
      newPrice:
          map['newPrice'] is int
              ? (map['newPrice'] as int).toDouble()
              : map['newPrice'],
      changeDate: DateTime.fromMillisecondsSinceEpoch(map['changeDate']),
      notes: map['notes'],
    );
  }

  // Convert to JSON
  String toJson() => json.encode(toMap());

  // Create from JSON
  factory PriceLog.fromJson(String source) =>
      PriceLog.fromMap(json.decode(source));

  @override
  String toString() {
    return 'PriceLog(id: $id, productId: $productId, oldPrice: $oldPrice, '
        'newPrice: $newPrice, changeDate: $changeDate, notes: $notes)';
  }
}
