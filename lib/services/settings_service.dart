import 'package:shared_preferences/shared_preferences.dart';

enum AiProvider { ollama, gemini }

class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  static const String defaultOllamaUrl = 'http://localhost:11434';
  static const String defaultOllamaModel = 'mistral';
  static const String defaultGeminiModel = 'gemini-1.5-flash-latest';

  static const _keyOllamaUrl = 'pref_ollama_url';
  static const _keyOllamaModel = 'pref_ollama_model';
  static const _keyAiProvider = 'pref_ai_provider';
  static const _keyGeminiKey = 'pref_gemini_key';
  static const _keyGeminiModel = 'pref_gemini_model';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ------------------------------------------------------------------
  // AI Provider selection
  // ------------------------------------------------------------------
  Future<AiProvider> getAiProvider() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_keyAiProvider);
    if (raw == 'gemini') return AiProvider.gemini;
    return AiProvider.ollama;
  }

  Future<void> setAiProvider(AiProvider provider) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAiProvider, provider.name);
  }

  // ------------------------------------------------------------------
  // Ollama
  // ------------------------------------------------------------------
  Future<String> getOllamaUrl() async {
    final prefs = await _prefs;
    return prefs.getString(_keyOllamaUrl) ?? defaultOllamaUrl;
  }

  Future<void> setOllamaUrl(String url) async {
    final prefs = await _prefs;
    await prefs.setString(_keyOllamaUrl, url);
  }

  Future<String> getOllamaModel() async {
    final prefs = await _prefs;
    return prefs.getString(_keyOllamaModel) ?? defaultOllamaModel;
  }

  Future<void> setOllamaModel(String model) async {
    final prefs = await _prefs;
    await prefs.setString(_keyOllamaModel, model);
  }

  // ------------------------------------------------------------------
  // Google Gemini
  // ------------------------------------------------------------------
  Future<String> getGeminiApiKey() async {
    final prefs = await _prefs;
    return prefs.getString(_keyGeminiKey) ?? '';
  }

  Future<void> setGeminiApiKey(String key) async {
    final prefs = await _prefs;
    await prefs.setString(_keyGeminiKey, key);
  }

  Future<String> getGeminiModel() async {
    final prefs = await _prefs;
    return prefs.getString(_keyGeminiModel) ?? defaultGeminiModel;
  }

  Future<void> setGeminiModel(String model) async {
    final prefs = await _prefs;
    await prefs.setString(_keyGeminiModel, model);
  }
}
