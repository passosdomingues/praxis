import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:praxis/services/app_provider.dart';
import 'package:praxis/theme/app_theme.dart';
import 'package:praxis/ui/screens/settings_screen.dart';
import 'package:praxis/ui/widgets/burndown_chart.dart';
import 'package:praxis/ui/widgets/scrum_board.dart';
import 'package:praxis/ui/widgets/glass_container.dart';
import 'package:praxis/ui/widgets/history_sidebar.dart';
import 'package:praxis/ui/widgets/plan_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0; // 0=Board, 1=Stats
  bool _showAIChat = false;
  bool _isSM = false;

  // AI Chat history (message, isAI)
  final List<({String text, bool isAi})> _chatHistory = [];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  @override
  void dispose() {
    _chatController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(AppProvider provider, String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _chatHistory.add((text: text.trim(), isAi: false));
      _chatController.clear();
    });
    _scrollChatToBottom();

    await provider.askAI(text.trim(), isSM: _isSM);

    if (mounted && provider.aiMessage.isNotEmpty) {
      setState(() {
        _chatHistory.add((text: provider.aiMessage, isAi: true));
      });
      _scrollChatToBottom();
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    try {
      await provider.exportData();
      if (mounted) {
        _showSnack(context, 'Project exported to Downloads folder.');
      }
    } catch (e) {
      if (mounted) _showSnack(context, 'Export failed: $e', isError: true);
    }
  }

  Future<void> _handleImport(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Praxis Data',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        await Provider.of<AppProvider>(context, listen: false).importData(file);
        if (mounted) _showSnack(context, 'Data imported successfully.');
      } catch (e) {
        if (mounted) _showSnack(context, 'Import failed: $e', isError: true);
      }
    }
  }

  void _showSnack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppTheme.danger : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAddSprintDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    int durationDays = 14;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Sprint'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Sprint Name'),
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: durationDays,
                decoration:
                    const InputDecoration(labelText: 'Duration'),
                dropdownColor: AppTheme.bgSurface,
                items: [7, 14, 21, 30]
                    .map((d) => DropdownMenuItem(
                        value: d, child: Text('$d days')))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => durationDays = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isNotEmpty) {
                  final start = DateTime.now();
                  final end =
                      start.add(Duration(days: durationDays));
                  Provider.of<AppProvider>(context, listen: false)
                      .addSprint(nameCtrl.text.trim(), start, end);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1B2D),
              Color(0xFF1A2940),
              Color(0xFF1E3A4C),
            ],
          ),
        ),
        child: Row(
          children: [
            // -------------------------------------------------------
            // Left Navigation Rail
            // -------------------------------------------------------
            GlassContainer(
              margin: const EdgeInsets.all(10),
              padding: EdgeInsets.zero,
              opacity: 0.08,
              blur: 20,
              borderRadius: BorderRadius.circular(22),
              child: NavigationRail(
                backgroundColor: Colors.transparent,
                selectedIndex: _navIndex,
                onDestinationSelected: (i) =>
                    setState(() => _navIndex = i),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      Text(
                        'pr',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Ax',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.secondary,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Is',
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SCRUM',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: Colors.white38,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.view_kanban_outlined),
                    selectedIcon: Icon(Icons.view_kanban),
                    label: Text('Board'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: Text('Stats'),
                  ),
                ],
                trailing: Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Role toggle
                      _NavIconButton(
                        icon: _isSM
                            ? Icons.manage_accounts
                            : Icons.person_outline,
                        tooltip:
                            'Role: ${_isSM ? "Scrum Master" : "Product Owner"}',
                        color: _isSM
                            ? theme.colorScheme.secondary
                            : theme.colorScheme.primary,
                        onPressed: () =>
                            setState(() => _isSM = !_isSM),
                      ),
                      _NavIconButton(
                        icon: Icons.file_download_outlined,
                        tooltip: 'Export JSON',
                        onPressed: () => _handleExport(context),
                      ),
                      _NavIconButton(
                        icon: Icons.file_upload_outlined,
                        tooltip: 'Import JSON',
                        onPressed: () => _handleImport(context),
                      ),
                      _NavIconButton(
                        icon: Icons.history_edu,
                        tooltip: 'Time Travel',
                        color: provider.isTimeTravelMode
                            ? theme.colorScheme.secondary
                            : null,
                        onPressed: () => provider.toggleTimeTravel(
                            !provider.isTimeTravelMode),
                      ),
                      _NavIconButton(
                        icon: Icons.list_alt_outlined,
                        tooltip: 'Plan',
                        onPressed: () => showDialog(
                            context: context,
                            builder: (_) => const PlanDialog()),
                      ),
                      _NavIconButton(
                        icon: Icons.settings_outlined,
                        tooltip: 'Settings',
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => const SettingsScreen(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // -------------------------------------------------------
            // Main Content
            // -------------------------------------------------------
            Expanded(
              child: Column(
                children: [
                  // Header Bar
                  GlassContainer(
                    margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    opacity: 0.12,
                    blur: 14,
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 58,
                      child: Row(
                        children: [
                          // Sprint info
                          Expanded(
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.activeSprint?.name ??
                                      'No Active Sprint',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (provider.activeSprint != null)
                                  Text(
                                    provider.activeSprint!.formattedRange,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: Colors.white54),
                                  ),
                              ],
                            ),
                          ),

                          // Progress bar
                          if (provider.activeSprint != null) ...[
                            SizedBox(
                              width: 160,
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Sprint Progress',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white38),
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: provider
                                          .activeSprint!.progress,
                                      minHeight: 5,
                                      backgroundColor: Colors.white10,
                                      valueColor:
                                          AlwaysStoppedAnimation(
                                              theme.colorScheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                          ],

                          // New Sprint button
                          FilledButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('New Sprint',
                                style: TextStyle(fontSize: 13)),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white10,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                            ),
                            onPressed: () =>
                                _showAddSprintDialog(context),
                          ),
                          const SizedBox(width: 10),

                          // AI assistant toggle
                          IconButton(
                            icon: Icon(
                              Icons.smart_toy_outlined,
                              color: _showAIChat
                                  ? theme.colorScheme.primary
                                  : Colors.white38,
                            ),
                            tooltip: 'AI Assistant',
                            onPressed: () =>
                                setState(() => _showAIChat = !_showAIChat),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Board / Stats / Loading
                  Expanded(
                    child: Container(
                      margin:
                          const EdgeInsets.fromLTRB(0, 0, 10, 10),
                      child: provider.isLoading
                          ? _buildShimmer(context)
                          : AnimatedSwitcher(
                              duration:
                                  const Duration(milliseconds: 250),
                              child: _navIndex == 1
                                  ? const Padding(
                                      key: ValueKey('stats'),
                                      padding: EdgeInsets.all(20),
                                      child: BurndownChart())
                                  : const Padding(
                                      key: ValueKey('board'),
                                      padding: EdgeInsets.zero,
                                      child: ScrumBoard()),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // -------------------------------------------------------
            // Time Travel Sidebar
            // -------------------------------------------------------
            if (provider.isTimeTravelMode) const HistorySidebar(),

            // -------------------------------------------------------
            // AI Chat Sidebar
            // -------------------------------------------------------
            if (_showAIChat) _buildAiSidebar(context, provider, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSidebar(
      BuildContext context, AppProvider provider, ThemeData theme) {
    final isReady = provider.ollamaRunning && provider.modelAvailable;
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: AppTheme.bgSurface.withOpacity(0.95),
        border: Border(
          left: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Column(
        children: [
          // Chat Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: Colors.white.withOpacity(0.07))),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy_outlined,
                    size: 16,
                    color: isReady
                        ? theme.colorScheme.primary
                        : Colors.white38),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isSM
                            ? 'AI Scrum Master'
                            : 'AI Product Owner',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        isReady
                            ? provider.currentModel
                            : 'Not connected',
                        style: TextStyle(
                          fontSize: 10,
                          color: isReady
                              ? Colors.greenAccent.withOpacity(0.8)
                              : Colors.redAccent.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () =>
                      setState(() => _showAIChat = false),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Autonomy toggle
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                  bottom:
                      BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                Text('Auto-apply actions',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                const Spacer(),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: provider.isAutoApplyEnabled,
                    onChanged: (_) => provider.toggleAutoApply(),
                  ),
                ),
              ],
            ),
          ),

          // Status banners
          if (!provider.ollamaRunning)
            _buildStatusBanner(
              icon: Icons.power_off_outlined,
              title: 'Ollama not running',
              subtitle:
                  'Start Ollama: run `ollama serve` in your terminal.',
              color: Colors.redAccent,
            )
          else if (!provider.modelAvailable)
            _buildStatusBanner(
              icon: Icons.download_for_offline_outlined,
              title: 'Model not found',
              subtitle:
                  'Run: ollama pull ${provider.currentModel}',
              color: Colors.orangeAccent,
            ),

          // Messages
          Expanded(
            child: ListView(
              controller: _chatScroll,
              padding: const EdgeInsets.all(12),
              children: [
                if (_chatHistory.isEmpty && isReady)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text(
                        _isSM
                            ? 'Ask me about impediments,'
                                '\nretros, or team health.'
                            : 'Ask me to prioritize backlog,'
                                '\nclarify requirements, or suggest tasks.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white24, fontSize: 12, height: 1.6),
                      ),
                    ),
                  ),
                ..._chatHistory.map((m) => _buildChatBubble(m, theme)),

                // Thinking indicator
                if (provider.isAiThinking)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Thinking...',
                          style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.primary),
                        ),
                      ],
                    ),
                  ),

                // Pending AI actions
                if (provider.pendingActions.isNotEmpty)
                  _buildPendingActionsCard(provider, theme),
              ],
            ),
          ),

          // Input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    enabled: isReady && !provider.isAiThinking,
                    decoration: InputDecoration(
                      hintText: isReady
                          ? 'Ask your AI ${_isSM ? "Scrum Master" : "Product Owner"}...'
                          : 'Ollama not ready',
                      hintStyle:
                          const TextStyle(fontSize: 12, color: Colors.white24),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onSubmitted: isReady
                        ? (val) => _sendMessage(provider, val)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send_rounded,
                      color: isReady
                          ? theme.colorScheme.primary
                          : Colors.white24),
                  onPressed: (isReady && !provider.isAiThinking)
                      ? () => _sendMessage(
                          provider, _chatController.text)
                      : null,
                  style: IconButton.styleFrom(
                    backgroundColor: isReady
                        ? theme.colorScheme.primary.withOpacity(0.15)
                        : Colors.transparent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(({String text, bool isAi}) msg, ThemeData theme) {
    return Align(
      alignment:
          msg.isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints:
            const BoxConstraints(maxWidth: 268),
        decoration: BoxDecoration(
          color: msg.isAi
              ? Colors.white.withOpacity(0.08)
              : theme.colorScheme.primary.withOpacity(0.25),
          borderRadius: BorderRadius.circular(14).copyWith(
            bottomLeft:
                msg.isAi ? const Radius.circular(2) : null,
            bottomRight:
                !msg.isAi ? const Radius.circular(2) : null,
          ),
        ),
        child: SelectableText(
          msg.text,
          style: const TextStyle(fontSize: 12, height: 1.5),
        ),
      ),
    );
  }

  Widget _buildStatusBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color.withOpacity(0.9)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: color)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingActionsCard(AppProvider provider, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: theme.colorScheme.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.pending_actions,
                  size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              const Text('Proposed Actions',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          ...provider.pendingActions.map((action) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '- ${action["type"]}: '
                  '${action["data"]?["title"] ?? action["data"]?["card_id"] ?? ""}',
                  style: const TextStyle(fontSize: 11),
                ),
              )),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => provider.rejectActions(),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    visualDensity: VisualDensity.compact),
                child: const Text('Reject', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => provider.acceptActions(),
                style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6)),
                child: const Text('Accept', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(
          4,
          (i) => Expanded(
            child: GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              opacity: 0.05,
              blur: 8,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
  }
}

// Small reusable nav icon button
class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _NavIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon,
          color: color ?? Colors.white54, size: 22),
      tooltip: tooltip,
      onPressed: onPressed,
      splashRadius: 20,
    );
  }
}
