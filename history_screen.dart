import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/storage_service.dart';
import '../models/invoice.dart';
import '../services/csv_export_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Map<String, List<Invoice>> _groupedInvoices = {};
  Map<String, Set<String>> _selectedInvoices = {};

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    final invoices = await StorageService().getInvoices();
    final grouped = <String, List<Invoice>>{};
    for (final invoice in invoices) {
      final dateKey = DateFormat('yyyy-MM-dd').format(invoice.date);
      grouped.putIfAbsent(dateKey, () => []).add(invoice);
    }
    setState(() {
      _groupedInvoices = grouped;
      _selectedInvoices = {
        for (var date in grouped.keys) date: <String>{}
      };
    });
  }

  void _toggleSelect(String date, String invoiceId) {
    setState(() {
      if (_selectedInvoices[date]!.contains(invoiceId)) {
        _selectedInvoices[date]!.remove(invoiceId);
      } else {
        _selectedInvoices[date]!.add(invoiceId);
      }
    });
  }

  void _selectAll(String date) {
    setState(() {
      if (_selectedInvoices[date]!.length == _groupedInvoices[date]!.length) {
        _selectedInvoices[date]!.clear();
      } else {
        _selectedInvoices[date] = _groupedInvoices[date]!.map((e) => e.id).toSet();
      }
    });
  }

  Future<void> _exportSelectedAsCsv(String date) async {
    final selected = _groupedInvoices[date]!
        .where((inv) => _selectedInvoices[date]!.contains(inv.id))
        .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one invoice.')),
      );
      return;
    }
    try {
      // Save to Downloads directory for user visibility
      final downloadsDir = await getExternalStorageDirectory(); // fallback if getDownloadsDirectory not available
      final formattedDate = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final path = '${downloadsDir!.path}/INVOICE_$formattedDate.csv';
      final savedPath = await CsvExportService().exportInvoicesToCustomCsv(selected, customPath: path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV exported to $savedPath')),
      );
      setState(() {
        _selectedInvoices[date]!.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV export failed: $e')),
      );
    }
  }

  Future<void> _shareSelectedAsCsv(String date) async {
    final selected = _groupedInvoices[date]!
        .where((inv) => _selectedInvoices[date]!.contains(inv.id))
        .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one invoice.')),
      );
      return;
    }
    try {
      final tempDir = await getTemporaryDirectory();
      final formattedDate = DateFormat('yyyy-MM-dd_HH-mm').format(DateTime.now());
      final path = '${tempDir.path}/INVOICE_$formattedDate.csv';
      final savedPath = await CsvExportService().exportInvoicesToCustomCsv(selected, customPath: path);
      await Share.shareXFiles([XFile(savedPath)], text: 'Invoices exported on $date');
      setState(() {
        _selectedInvoices[date]!.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV share failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F8FD), Color(0xFFE3F0FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _groupedInvoices.isEmpty
            ? const Center(child: Text('No invoices processed yet.'))
            : ListView(
          children: _groupedInvoices.entries.map((entry) {
            final date = entry.key;
            final invoices = entry.value;
            return Card(
              margin: const EdgeInsets.all(8),
              child: ExpansionTile(
                initiallyExpanded: true,
                title: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        DateFormat('EEE, MMM d, yyyy').format(DateTime.parse(date)),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: TextButton.icon(
                        icon: const Icon(Icons.select_all, color: Colors.blue, size: 20),
                        label: const Text('Select All', style: TextStyle(color: Colors.blue)),
                        onPressed: () => _selectAll(date),
                        style: TextButton.styleFrom(
                          minimumSize: Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                  ],
                ),
                children: [
                  ...invoices.map((invoice) {
                    final selected = _selectedInvoices[date]!.contains(invoice.id);
                    return ListTile(
                      leading: Checkbox(
                        value: selected,
                        onChanged: (_) => _toggleSelect(date, invoice.id),
                      ),
                      title: Text(
                        'Invoice: ${invoice.jsonData['invoice_number'] ?? invoice.jsonData['invoice no'] ?? invoice.id}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Vendor: ${invoice.vendor}\nCustomer: ${invoice.customer}\nTotal: ${invoice.total}\nTime: ${DateFormat('HH:mm').format(invoice.date)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.info_outline, color: Colors.blue),
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
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.download, color: Colors.white),
                            label: const Text('Export Selected as CSV'),
                            onPressed: () => _exportSelectedAsCsv(date),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.share, color: Colors.white),
                            label: const Text('Share CSV'),
                            onPressed: () => _shareSelectedAsCsv(date),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
