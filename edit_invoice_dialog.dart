import 'package:flutter/material.dart';
import '../models/invoice.dart';

class EditInvoiceDialog extends StatefulWidget {
  final Invoice invoice;
  const EditInvoiceDialog({Key? key, required this.invoice}) : super(key: key);

  @override
  State<EditInvoiceDialog> createState() => _EditInvoiceDialogState();
}

class _EditInvoiceDialogState extends State<EditInvoiceDialog> {
  late TextEditingController vendorController;
  late TextEditingController customerController;
  late TextEditingController subtotalController;
  late TextEditingController taxController;
  late TextEditingController totalController;
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    vendorController = TextEditingController(text: widget.invoice.vendor);
    customerController = TextEditingController(text: widget.invoice.customer);
    subtotalController = TextEditingController(text: widget.invoice.subtotal.toString());
    taxController = TextEditingController(text: widget.invoice.tax.toString());
    totalController = TextEditingController(text: widget.invoice.total.toString());
    dateController = TextEditingController(text: widget.invoice.date.toIso8601String().split('T')[0]);
  }

  @override
  void dispose() {
    vendorController.dispose();
    customerController.dispose();
    subtotalController.dispose();
    taxController.dispose();
    totalController.dispose();
    dateController.dispose();
    super.dispose();
  }

  void _save() {
    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(dateController.text);
    } catch (_) {}

    final updatedInvoice = widget.invoice.copyWith(
      vendor: vendorController.text,
      customer: customerController.text,
      subtotal: double.tryParse(subtotalController.text) ?? 0.0,
      tax: double.tryParse(taxController.text) ?? 0.0,
      total: double.tryParse(totalController.text) ?? 0.0,
      date: parsedDate ?? widget.invoice.date,
    );
    Navigator.of(context).pop(updatedInvoice);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Invoice'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: vendorController,
              decoration: const InputDecoration(labelText: 'Vendor'),
            ),
            TextField(
              controller: customerController,
              decoration: const InputDecoration(labelText: 'Customer'),
            ),
            TextField(
              controller: subtotalController,
              decoration: const InputDecoration(labelText: 'Subtotal'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: taxController,
              decoration: const InputDecoration(labelText: 'Tax'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: totalController,
              decoration: const InputDecoration(labelText: 'Total'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: dateController,
              decoration: const InputDecoration(labelText: 'Invoice Date (YYYY-MM-DD)'),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
