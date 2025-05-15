import 'dart:io';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/invoice.dart';

class CsvExportService {
  Future<String> exportInvoicesToCustomCsv(List<Invoice> invoices, {required String customPath}) async {
    List<List<dynamic>> rows = [
      ['DATE', 'INVOICE NUMBER', 'DESCRIPTION', 'LIST EA', 'QUANTITY', 'COST', 'TAX', 'TOTAL']
    ];
    for (final invoice in invoices) {
      final invoiceJson = invoice.jsonData;
      // Use the date from JSON if present, else from model
      final dateStr = invoiceJson['date'] ?? DateFormat('yyyy-MM-dd').format(invoice.date);
      // Use the invoice number from JSON if present, else from model
      final invoiceNumber = invoiceJson['invoice_number'] ?? invoiceJson['invoice no'] ?? invoice.id;
      // Line items from JSON
      final lineItems = (invoiceJson['line_items'] ?? invoiceJson['items'] ?? []) as List<dynamic>;
      if (lineItems.isNotEmpty) {
        for (final item in lineItems) {
          // LIST EA: prefer 'list_ea', fallback to 'list', else empty
          final listEA = item['list_ea'] ?? item['list'] ?? '';
          rows.add([
            dateStr,
            invoiceNumber,
            item['description'] ?? '',
            listEA,
            item['quantity']?.toString() ?? '',
            item['cost']?.toString() ?? item['price']?.toString() ?? '',
            item['tax']?.toString() ?? '',
            item['total']?.toString() ?? '',
          ]);
        }
      } else {
        // No line items, just add the invoice summary
        rows.add([
          dateStr,
          invoiceNumber,
          invoiceJson['description'] ?? '',
          invoiceJson['list_ea'] ?? invoiceJson['list'] ?? '',
          invoiceJson['quantity']?.toString() ?? '',
          invoiceJson['cost']?.toString() ?? invoiceJson['price']?.toString() ?? '',
          invoiceJson['tax']?.toString() ?? '',
          invoiceJson['total']?.toString() ?? '',
        ]);
      }
    }
    String csvData = const ListToCsvConverter().convert(rows);
    final file = File(customPath);
    await file.writeAsBytes(utf8.encode(csvData));
    return customPath;
  }
}
