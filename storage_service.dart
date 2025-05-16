import 'package:hive/hive.dart';
import '../models/invoice.dart';

class StorageService {
  static const _invoiceBoxName = 'invoices';

  Future<void> saveInvoice(Invoice invoice) async {
    try {
      final box = await Hive.openBox<Invoice>(_invoiceBoxName);
      // Safely trim rawText to 1000 characters if needed
      final rawText = invoice.rawText.length > 1000
          ? invoice.rawText.substring(0, 1000)
          : invoice.rawText;
      final optimizedInvoice = Invoice(
        id: invoice.id,
        date: invoice.date,
        vendor: invoice.vendor,
        customer: invoice.customer,
        lineItems: invoice.lineItems,
        subtotal: invoice.subtotal,
        tax: invoice.tax,
        total: invoice.total,
        rawText: rawText,
        jsonData: invoice.jsonData,
      );
      await box.add(optimizedInvoice);
    } catch (e) {
      throw Exception('Failed to save invoice: $e');
    }
  }

  Future<List<Invoice>> getInvoices() async {
    final box = await Hive.openBox<Invoice>(_invoiceBoxName);
    return box.values.toList();
  }
}
