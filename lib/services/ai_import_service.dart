import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:praxis/services/ollama_service.dart';

class AIImportService {
  final OllamaService _ollama = OllamaService();

  /// ===============================
  /// PONTO DE ENTRADA
  /// ===============================
  Future<List<Map<String, dynamic>>> parseFileContent(File file) async {
    final extension = file.path.split('.').last.toLowerCase();
    final content = await _readFileSafe(file);

    print("Arquivo: ${file.path}");
    print("Preview:\n${content.substring(0, content.length > 500 ? 500 : content.length)}");

    if (extension == 'json') {
      return _parseJson(content);
    }

    if (extension == 'csv') {
      final csvParsed = _parseCsv(content);
      if (csvParsed.isNotEmpty) {
        return csvParsed;
      }
    }

    // Se falhar no parser estruturado ou for outro formato (txt, md), tenta IA
    return _parseWithAI(content, extension);
  }

  /// ===============================
  /// LEITURA SEGURA (Correção de encoding)
  /// ===============================
  Future<String> _readFileSafe(File file) async {
    try {
      return await file.readAsString();
    } catch (_) {
      // Tenta ler como Latin1 se o UTF-8 falhar (comum em CSVs antigos)
      return await file.readAsString(encoding: latin1);
    }
  }

  /// ===============================
  /// PARSER JSON
  /// ===============================
  Future<List<Map<String, dynamic>>> _parseJson(String content) async {
    try {
      final decoded = jsonDecode(content);

      if (decoded is List) {
        return decoded.map(_standardizeTask).toList();
      }

      if (decoded is Map && decoded['tasks'] is List) {
        return (decoded['tasks'] as List)
            .map(_standardizeTask)
            .toList();
      }
    } catch (e) {
      print("JSON direto falhou, tentando extração por IA: $e");
    }

    return _parseWithAI(content, "json");
  }

  /// ===============================
  /// PARSER CSV
  /// ===============================
  List<Map<String, dynamic>> _parseCsv(String content) {
    try {
      // Removido o 'const' aqui para evitar erro de compilação
      final rows = CsvToListConverter().convert(content);

      if (rows.length < 2) return [];

      final headers = rows.first.map((e) => e.toString().toLowerCase()).toList();

      final titleIndex = headers.indexWhere((h) => h.contains('title') || h.contains('titulo'));
      final descIndex = headers.indexWhere((h) => h.contains('desc'));
      final pointsIndex = headers.indexWhere((h) => h.contains('point') || h.contains('ponto'));

      if (titleIndex == -1) return [];

      final result = <Map<String, dynamic>>[];

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length <= titleIndex) continue;

        result.add({
          'title': row[titleIndex].toString(),
          'description': descIndex != -1 && row.length > descIndex ? row[descIndex].toString() : '',
          'points': pointsIndex != -1 && row.length > pointsIndex
              ? int.tryParse(row[pointsIndex].toString()) ?? 1
              : 1,
        });
      }

      return result;
    } catch (e) {
      print("CSV parse falhou: $e");
      return [];
    }
  }

  /// ===============================
  /// PARSER COM IA (Ollama)
  /// ===============================
  Future<List<Map<String, dynamic>>> _parseWithAI(
    String content,
    String format,
  ) async {
    final truncated = _truncate(content, 6000);

    final systemPrompt = """
Return ONLY a valid JSON array. 
No markdown tags like ```json. 
No text before or after the JSON.
Format: [{"title":"Task Name","description":"details","points":1}]
""";

    final prompt = "Convert this $format content into a list of tasks:\n$truncated";

    // Removido o 'stream: false' para alinhar com sua OllamaService
    final response = await _ollama.generateResponse(
      prompt,
      systemPrompt: systemPrompt,
    );

    print("LLM RAW RESPONSE:\n$response");

    try {
      final jsonStr = _extractJson(response);
      final decoded = jsonDecode(jsonStr);

      if (decoded is! List) throw Exception("Response is not a JSON list");

      return decoded.map(_standardizeTask).toList();
    } catch (e) {
      print("AI Parsing failed: $e");
      return [];
    }
  }

  /// ===============================
  /// UTILITÁRIOS
  /// ===============================

  String _extractJson(String text) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');

    if (start == -1 || end == -1 || end <= start) {
      // Tenta limpar markdown se a IA ignorou o system prompt
      final clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
      if (clean.startsWith('[') && clean.endsWith(']')) return clean;
      throw Exception("JSON structure not found in AI response");
    }

    return text.substring(start, end + 1);
  }

  String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return text.substring(0, maxChars);
  }

  Map<String, dynamic> _standardizeTask(dynamic raw) {
    if (raw is! Map) {
      return {
        'title': 'Tarefa sem título',
        'description': '',
        'points': 1,
      };
    }

    return {
      'title': raw['title']?.toString() ?? 'Tarefa sem título',
      'description': raw['description']?.toString() ?? '',
      'points': int.tryParse(raw['points']?.toString() ?? '1') ?? 1,
    };
  }
}