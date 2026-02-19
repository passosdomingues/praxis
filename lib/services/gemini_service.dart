import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:praxis/services/ai_service.dart';

/// Google Gemini Flash via the REST API.
///
/// Endpoint: POST https://generativelanguage.googleapis.com/v1beta/models/<model>:generateContent?key=<apiKey>
class GeminiService implements AIService {
  final String apiKey;
  final String model;

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Reasonable models available via the free API
  static const List<String> availableModels = [
    'gemini-1.5-flash-latest',
    'gemini-1.5-flash-8b-latest',
    'gemini-1.5-pro-latest',
    'gemini-2.0-flash-lite',
  ];

  const GeminiService({
    required this.apiKey,
    this.model = 'gemini-1.5-flash-latest',
  });

  @override
  String get providerName => 'Google Gemini';

  @override
  String get activeModel => model;

  @override
  Future<bool> isRunning() async {
    if (apiKey.isEmpty) return false;
    // Light check: try hitting the model list endpoint
    try {
      final res = await http
          .get(
            Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey'),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> listModels() async => availableModels;

  @override
  Future<String> generateResponse(
    String prompt, {
    String? systemPrompt,
    String? contextJson,
  }) async {
    if (apiKey.isEmpty) {
      return 'Gemini API key not configured. Add it in Settings.';
    }

    final contents = <Map<String, dynamic>>[];

    // Build system + context block if present
    String userText = prompt;
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      userText = '$systemPrompt\n\n$userText';
    }
    if (contextJson != null) {
      userText +=
          '\n\nCurrent board state:\n$contextJson\n\n'
          'You can propose board actions by including a JSON block in your response.\n'
          'Supported Actions:\n'
          '- {"type": "MOVE", "data": {"card_id": ID, "new_column": COL_ID}}\n'
          '- {"type": "CREATE", "data": {"title": "text", "description": "text", "points": INT, "column": COL_ID}}\n'
          '- {"type": "EDIT", "data": {"card_id": ID, "title": "text", "points": INT}}\n'
          'Columns: 0=Backlog, 1=To Do, 2=In Progress, 3=Done.\n'
          'Respond naturally, then include proposed actions in a ```json [...] ``` block if needed.';
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': userText}
      ]
    });

    final body = json.encode({
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 1024,
      },
    });

    try {
      final res = await http
          .post(
            Uri.parse('$_baseUrl/$model:generateContent?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text?.toString() ?? 'No response from Gemini.';
      } else {
        final error = json.decode(res.body);
        final msg = error['error']?['message'] ?? 'Unknown error';
        return 'Gemini error ${res.statusCode}: $msg';
      }
    } catch (e) {
      debugPrint('GeminiService error: $e');
      return 'Error contacting Gemini: $e';
    }
  }
}
