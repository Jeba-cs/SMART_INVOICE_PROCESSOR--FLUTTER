// lib/screens/multi_result_screen.dart
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
          final imageFile = res['imageFile'] as File;
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.file(imageFile, height: 80),
                  const SizedBox(height: 8),
                  const Text('Raw OCR Text:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(rawText),
                  const SizedBox(height: 8),
                  const Text('Extracted Invoice Data (JSON):', style: TextStyle(fontWeight: FontWeight.bold)),
                  SelectableText(invoiceJson.toString()),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save to History'),
                    onPressed: () async {
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
