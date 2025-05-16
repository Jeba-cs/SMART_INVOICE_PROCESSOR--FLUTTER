import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';

class CsvExportService {
  Future<String> exportInvoicesToCustomCsv(
      List<Invoice> invoices, {
        required String customPath,
      }) async {
    List<List<dynamic>> rows = [
      ['DATE', 'INVOICE NUMBER', 'DESCRIPTION', 'LIST EA', 'QUANTITY', 'COST', 'TAX']
    ];

    double fullCostTotal = 0;
    double fullTaxTotal = 0;

    for (final invoice in invoices) {
      final invoiceJson = invoice.jsonData;
      final dateStr = invoiceJson['date'] ?? DateFormat('yyyy-MM-dd').format(invoice.date);
      final invoiceNumber = invoiceJson['invoice_number'] ?? invoiceJson['invoice no'] ?? invoice.id;
      final lineItems = (invoiceJson['line_items'] ?? invoiceJson['items'] ?? []) as List<dynamic>;

      for (final item in lineItems) {
        final quantity = double.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        final cost = double.tryParse(item['cost']?.toString() ?? item['price']?.toString() ?? '0') ?? 0;
        final tax = double.tryParse(item['tax']?.toString() ?? '0') ?? 0;

        fullCostTotal += quantity * cost;
        fullTaxTotal += tax;

        rows.add([
          dateStr,
          invoiceNumber,
          item['description'] ?? '',
          item['list_ea'] ?? item['list'] ?? '',
          quantity,
          cost,
          tax,
        ]);
      }
    }

    rows.add([]);
    rows.add(['Full Cost Total', '', '', '', '', fullCostTotal]);
    rows.add(['Full Tax Total', '', '', '', '', fullTaxTotal]);
    rows.add(['Overall Total', '', '', '', '', fullCostTotal + fullTaxTotal]);

    String csvData = const ListToCsvConverter().convert(rows);
    final file = File(customPath);
    await file.writeAsBytes(utf8.encode(csvData));
    return customPath;
  }
}
