import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/invoice.dart';
import '../extensions/number_extensions.dart';
import 'edit_invoice_dialog.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({Key? key}) : super(key: key);

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  late Box<Invoice> invoiceBox;
  Map<String, List<Invoice>> groupedInvoices = {};
  Set<int> selectedInvoiceKeys = {};
  Map<String, bool> expandedGroups = {};

  @override
  void initState() {
    super.initState();
    invoiceBox = Hive.box<Invoice>('invoices');
    _groupInvoices();
    invoiceBox.listenable().addListener(_groupInvoices);
  }

  @override
  void dispose() {
    invoiceBox.listenable().removeListener(_groupInvoices);
    super.dispose();
  }

  void _groupInvoices() {
    final invoices = invoiceBox.values.toList();
    invoices.sort((a, b) => b.date.compareTo(a.date));
    final newGrouped = <String, List<Invoice>>{};
    for (var invoice in invoices) {
      final dateStr = _formatDate(invoice.date);
      newGrouped.putIfAbsent(dateStr, () => []).add(invoice);
    }
    setState(() {
      groupedInvoices = newGrouped;
      expandedGroups = {for (var k in groupedInvoices.keys) k: true};
    });
  }

  String _formatDate(DateTime date) {
    return "${_weekday(date.weekday)}, ${_month(date.month)} ${date.day}, ${date.year}";
  }

  String _weekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[(weekday - 1) % 7];
  }

  String _month(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[(month - 1) % 12];
  }

  String _formatTime(DateTime date) {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  bool get _allSelected => selectedInvoiceKeys.length == invoiceBox.length;

  void _toggleGlobalSelection() {
    setState(() {
      if (_allSelected) {
        selectedInvoiceKeys.clear();
      } else {
        selectedInvoiceKeys.addAll(invoiceBox.keys.cast<int>());
      }
    });
  }

  void _toggleSelectAll(String dateStr) {
    final invoices = groupedInvoices[dateStr]!;
    final allSelected = invoices.every((inv) => selectedInvoiceKeys.contains(inv.key));
    setState(() {
      if (allSelected) {
        invoices.forEach((inv) => selectedInvoiceKeys.remove(inv.key));
      } else {
        invoices.forEach((inv) => selectedInvoiceKeys.add(inv.key));
      }
    });
  }

  void _editInvoice(Invoice invoice) async {
    final updatedInvoice = await showDialog<Invoice>(
      context: context,
      builder: (context) => EditInvoiceDialog(invoice: invoice),
    );
    if (updatedInvoice != null) {
      await invoiceBox.put(invoice.key, updatedInvoice);
      // _groupInvoices(); // Not needed: listener will trigger regroup
    }
  }

  void _showInvoiceInfo(Invoice invoice) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Invoice Info'),
        content: Text(
          'Invoice: ${invoice.id}\n'
              'Vendor: ${invoice.vendor}\n'
              'Customer: ${invoice.customer}\n'
              'Subtotal: ${invoice.subtotal}\n'
              'Tax: ${invoice.tax}\n'
              'Total: ${invoice.total}\n'
              'Time: ${_formatTime(invoice.date)}\n'
              'Date: ${_formatDate(invoice.date)}\n'
              'Line Items: ${invoice.lineItems.map((item) => item['description']).join(", ")}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  List<Invoice> get _selectedInvoices =>
      invoiceBox.values.where((inv) => selectedInvoiceKeys.contains(inv.key)).toList();

  Future<void> _exportSelectedAsCsv() async {
    if (_selectedInvoices.isEmpty) return;

    final missingDataInvoices = _selectedInvoices.where((inv) =>
    inv.subtotal == 0.0 || inv.total == 0.0
    ).toList();

    if (missingDataInvoices.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${missingDataInvoices.length} invoices missing financial data'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    List<List<dynamic>> csvData = [
      ['Invoice ID', 'Date', 'Vendor', 'Customer', 'Subtotal', 'Tax', 'Total', 'Line Items'],
      ..._selectedInvoices.map((inv) => [
        inv.id,
        _formatDate(inv.date),
        inv.vendor,
        inv.customer,
        inv.subtotal != 0.0 ? inv.subtotal.toCurrencyString() : 'N/A',
        inv.tax != 0.0 ? inv.tax.toCurrencyString() : 'N/A',
        inv.total != 0.0 ? inv.total.toCurrencyString() : 'N/A',
        inv.lineItems.isNotEmpty
            ? inv.lineItems.map((item) =>
        '${item['description'] ?? ''} (Qty: ${item['quantity'] ?? ''}, Price: ${item['price'] ?? ''})'
        ).join('; ')
            : 'N/A',
      ])
    ];

    String csv = const ListToCsvConverter().convert(csvData);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/invoices_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exported: ${file.path}')),
    );
  }

  Future<void> _shareCsv() async {
    if (_selectedInvoices.isEmpty) return;
    List<List<dynamic>> csvData = [
      ['Invoice ID', 'Date', 'Vendor', 'Customer', 'Subtotal', 'Tax', 'Total', 'Line Items'],
      ..._selectedInvoices.map((inv) => [
        inv.id,
        _formatDate(inv.date),
        inv.vendor,
        inv.customer,
        inv.subtotal != 0.0 ? inv.subtotal.toCurrencyString() : 'N/A',
        inv.tax != 0.0 ? inv.tax.toCurrencyString() : 'N/A',
        inv.total != 0.0 ? inv.total.toCurrencyString() : 'N/A',
        inv.lineItems.isNotEmpty
            ? inv.lineItems.map((item) =>
        '${item['description'] ?? ''} (Qty: ${item['quantity'] ?? ''}, Price: ${item['price'] ?? ''})'
        ).join('; ')
            : 'N/A',
      ])
    ];
    String csv = const ListToCsvConverter().convert(csvData);
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/invoices_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Invoices CSV');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        actions: [
          IconButton(
            icon: Icon(_allSelected ? Icons.check_box : Icons.check_box_outline_blank),
            onPressed: _toggleGlobalSelection,
            tooltip: 'Select All Invoices',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _groupInvoices,
          ),
        ],
      ),
      body: groupedInvoices.isEmpty
          ? const Center(child: Text('No invoices found.'))
          : ListView(
        children: groupedInvoices.entries.map((entry) {
          final dateStr = entry.key;
          final invoices = entry.value;
          final allSelected = invoices.every((inv) => selectedInvoiceKeys.contains(inv.key));
          final expanded = expandedGroups[dateStr] ?? true;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      setState(() {
                        expandedGroups[dateStr] = !expanded;
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dateStr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        InkWell(
                          onTap: () => _toggleSelectAll(dateStr),
                          child: Row(
                            children: [
                              Icon(
                                allSelected
                                    ? Icons.check_box
                                    : Icons.check_box_outline_blank,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Select All',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          expanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  if (expanded) ...[
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    ...invoices.map((invoice) => Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: selectedInvoiceKeys.contains(invoice.key),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  selectedInvoiceKeys.add(invoice.key);
                                } else {
                                  selectedInvoiceKeys.remove(invoice.key);
                                }
                              });
                            },
                          ),
                          title: Text(
                            'Invoice: ${invoice.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vendor: ${invoice.vendor}'),
                              Text('Customer: ${invoice.customer}'),
                              Text('Total: ${invoice.total.toCurrencyString()}'),
                              Text('Time: ${_formatTime(invoice.date)}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () => _editInvoice(invoice),
                                tooltip: 'Edit',
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.grey),
                                onPressed: () => _showInvoiceInfo(invoice),
                                tooltip: 'Info',
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    )),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download, color: Colors.white),
                              label: const Text(
                                'Export Selected as CSV',
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: _selectedInvoices.isEmpty ? null : _exportSelectedAsCsv,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.share, color: Colors.white),
                              label: const Text(
                                'Share CSV',
                                style: TextStyle(color: Colors.white),
                              ),
                              onPressed: _selectedInvoices.isEmpty ? null : _shareCsv,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
