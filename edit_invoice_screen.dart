import 'package:flutter/material.dart';
import '../models/invoice.dart';

class EditInvoiceScreen extends StatefulWidget {
  final Invoice invoice;
  const EditInvoiceScreen({super.key, required this.invoice});

  @override
  State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
  late TextEditingController _vendorController;
  late TextEditingController _dateController;
  late TextEditingController _invoiceNumberController;
  late List<Map<String, TextEditingController>> _lineItemControllers;

  @override
  void initState() {
    super.initState();
    _vendorController = TextEditingController(text: widget.invoice.vendor);
    _dateController = TextEditingController(text: widget.invoice.jsonData['date'] ?? widget.invoice.date.toString().split(' ')[0]);
    _invoiceNumberController = TextEditingController(text: widget.invoice.jsonData['invoice_number'] ?? widget.invoice.id);

    _lineItemControllers = widget.invoice.lineItems.map((item) {
      return {
        'description': TextEditingController(text: item['description']?.toString() ?? ''),
        'list_ea': TextEditingController(text: item['list_ea']?.toString() ?? item['list']?.toString() ?? ''),
        'quantity': TextEditingController(text: item['quantity']?.toString() ?? ''),
        'cost': TextEditingController(text: item['cost']?.toString() ?? item['price']?.toString() ?? ''),
        'tax': TextEditingController(text: item['tax']?.toString() ?? ''),
        'total': TextEditingController(text: item['total']?.toString() ?? ''),
      };
    }).toList();
  }

  void _saveChanges() {
    final updatedLineItems = _lineItemControllers.map((controllers) => {
      'description': controllers['description']!.text,
      'list_ea': controllers['list_ea']!.text,
      'quantity': controllers['quantity']!.text,
      'cost': controllers['cost']!.text,
      'tax': controllers['tax']!.text,
      'total': controllers['total']!.text,
    }).toList();

    final updatedInvoice = widget.invoice.copyWith(
      vendor: _vendorController.text,
      date: DateTime.tryParse(_dateController.text) ?? widget.invoice.date,
      jsonData: {
        ...widget.invoice.jsonData,
        'date': _dateController.text,
        'invoice_number': _invoiceNumberController.text,
        'line_items': updatedLineItems,
      },
      lineItems: updatedLineItems,
    );
    Navigator.pop(context, updatedInvoice);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _vendorController,
              decoration: const InputDecoration(labelText: 'Vendor'),
            ),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)'),
            ),
            TextField(
              controller: _invoiceNumberController,
              decoration: const InputDecoration(labelText: 'Invoice Number'),
            ),
            const SizedBox(height: 16),
            const Text('Line Items', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._lineItemControllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final controllers = entry.value;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      TextField(
                        controller: controllers['description'],
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                      TextField(
                        controller: controllers['list_ea'],
                        decoration: const InputDecoration(labelText: 'List EA'),
                      ),
                      TextField(
                        controller: controllers['quantity'],
                        decoration: const InputDecoration(labelText: 'Quantity'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: controllers['cost'],
                        decoration: const InputDecoration(labelText: 'Cost'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: controllers['tax'],
                        decoration: const InputDecoration(labelText: 'Tax'),
                        keyboardType: TextInputType.number,
                      ),
                      TextField(
                        controller: controllers['total'],
                        decoration: const InputDecoration(labelText: 'Total'),
                        keyboardType: TextInputType.number,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _lineItemControllers.removeAt(idx);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Line Item'),
              onPressed: () {
                setState(() {
                  _lineItemControllers.add({
                    'description': TextEditingController(),
                    'list_ea': TextEditingController(),
                    'quantity': TextEditingController(),
                    'cost': TextEditingController(),
                    'tax': TextEditingController(),
                    'total': TextEditingController(),
                  });
                });
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveChanges,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
