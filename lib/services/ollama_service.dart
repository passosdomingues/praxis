import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:praxis/services/ai_service.dart';

class OllamaService implements AIService {
  final String baseUrl;
  final String model;

  const OllamaService({
    this.baseUrl = 'http://localhost:11434',
    this.model = 'mistral',
  });

  String get _api => '$baseUrl/api';

  @override
  String get providerName => 'Ollama (Local)';

  @override
  String get activeModel => model;

  Future<bool> isRunning() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/tags'))
          .timeout(const Duration(seconds: 3));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Returns a list of model names available in this Ollama instance.
  Future<List<String>> listModels() async {
    try {
      final response = await http
          .get(Uri.parse('$_api/tags'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List models = data['models'] ?? [];
        return models
            .map<String>((m) => m['name'].toString())
            .toList()
          ..sort();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> isModelAvailable() async {
    final models = await listModels();
    final base = model.split(':')[0].toLowerCase();
    return models.any((m) => m.toLowerCase().startsWith(base));
  }

  Future<String> generateResponse(
    String prompt, {
    String? systemPrompt,
    String? contextJson,
  }) async {
    try {
      final url = Uri.parse('$_api/generate');

      String combinedSystem = systemPrompt ?? '';
      if (contextJson != null) {
        combinedSystem +=
            '\n\nCRITICAL: You have full visibility of the board state.\n'
            'Current State: $contextJson\n\n'
            'You can propose board actions by including a JSON block in your response.\n'
            'Supported Actions:\n'
            '- {"type": "MOVE", "data": {"card_id": ID, "new_column": COL_ID}}\n'
            '- {"type": "CREATE", "data": {"title": "text", "description": "text", "points": INT, "column": COL_ID}}\n'
            '- {"type": "EDIT", "data": {"card_id": ID, "title": "text", "points": INT}}\n'
            'Columns: 0=Backlog, 1=To Do, 2=In Progress, 3=Done.\n'
            'Respond naturally, then include proposed actions in a ```json [...] ``` block at the end if needed.';
      }

      final body = jsonEncode({
        'model': model,
        'prompt': prompt,
        'system': combinedSystem,
        'stream': false,
      });

      final response =
          await http.post(url, body: body).timeout(const Duration(minutes: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] as String? ?? '';
      } else {
        return 'Error: Ollama returned status ${response.statusCode}.';
      }
    } catch (e) {
      return 'Error: Could not connect to Ollama at $baseUrl. Is it running?';
    }
  }

  Stream<String> generateChatStream(
      List<Map<String, String>> messages) async* {
    try {
      final url = Uri.parse('$_api/chat');
      final request = http.Request('POST', url);
      request.body = jsonEncode({
        'model': model,
        'messages': messages,
        'stream': true,
      });

      final response = await http.Client().send(request);

      if (response.statusCode == 200) {
        await for (final chunk
            in response.stream.transform(utf8.decoder)) {
          final lines = chunk.split('\n');
          for (final line in lines) {
            if (line.trim().isEmpty) continue;
            try {
              final data = jsonDecode(line);
              final content =
                  data['message']?['content'] as String?;
              if (content != null && content.isNotEmpty) {
                yield content;
              }
              if (data['done'] == true) return;
            } catch (_) {
              // Ignore partial JSON chunks
            }
          }
        }
      } else {
        yield 'Error: Ollama returned status ${response.statusCode}.';
      }
    } catch (e) {
      yield 'Error: Could not connect to Ollama at $baseUrl.';
    }
  }
}
