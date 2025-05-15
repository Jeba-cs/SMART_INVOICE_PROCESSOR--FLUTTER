import 'package:flutter/material.dart';
import '../models/invoice.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  const InvoiceCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        title: Text('Invoice: ${invoice.id}'),
        subtitle: Text('Vendor: ${invoice.vendor}\nCustomer: ${invoice.customer}\nTotal: ${invoice.total}'),
        trailing: IconButton(
          icon: const Icon(Icons.info_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Invoice Details'),
                content: SingleChildScrollView(
                  child: Text(invoice.jsonData.toString()),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
