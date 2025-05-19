import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import '../services/deepseek_service.dart';
import '../widgets/settings_drawer.dart';
import 'multi_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<File> _selectedImages = [];
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
        _selectedImages.clear();
        _selectedImages.addAll(result.paths.whereType<String>().map((p) => File(p)));
      });
    }
  }

  Future<void> _captureImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages.add(File(image.path));
      });
    }
  }

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      File pdfFile = File(result.files.single.path!);
      setState(() => _isProcessing = true);
      try {
        String pdfText = await ocrService.extractTextFromPdf(pdfFile);
        Map<String, dynamic> invoiceJson;
        try {
          invoiceJson = await deepSeekService.hybridExtract(pdfText);
        } catch (e) {
          _showErrorDialog('Processing failed: $e');
          setState(() => _isProcessing = false);
          return;
        }
        if (!mounted) return;
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MultiResultScreen(results: [
            {
              'rawText': pdfText,
              'invoiceJson': invoiceJson,
              'imageFile': null,
              'pdfFile': pdfFile,
            }
          ]),
        ));
      } catch (e) {
        _showErrorDialog('PDF processing failed: $e');
      }
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _processInvoices() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isProcessing = true);
    List<Map<String, dynamic>> invoiceResults = [];
    for (final image in _selectedImages) {
      try {
        String rawText = await ocrService.extractText(image);
        Map<String, dynamic> invoiceJson;
        try {
          invoiceJson = await deepSeekService.hybridExtract(rawText);
        } catch (e) {
          _showErrorDialog('Processing failed: $e');
          invoiceResults.add({
            'rawText': rawText,
            'invoiceJson': {'error': e.toString()},
            'imageFile': image,
          });
          continue;
        }
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
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => MultiResultScreen(results: invoiceResults),
    ));
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error', style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildRectButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 170,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white, size: 28),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          alignment: Alignment.centerLeft,
        ),
        onPressed: onTap,
      ),
    );
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
            icon: const Icon(Icons.receipt_long),
            onPressed: () => Navigator.pushNamed(context, '/invoices'),
            tooltip: 'Invoices',
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
            // Top row with two buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildRectButton(
                  icon: Icons.upload_file,
                  label: 'Upload Images',
                  onTap: _pickImages,
                ),
                _buildRectButton(
                  icon: Icons.camera_alt,
                  label: 'Capture Photo',
                  onTap: _captureImage,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Centered PDF button
            Center(
              child: _buildRectButton(
                icon: Icons.picture_as_pdf,
                label: 'Upload PDF Invoice',
                onTap: _pickPdf,
              ),
            ),
            if (_selectedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _selectedImages
                        .map((img) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(img, height: 80),
                      ),
                    ))
                        .toList(),
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
