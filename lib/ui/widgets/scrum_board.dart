import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:praxis/models/task_card.dart';
import 'package:praxis/services/app_provider.dart';
import 'package:praxis/utils/constants.dart';
import 'package:praxis/ui/widgets/task_card_widget.dart';
import 'package:praxis/ui/widgets/glass_container.dart';
import 'package:praxis/theme/app_theme.dart';

class ScrumBoard extends StatelessWidget {
  const ScrumBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final cards = provider.cards;

    final List<List<TaskCard>> columns = List.generate(4, (_) => []);
    for (var card in cards) {
      if (card.columnId >= 0 && card.columnId < 4) {
        columns[card.columnId].add(card);
      }
    }

    return DragAndDropLists(
      axis: Axis.horizontal,
      listWidth: 300,
      listDraggingWidth: 300,
      listPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemDragOnLongPress: false,
      itemDragHandle: const DragHandle(
        onLeft: true,
        child: Padding(
          padding: EdgeInsets.only(right: 10),
          child: Icon(Icons.drag_indicator, color: Colors.white24, size: 18),
        ),
      ),
      children: List.generate(4, (index) {
        final colPoints = columns[index].fold<int>(0, (s, c) => s + c.points);
        return DragAndDropList(
          header: GlassContainer(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            opacity: 0.05,
            blur: 8,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppConstants.columns[index].toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.9),
                  ),
                ),
                Row(
                  children: [
                    if (colPoints > 0) ...[
                      Text(
                        '${colPoints}pts',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.white38),
                      ),
                      const SizedBox(width: 8),
                    ],
                    GlassContainer(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      opacity: 0.1,
                      borderRadius: BorderRadius.circular(12),
                      child: Text(
                        '${columns[index].length}',
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          children: columns[index].isEmpty
              ? [
                  DragAndDropItem(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined,
                                color: Colors.white10, size: 40),
                            const SizedBox(height: 8),
                            const Text(
                              'Empty',
                              style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ]
              : columns[index].map((card) {
                  return DragAndDropItem(
                    child: TaskCardWidget(
                      card: card,
                      onTap: () => _showEditCardDialog(context, card),
                    ),
                  );
                }).toList(),
          footer: _buildFooter(context, index),
        );
      }),
      onItemReorder: (oldItemIndex, oldListIndex, newItemIndex, newListIndex) {
        if (columns[oldListIndex].isEmpty) return;
        final card = columns[oldListIndex][oldItemIndex];
        if (card.columnId != newListIndex) {
          provider.updateCardStatus(card, newListIndex);
        }
      },
      onListReorder: (_, __) {},
      listDecoration: BoxDecoration(
        color: Colors.black.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, int columnIndex) {
    // Allow adding cards to Backlog and To Do columns
    if (columnIndex == 0 || columnIndex == 1) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: OutlinedButton.icon(
          onPressed: () => _showAddCardDialog(context, columnIndex),
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Add Card', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white54,
            side: const BorderSide(color: Colors.white10),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }

  void _showAddCardDialog(BuildContext context, int columnIndex) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int points = 1;
    int labelColorIndex = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('New Card — ${AppConstants.columns[columnIndex]}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: points,
                  dropdownColor: AppTheme.bgSurface,
                  decoration: const InputDecoration(labelText: 'Story Points'),
                  items: [1, 2, 3, 5, 8, 13]
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text('$p pts')))
                      .toList(),
                  onChanged: (val) => setDialogState(() => points = val!),
                ),
                const SizedBox(height: 16),
                const Text('Label Color',
                    style: TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 8),
                _buildColorPicker(
                    labelColorIndex,
                    (i) => setDialogState(() => labelColorIndex = i)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isNotEmpty) {
                  Provider.of<AppProvider>(context, listen: false).addTask(
                    titleController.text.trim(),
                    descController.text.trim(),
                    points,
                    columnIndex,
                    labelColorIndex: labelColorIndex,
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Add Card'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCardDialog(BuildContext context, TaskCard card) {
    final titleController = TextEditingController(text: card.title);
    final descController = TextEditingController(text: card.description);
    int points = card.points;
    int labelColorIndex = card.labelColorIndex;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: points,
                  dropdownColor: AppTheme.bgSurface,
                  decoration: const InputDecoration(labelText: 'Story Points'),
                  items: [1, 2, 3, 5, 8, 13]
                      .map((p) => DropdownMenuItem(
                          value: p, child: Text('$p pts')))
                      .toList(),
                  onChanged: (val) => setDialogState(() => points = val!),
                ),
                const SizedBox(height: 16),
                const Text('Label Color',
                    style: TextStyle(fontSize: 12, color: Colors.white54)),
                const SizedBox(height: 8),
                _buildColorPicker(
                    labelColorIndex,
                    (i) => setDialogState(() => labelColorIndex = i)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Provider.of<AppProvider>(context, listen: false)
                    .deleteCard(card.id!);
              },
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.danger)),
            ),
            const Spacer(),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final updated = card.copyWith(
                  title: titleController.text.trim(),
                  description: descController.text.trim(),
                  points: points,
                  labelColorIndex: labelColorIndex,
                );
                Provider.of<AppProvider>(context, listen: false)
                    .updateCard(updated);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildColorPicker(
      int selectedIndex, ValueChanged<int> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(AppConstants.labelColors.length, (i) {
        final color = AppConstants.labelColors[i];
        final selected = i == selectedIndex;
        return GestureDetector(
          onTap: () => onSelect(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                          color: color.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 1)
                    ]
                  : [],
            ),
            child: selected
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : null,
          ),
        );
      }),
    );
  }
}
