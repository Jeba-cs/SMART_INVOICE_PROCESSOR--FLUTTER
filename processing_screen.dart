import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/invoice.dart';

class ProcessingScreen extends StatelessWidget {
  final Invoice invoice;
  const ProcessingScreen({Key? key, required this.invoice}) : super(key: key);

  void _saveToHistory(BuildContext context) async {
    final hasCriticalData = invoice.subtotal != 0.0 &&
        invoice.total != 0.0 &&
        invoice.date != null;

    if (!hasCriticalData) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Missing Critical Data'),
          content: const Text(
              'This invoice is missing subtotal, total, or date. Save anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _forceSaveToHistory(context);
                Navigator.pop(context);
              },
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
    } else {
      _forceSaveToHistory(context);
    }
  }

  void _forceSaveToHistory(BuildContext context) async {
    final box = Hive.box<Invoice>('invoices');
    await box.add(invoice);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invoice saved')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ...your UI for processing and showing invoice...
    return Scaffold(
      appBar: AppBar(title: const Text('Process Invoice')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _saveToHistory(context),
          child: const Text('Save to History'),
        ),
      ),
    );
  }
}
