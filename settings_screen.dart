import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _keyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final prefs = await SharedPreferences.getInstance();
    _keyController.text = prefs.getString('deepseek_api_key') ?? '';
    setState(() {});
  }

  Future<void> _saveKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deepseek_api_key', _keyController.text.trim());
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('API Key Saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('DeepSeek API Key', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _keyController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'API Key'),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save'),
              onPressed: _saveKey,
            ),
          ],
        ),
      ),
    );
  }
}
