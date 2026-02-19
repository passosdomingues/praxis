import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:praxis/services/app_provider.dart';
import 'package:praxis/theme/app_theme.dart';
import 'package:praxis/ui/widgets/glass_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  String? _selectedModel;
  List<String> _models = [];
  bool _isTesting = false;
  bool? _testResult;
  bool _isSaving = false;
  bool _isLoadingModels = false;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _urlController = TextEditingController(text: provider.currentOllamaUrl);
    _selectedModel = provider.currentModel;
    _models = provider.availableModels;
    if (_models.isEmpty) {
      _fetchModels();
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    await _fetchModels();
    setState(() {
      _isTesting = false;
      _testResult = _models.isNotEmpty;
    });
  }

  Future<void> _fetchModels() async {
    setState(() => _isLoadingModels = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    // Temporarily apply the typed URL for fetching
    await provider.applySettings(_urlController.text.trim(), provider.currentModel);
    final models = await provider.refreshModels();
    setState(() {
      _models = models;
      _isLoadingModels = false;
      if (_selectedModel == null && models.isNotEmpty) {
        _selectedModel = models.first;
      }
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.applySettings(
      _urlController.text.trim(),
      _selectedModel ?? provider.currentModel,
    );
    setState(() => _isSaving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(40),
      child: GlassContainer(
        opacity: 0.15,
        blur: 30,
        borderRadius: BorderRadius.circular(24),
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.settings_outlined,
                      color: AppTheme.accent, size: 22),
                  const SizedBox(width: 12),
                  Text('Settings',
                      style: theme.textTheme.displayMedium?.copyWith(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Section: Ollama Server
              _buildSectionLabel('AI Engine — Ollama'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Ollama Server URL',
                        hintText: 'http://localhost:11434',
                        prefixIcon: Icon(Icons.link, size: 18, color: Colors.white38),
                      ),
                      onSubmitted: (_) => _testConnection(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _isTesting
                        ? const Padding(
                            padding: EdgeInsets.all(14),
                            child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : OutlinedButton(
                            onPressed: _testConnection,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                            ),
                            child: const Text('Test'),
                          ),
                  ),
                ],
              ),

              if (_testResult != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _testResult! ? Icons.check_circle : Icons.error_outline,
                      size: 14,
                      color:
                          _testResult! ? Colors.greenAccent : Colors.redAccent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _testResult!
                          ? 'Connected — ${_models.length} model(s) found'
                          : 'Connection failed. Is Ollama running?',
                      style: TextStyle(
                        fontSize: 12,
                        color: _testResult!
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),

              // Section: Model Selector
              Row(
                children: [
                  _buildSectionLabel('Active Model'),
                  const Spacer(),
                  if (_isLoadingModels)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  TextButton.icon(
                    onPressed: _isLoadingModels ? null : _fetchModels,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_models.isEmpty && !_isLoadingModels)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.orangeAccent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No models found. Connect to Ollama or run:\noллама pull mistral',
                          style: const TextStyle(fontSize: 12, color: Colors.orangeAccent),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_models.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _models.contains(_selectedModel)
                      ? _selectedModel
                      : _models.first,
                  dropdownColor: AppTheme.bgSurface,
                  decoration: const InputDecoration(
                    prefixIcon:
                        Icon(Icons.smart_toy_outlined, size: 18, color: Colors.white38),
                  ),
                  style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
                  items: _models
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedModel = val);
                  },
                ),

              const SizedBox(height: 12),

              // Model info hint
              Text(
                'Run `ollama pull <model>` to download. Popular: mistral, llama3, deepseek-r1, gemma2, phi3',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white38, fontSize: 11),
              ),

              const SizedBox(height: 32),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black))
                        : const Text('Save Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
