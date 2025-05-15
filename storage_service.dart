import 'package:hive/hive.dart';
import '../models/invoice.dart';

class StorageService {
  Future<void> saveInvoice(Invoice invoice) async {
    final box = await Hive.openBox<Invoice>('invoices');
    await box.put(invoice.id, invoice);
  }

  Future<List<Invoice>> getInvoices() async {
    final box = await Hive.openBox<Invoice>('invoices');
    return box.values.toList();
  }
}
