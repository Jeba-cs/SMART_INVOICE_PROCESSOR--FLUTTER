import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import '../models/invoice.dart';

Future<void> exportInvoicesAsCsv(List<Invoice> invoices) async {
  List<List<dynamic>> csvData = [
    ['DATE', 'INVOICE NUMBER', 'DESCRIPTION', 'LIST EA', 'QUANTITY', 'COST', 'TAX'],
  ];

  double totalCost = 0;
  double totalTax = 0;

  for (var invoice in invoices) {
    for (var item in invoice.lineItems) {
      final cost = (item['price'] ?? 0) * (item['quantity'] ?? 0);
      final tax = invoice.tax; // Or item['tax'] if per-line
      csvData.add([
        _formatSimpleDate(invoice.date),
        invoice.id,
        item['description'] ?? '',
        item['price'] ?? '',
        item['quantity'] ?? '',
        cost,
        tax,
      ]);
      totalCost += cost;
      totalTax += tax;
    }
  }

  csvData.add([]);
  csvData.add(['Full Cost Total', '', '', '', '', totalCost, '']);
  csvData.add(['Full Tax Total', '', '', '', '', '', totalTax]);
  csvData.add(['Overall Total', '', '', '', '', totalCost + totalTax, '']);

  String csv = const ListToCsvConverter().convert(csvData);
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/invoices_${DateTime.now().millisecondsSinceEpoch}.csv');
  await file.writeAsString(csv);
}

String _formatSimpleDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final month = months[date.month - 1];
  final year = date.year.toString().substring(2);
  return '$day-$month-$year';
}
