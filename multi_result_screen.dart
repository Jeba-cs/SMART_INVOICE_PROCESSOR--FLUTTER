import 'dart:io';
import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/storage_service.dart';

class MultiResultScreen extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  const MultiResultScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Processed Invoices')),
      body: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, i) {
          final res = results[i];
          final rawText = res['rawText'] as String;
          final invoiceJson = res['invoiceJson'] as Map<String, dynamic>;
          final imageFile = res['imageFile'] as File?;
          final pdfFile = res['pdfFile'] as File?;
          final hasError = invoiceJson['error'] != null;

          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageFile != null)
                    Image.file(imageFile, height: 80),
                  if (pdfFile != null)
                    Row(
                      children: [
                        const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pdfFile.path.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  if (hasError)
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.red[100],
                      child: Text(
                        'Error: ${invoiceJson['error']}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const Text('Raw OCR Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(rawText),
                  const SizedBox(height: 8),
                  const Text('Extracted Invoice Data (JSON):', style: TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(invoiceJson.toString()),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save to History'),
                    onPressed: hasError
                        ? null
                        : () async {
                      try {
                        final invoice = Invoice(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          date: DateTime.now(),
                          vendor: invoiceJson['vendor'] ?? '',
                          customer: invoiceJson['customer'] ?? '',
                          lineItems: List<Map<String, dynamic>>.from(invoiceJson['line_items'] ?? []),
                          subtotal: (invoiceJson['subtotal'] ?? 0).toDouble(),
                          tax: (invoiceJson['tax'] ?? 0).toDouble(),
                          total: (invoiceJson['total'] ?? 0).toDouble(),
                          rawText: rawText,
                          jsonData: invoiceJson,
                        );
                        await StorageService().saveInvoice(invoice);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invoice saved to history!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save: $e')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
