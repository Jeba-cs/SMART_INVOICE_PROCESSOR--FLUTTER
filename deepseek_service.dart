import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class DeepSeekService {
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('deepseek_api_key');
  }

  String extractJsonFromMarkdown(String content) {
    // 1. First try to extract JSON from code blocks
    final codeBlockRegex = RegExp(r'``````');
    final codeBlockMatch = codeBlockRegex.firstMatch(content);
    if (codeBlockMatch != null && codeBlockMatch.groupCount >= 1) {
      return codeBlockMatch.group(1)!.trim();
    }

    // 2. If no code block, try to find JSON between curly braces
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return content.substring(start, end + 1);
    }

    // 3. Fallback: Return cleaned content
    return content
        .replaceAll(RegExp(r'^[^{]*'), '') // Remove non-JSON prefix
        .replaceAll(RegExp(r'[^}]*$'), '') // Remove non-JSON suffix
        .trim();
  }

  Future<Map<String, dynamic>> hybridExtract(String rawText) async {
    final apiKey = await getApiKey();
    if (apiKey == null) throw Exception('API Key not set');

    const systemPrompt = '''
Extract invoice data and return ONLY valid JSON without any markdown formatting.
Required fields:
- invoice_number (string)
- date (YYYY-MM-DD)
- vendor (string)
- customer (string)
- line_items (array of objects with: description, quantity, unit_price, tax_rate, total)
- subtotal (number)
- tax (number)
- total (number)

Return format:
{
  "invoice_number": "INV-123",
  "date": "2023-01-01",
  "vendor": "Vendor Name",
  "customer": "Customer Name",
  "line_items": [
    {
      "description": "Item 1",
      "quantity": 2,
      "unit_price": 10.50,
      "tax_rate": 0.07,
      "total": 22.47
    }
  ],
  "subtotal": 21.00,
  "tax": 1.47,
  "total": 22.47
}
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.deepseek.com/v1/chat/completions'),
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
          'temperature': 0.1,
          'max_tokens': 2000
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final jsonString = extractJsonFromMarkdown(content);

        try {
          return jsonDecode(jsonString) as Map<String, dynamic>;
        } catch (e) {
          throw Exception('Failed to parse JSON: $e\nExtracted content: $jsonString');
        }
      } else {
        throw Exception('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Request failed: $e');
    }
  }
}
