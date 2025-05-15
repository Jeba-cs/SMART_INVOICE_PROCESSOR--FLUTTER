import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/ocr_service.dart';
import '../services/deepseek_service.dart';
import '../models/invoice.dart';
import '../widgets/settings_drawer.dart';
import 'result_screen.dart';
import 'multi_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<File> _selectedImages = [];
  bool _isProcessing = false;

  final ocrService = OCRService();
  final deepSeekService = DeepSeekService();

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        _selectedImages = result.paths.whereType<String>().map((p) => File(p)).toList();
      });
    }
  }

  Future<void> _processInvoices() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isProcessing = true);
    List<Map<String, dynamic>> invoiceResults = [];
    for (final image in _selectedImages) {
      try {
        String rawText = await ocrService.extractText(image);
        Map<String, dynamic> invoiceJson = await deepSeekService.hybridExtract(rawText);
        invoiceResults.add({
          'rawText': rawText,
          'invoiceJson': invoiceJson,
          'imageFile': image,
        });
      } catch (e) {
        invoiceResults.add({
          'rawText': '',
          'invoiceJson': {'error': e.toString()},
          'imageFile': image,
        });
      }
    }
    setState(() => _isProcessing = false);
    if (context.mounted) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MultiResultScreen(results: invoiceResults),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Invoice Processor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/history'),
            tooltip: 'Invoice History',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      drawer: const SettingsDrawer(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5F8FD), Color(0xFFE3F0FB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Invoice Images'),
              onPressed: _pickImages,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
              ),
            ),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _selectedImages.map((img) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(img, height: 80),
                      ),
                    )).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processInvoices,
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Process Invoices (OCR + LLM)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: const Size(220, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// You will also need to create a MultiResultScreen to show results for multiple invoices!
