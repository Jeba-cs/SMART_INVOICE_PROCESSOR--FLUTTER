import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeepSeekService {
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('deepseek_api_key');
  }

  // Helper to extract JSON from markdown code block
  String extractJsonFromMarkdown(String content) {
    final regex = RegExp(r'``````');
    final match = regex.firstMatch(content);
    if (match != null) {
      return match.group(1)!.trim();
    }
    // Try to find first { ... } block if no code block
    final curly = RegExp(r'(\{[\s\S]*\})');
    final curlyMatch = curly.firstMatch(content);
    if (curlyMatch != null) return curlyMatch.group(1)!.trim();
    return content.trim();
  }

  Future<Map<String, dynamic>> hybridExtract(String rawText) async {
    final apiKey = await getApiKey();
    if (apiKey == null) throw Exception('API Key not set');
    final url = Uri.parse('https://api.deepseek.com/v1/chat/completions');
    const systemPrompt = '''
Extract invoice number, date, vendor, customer, line items, subtotal, tax, total, and output as plain JSON (no markdown, no backticks, no explanation). Return only valid JSON.
''';
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': rawText}
        ],
        'temperature': 0.2,
        'max_tokens': 2000
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices'][0]['message']['content'];
      final jsonString = extractJsonFromMarkdown(content);
      try {
        return jsonDecode(jsonString);
      } catch (e) {
        throw Exception('Failed to parse JSON from LLM: $e\n$content');
      }
    } else {
      throw Exception('DeepSeek LLM error: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> extractInvoiceData(File imageFile) async {
    final apiKey = await getApiKey();
    if (apiKey == null) throw Exception('API Key not set');
    final url = Uri.parse('https://api.deepseek.com/v1/vision');
    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));
    final response = await request.send();
    final respStr = await response.stream.bytesToString();
    if (response.statusCode == 200) {
      return jsonDecode(respStr);
    } else {
      throw Exception('DeepSeek API error: $respStr');
    }
  }
}
