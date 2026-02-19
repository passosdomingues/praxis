import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:praxis/models/sprint.dart';
import 'package:praxis/models/task_card.dart';
import 'package:praxis/services/ai_service.dart';
import 'package:praxis/services/database_helper.dart';
import 'package:praxis/services/gemini_service.dart';
import 'package:praxis/services/ollama_service.dart';
import 'package:praxis/services/settings_service.dart';
import 'package:praxis/services/export_import_service.dart';
import 'package:praxis/services/event_store.dart';
import 'package:praxis/services/plan_generator_service.dart';
import 'package:praxis/models/event.dart';
import 'package:uuid/uuid.dart';
import 'package:praxis/services/ai_import_service.dart';

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final ExportImportService _exportImport = ExportImportService();
  final EventStore _eventStore = EventStore();
  final AIImportService _aiImport = AIImportService();

  // Active AI service — swapped when provider/settings change
  AIService _ai = const OllamaService();

  // ------------------------------------------------------------------
  // State
  // ------------------------------------------------------------------
  List<Sprint> sprints = [];
  Sprint? activeSprint;
  List<TaskCard> cards = [];
  bool isLoading = false;

  // AI
  String aiMessage = '';
  bool isAiThinking = false;
  bool aiReady = false;
  List<String> availableModels = [];
  bool ollamaRunning = false;  // kept for Ollama-specific UI
  bool modelAvailable = false;

  AiProvider currentProvider = AiProvider.ollama;
  String currentModel = SettingsService.defaultOllamaModel;
  String currentOllamaUrl = SettingsService.defaultOllamaUrl;
  String geminiApiKey = '';
  String geminiModel = SettingsService.defaultGeminiModel;

  bool isAutoApplyEnabled = false;
  List<Map<String, dynamic>> pendingActions = [];

  // Time travel
  List<Event> _allEvents = [];
  List<Event> get events => _allEvents;
  int? timeTravelIndex;
  bool get isTimeTravelMode => timeTravelIndex != null;

  AppProvider() {
    _init();
  }

  Future<void> _init() async {
    await _loadSettings();
    _eventStore.startPolling();
    await loadData();
    await checkAiStatus();
  }

  Future<void> _loadSettings() async {
    currentProvider = await SettingsService.instance.getAiProvider();
    currentOllamaUrl = await SettingsService.instance.getOllamaUrl();
    currentModel = await SettingsService.instance.getOllamaModel();
    geminiApiKey = await SettingsService.instance.getGeminiApiKey();
    geminiModel = await SettingsService.instance.getGeminiModel();
    _rebuildAiService();
  }

  void _rebuildAiService() {
    if (currentProvider == AiProvider.gemini) {
      _ai = GeminiService(apiKey: geminiApiKey, model: geminiModel);
    } else {
      _ai = OllamaService(baseUrl: currentOllamaUrl, model: currentModel);
    }
  }

  // Convenience for the home_screen AI chat panel
  String get activeProviderName => _ai.providerName;
  String get activeModelName => _ai.activeModel;

  /// Save all AI settings and rebuild the active service.
  Future<void> applyOllamaSettings(String url, String model) async {
    await SettingsService.instance.setOllamaUrl(url);
    await SettingsService.instance.setOllamaModel(model);
    await SettingsService.instance.setAiProvider(AiProvider.ollama);
    currentOllamaUrl = url;
    currentModel = model;
    currentProvider = AiProvider.ollama;
    _rebuildAiService();
    await checkAiStatus();
    notifyListeners();
  }

  Future<void> applyGeminiSettings(String apiKey, String model) async {
    await SettingsService.instance.setGeminiApiKey(apiKey);
    await SettingsService.instance.setGeminiModel(model);
    await SettingsService.instance.setAiProvider(AiProvider.gemini);
    geminiApiKey = apiKey;
    geminiModel = model;
    currentProvider = AiProvider.gemini;
    _rebuildAiService();
    await checkAiStatus();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // AI Status
  // ------------------------------------------------------------------
  Future<void> checkAiStatus() async {
    aiReady = await _ai.isRunning();
    availableModels = aiReady ? await _ai.listModels() : [];

    if (currentProvider == AiProvider.ollama) {
      ollamaRunning = aiReady;
      modelAvailable = aiReady
          ? availableModels.any((m) =>
              m.toLowerCase().startsWith(currentModel.split(':')[0].toLowerCase()))
          : false;
    } else {
      ollamaRunning = false;
      modelAvailable = aiReady;
    }
    notifyListeners();
  }

  Future<List<String>> refreshModels() async {
    availableModels = await _ai.listModels();
    notifyListeners();
    return availableModels;
  }

  // ------------------------------------------------------------------
  // Data
  // ------------------------------------------------------------------
  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();
    try {
      sprints = await _db.getAllSprints();
      activeSprint = await _db.getActiveSprint();
      if (activeSprint != null) {
        cards = await _db.getCardsBySprint(activeSprint!.id!);
      } else {
        cards = [];
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _allEvents = await _eventStore.getAllEvents();
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Time Travel
  // ------------------------------------------------------------------
  Future<void> toggleTimeTravel(bool active) async {
    if (active) {
      await loadHistory();
      timeTravelIndex = _allEvents.length - 1;
      if (timeTravelIndex != null && timeTravelIndex! >= 0) {
        _reconstructState(timeTravelIndex!);
      }
    } else {
      timeTravelIndex = null;
      await loadData();
    }
    notifyListeners();
  }

  void setTimeTravelIndex(int index) {
    if (index < 0 || index >= _allEvents.length) return;
    timeTravelIndex = index;
    _reconstructState(index);
    notifyListeners();
  }

  void _reconstructState(int upToIndex) {
    final List<TaskCard> tempCards = [];
    for (int i = 0; i <= upToIndex; i++) {
      final event = _allEvents[i];
      final p = event.payload;
      if (event.type == 'TASK_CREATED') {
        tempCards.add(TaskCard(
          id: p['id'] as int?,
          sprintId: activeSprint?.id ?? 0,
          columnId: (p['column'] as int?) ?? 0,
          title: (p['title'] as String?) ?? 'No Title',
          description: (p['description'] as String?) ?? '',
          labelColorIndex: (p['labelColorIndex'] as int?) ?? 0,
          points: (p['points'] as int?) ?? 1,
          isAi: (p['isAi'] as bool?) ?? false,
        ));
      } else if (event.type == 'card_move') {
        final id = p['card_id'];
        final newCol = p['new_column'] as int?;
        if (newCol != null) {
          final idx = tempCards.indexWhere((c) => c.id == id);
          if (idx != -1) tempCards[idx].columnId = newCol;
        }
      } else if (event.type == 'TASK_DELETED') {
        final id = p['id'];
        tempCards.removeWhere((c) => c.id == id);
      }
    }
    cards = tempCards;
  }

  // ------------------------------------------------------------------
  // CRUD
  // ------------------------------------------------------------------
  Future<void> addTask(
    String title,
    String description,
    int points,
    int subColumn, {
    bool isAi = false,
    int labelColorIndex = 0,
  }) async {
    if (activeSprint == null) return;
    try {
      final card = TaskCard(
        sprintId: activeSprint!.id!,
        columnId: subColumn,
        title: title,
        description: description,
        labelColorIndex: labelColorIndex,
        points: points,
        isAi: isAi,
      );
      final created = await _db.createCard(card);
      final event = Event(
        uuid: const Uuid().v4(),
        type: 'TASK_CREATED',
        payload: {
          'id': created.id,
          'title': title,
          'description': description,
          'points': points,
          'column': subColumn,
          'labelColorIndex': labelColorIndex,
          'isAi': isAi,
        },
        timestamp: DateTime.now(),
        author: isAi ? 'ai' : 'user',
      );
      await _eventStore.appendEvent(event);
      await loadData();
    } catch (e) {
      debugPrint('Error adding task: $e');
    }
  }

  Future<void> updateCard(TaskCard card) async {
    if (isTimeTravelMode) return;
    try {
      await _db.updateCard(card);
      final event = Event(
        uuid: const Uuid().v4(),
        type: 'TASK_UPDATED',
        payload: {
          'card_id': card.id,
          'title': card.title,
          'description': card.description,
          'points': card.points,
          'labelColorIndex': card.labelColorIndex,
        },
        timestamp: DateTime.now(),
        author: 'user',
      );
      await _eventStore.appendEvent(event);
      await loadData();
    } catch (e) {
      debugPrint('Error updating card: $e');
    }
  }

  Future<void> updateCardStatus(TaskCard card, int newColumnId) async {
    if (isTimeTravelMode) return;
    final oldColumn = card.columnId;
    try {
      final updated = card.copyWith(columnId: newColumnId);
      await _db.updateCard(updated);
      final event = Event(
        uuid: const Uuid().v4(),
        type: 'card_move',
        payload: {
          'card_id': card.id,
          'old_column': oldColumn,
          'new_column': newColumnId,
          'title': card.title,
        },
        timestamp: DateTime.now(),
        author: 'user',
      );
      await _eventStore.appendEvent(event);
      await loadData();
    } catch (e) {
      debugPrint('Error moving card: $e');
    }
  }

  Future<void> deleteCard(int id) async {
    try {
      await _db.deleteCard(id);
      final event = Event(
        uuid: const Uuid().v4(),
        type: 'TASK_DELETED',
        payload: {'id': id},
        timestamp: DateTime.now(),
        author: 'user',
      );
      await _eventStore.appendEvent(event);
      await loadData();
    } catch (e) {
      debugPrint('Error deleting card: $e');
    }
  }

  Future<void> addSprint(String name, DateTime start, DateTime end) async {
    try {
      final sprint = Sprint(
        name: name,
        startDate: start,
        endDate: end,
        isActive: true,
      );
      await _db.createSprint(sprint);
      await loadData();
    } catch (e) {
      debugPrint('Error adding sprint: $e');
    }
  }

  // ------------------------------------------------------------------
  // AI Chat
  // ------------------------------------------------------------------
  Future<void> askAI(String prompt, {bool isSM = false}) async {
    isAiThinking = true;
    notifyListeners();
    try {
      final systemPrompt = isSM
          ? 'You are a Scrum Master. Help the team remove impediments and improve process. Keep answers concise.'
          : 'You are a Product Owner. Prioritize the backlog and clarify requirements. Keep answers concise.';
      final response = await _ai.generateResponse(
        prompt,
        systemPrompt: systemPrompt,
        contextJson: getBoardStateJson(),
      );
      _parseAiActions(response);
      aiMessage = response.replaceAll(RegExp(r'```json[\s\S]*?```'), '').trim();
    } catch (e) {
      aiMessage = 'Error: $e';
    } finally {
      isAiThinking = false;
      notifyListeners();
    }
  }

  void _parseAiActions(String response) {
    final regex = RegExp(r'```json([\s\S]*?)```');
    final matches = regex.allMatches(response);
    pendingActions = [];
    for (var match in matches) {
      try {
        final jsonStr = match.group(1)?.trim() ?? '';
        final dynamic decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          pendingActions.addAll(decoded.cast<Map<String, dynamic>>());
        } else if (decoded is Map) {
          pendingActions.add(decoded.cast<String, dynamic>());
        }
      } catch (e) {
        debugPrint('Failed to parse AI action JSON: $e');
      }
    }
    if (isAutoApplyEnabled && pendingActions.isNotEmpty) {
      executeAiActions(pendingActions);
      pendingActions = [];
    }
  }

  Future<void> executeAiActions(List<dynamic> actions) async {
    for (var action in actions) {
      final type = action['type'];
      final data = action['data'];
      try {
        if (type == 'MOVE') {
          final cardId = data['card_id'];
          final newCol = data['new_column'] as int;
          final card = cards.firstWhere((c) => c.id == cardId);
          await updateCardStatus(card, newCol);
        } else if (type == 'CREATE') {
          await addTask(
            data['title'] as String? ?? 'AI Task',
            data['description'] as String? ?? '',
            data['points'] as int? ?? 1,
            data['column'] as int? ?? 0,
            isAi: true,
          );
        }
      } catch (e) {
        debugPrint('AI Action failed: $e');
      }
    }
    await loadData();
  }

  void toggleAutoApply() {
    isAutoApplyEnabled = !isAutoApplyEnabled;
    notifyListeners();
  }

  void acceptActions() {
    executeAiActions(pendingActions);
    pendingActions = [];
    notifyListeners();
  }

  void rejectActions() {
    pendingActions = [];
    notifyListeners();
  }

  String getBoardStateJson() {
    final state = {
      'active_sprint': activeSprint?.name ?? 'None',
      'cards': cards
          .map((c) => {
                'id': c.id,
                'title': c.title,
                'column': c.columnId,
                'points': c.points,
              })
          .toList(),
    };
    return jsonEncode(state);
  }

  // ------------------------------------------------------------------
  // Plan Generation (used by PlanDialog)
  // ------------------------------------------------------------------
  Future<String> generatePlan() async {
    final gen = PlanGeneratorService(_ai as OllamaService? ?? OllamaService());
    // Generate markdown representation of current board
    return gen.generatePlanMarkdown(activeSprint, cards);
  }

  Future<void> applyPlan(String markdown) async {
    final gen = PlanGeneratorService(_ai as OllamaService? ?? OllamaService());
    final tasks = gen.parseMarkdownRegex(markdown);
    for (var task in tasks) {
      final status = task['status'] as String? ?? 'todo';
      final col = status == 'done'
          ? 3
          : status == 'in_progress'
              ? 2
              : status == 'todo'
                  ? 1
                  : 0;
      await addTask(
        task['title'] as String? ?? 'Imported',
        task['description'] as String? ?? '',
        task['points'] as int? ?? 1,
        col,
      );
    }
  }

  // ------------------------------------------------------------------
  // Import / Export
  // ------------------------------------------------------------------
  Future<void> exportData() async {
    await _exportImport.exportData();
  }

  Future<void> importData(File file) async {
    await _exportImport.importData(file);
    await loadData();
  }

  Future<void> importAITasks(File file) async {
    final tasks = await _aiImport.parseFileContent(file);
    for (var t in tasks) {
      await addTask(
        t['title'] as String? ?? 'Imported',
        t['description'] as String? ?? '',
        t['points'] as int? ?? 1,
        1,
        isAi: true,
      );
    }
  }

  Future<void> applySettings(String url, String model) async {
    await applyOllamaSettings(url, model);  // Reusa lógica existente
  }

}
