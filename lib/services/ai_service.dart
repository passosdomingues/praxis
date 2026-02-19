/// Abstract interface for AI providers (Ollama, Gemini, etc.)
abstract class AIService {
  /// Generate a text response given a user prompt.
  Future<String> generateResponse(
    String prompt, {
    String? systemPrompt,
    String? contextJson,
  });

  /// List available models (for providers that support it).
  Future<List<String>> listModels();

  /// Check if the service is running / reachable.
  Future<bool> isRunning();

  /// Display name shown in the UI.
  String get providerName;

  /// Currently active model identifier.
  String get activeModel;
}
