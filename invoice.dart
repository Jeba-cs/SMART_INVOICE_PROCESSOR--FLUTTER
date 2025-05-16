import 'package:hive/hive.dart';

part 'invoice.g.dart';

@HiveType(typeId: 0)
class Invoice extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime date;
  @HiveField(2)
  final String vendor;
  @HiveField(3)
  final String customer;
  @HiveField(4)
  final List<Map<String, dynamic>> lineItems;
  @HiveField(5)
  final double subtotal;
  @HiveField(6)
  final double tax;
  @HiveField(7)
  final double total;
  @HiveField(8)
  final String rawText;
  @HiveField(9)
  final Map<String, dynamic> jsonData;

  Invoice({
    required this.id,
    required this.date,
    required this.vendor,
    required this.customer,
    required this.lineItems,
    required this.subtotal,
    required this.tax,
    required this.total,
    required this.rawText,
    required this.jsonData,
  });

  Invoice copyWith({
    String? id,
    DateTime? date,
    String? vendor,
    String? customer,
    List<Map<String, dynamic>>? lineItems,
    double? subtotal,
    double? tax,
    double? total,
    String? rawText,
    Map<String, dynamic>? jsonData,
  }) {
    return Invoice(
      id: id ?? this.id,
      date: date ?? this.date,
      vendor: vendor ?? this.vendor,
      customer: customer ?? this.customer,
      lineItems: lineItems ?? this.lineItems,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      total: total ?? this.total,
      rawText: rawText ?? this.rawText,
      jsonData: jsonData ?? this.jsonData,
    );
  }
}
