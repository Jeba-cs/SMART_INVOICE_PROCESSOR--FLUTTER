import 'dart:io';
import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../services/storage_service.dart';

class ResultScreen extends StatefulWidget {
  final String rawText;
  final Map<String, dynamic> invoiceJson;
  final File imageFile;

  const ResultScreen({
    super.key,
    required this.rawText,
    required this.invoiceJson,
    required this.imageFile,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _saved = false;

  Future<void> _saveToHistory() async {
    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      vendor: widget.invoiceJson['vendor'] ?? '',
      customer: widget.invoiceJson['customer'] ?? '',
      lineItems: List<Map<String, dynamic>>.from(widget.invoiceJson['line_items'] ?? []),
      subtotal: (widget.invoiceJson['subtotal'] ?? 0).toDouble(),
      tax: (widget.invoiceJson['tax'] ?? 0).toDouble(),
      total: (widget.invoiceJson['total'] ?? 0).toDouble(),
      rawText: widget.rawText,
      jsonData: widget.invoiceJson,
    );
    await StorageService().saveInvoice(invoice);
    setState(() {
      _saved = true;
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice saved to history!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Result')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFF90CAF9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              const Text('Raw OCR Text:', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(widget.rawText),
              const SizedBox(height: 24),
              const Text('Extracted Invoice Data (JSON):', style: TextStyle(fontWeight: FontWeight.bold)),
              SelectableText(widget.invoiceJson.toString()),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(_saved ? Icons.check : Icons.save),
                label: Text(_saved ? 'Saved!' : 'Save to History'),
                onPressed: _saved ? null : _saveToHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _saved ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
