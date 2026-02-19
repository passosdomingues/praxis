import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:praxis/models/task_card.dart';
import 'package:praxis/utils/constants.dart';
import 'package:praxis/ui/widgets/glass_container.dart';

class TaskCardWidget extends StatelessWidget {
  final TaskCard card;
  final VoidCallback onTap;

  const TaskCardWidget({super.key, required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final labelColor = AppConstants.labelColors[card.labelColorIndex % AppConstants.labelColors.length];
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GlassContainer(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        opacity: 0.1,
        blur: 10,
        borderRadius: BorderRadius.circular(16),
        border: card.isAi 
          ? Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3), width: 1.0)
          : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: Colors.white.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: labelColor,
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                            BoxShadow(color: labelColor.withOpacity(0.5), blurRadius: 4, offset: const Offset(0, 2))
                        ]
                      ),
                    ),
                    if (card.isAi)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3), width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 10, color: Theme.of(context).colorScheme.secondary),
                            const SizedBox(width: 4),
                            Text(
                              'AI',
                              style: TextStyle(
                                fontSize: 9, 
                                fontWeight: FontWeight.bold, 
                                color: Theme.of(context).colorScheme.secondary,
                                letterSpacing: 1.0
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    if (card.points > 0)
                      Text(
                        '${card.points} pts',
                        style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.w900, 
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
                            letterSpacing: 0.5
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  card.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (card.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                        card.description,
                        style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6), height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                    ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (card.dueDate != null) ...[
                        Icon(Icons.calendar_today_outlined, size: 12, color: Colors.white.withOpacity(0.4)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d').format(card.dueDate!),
                          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.w500),
                        ),
                    ],
                    const Spacer(),
                    Icon(Icons.more_horiz, size: 16, color: Colors.white.withOpacity(0.2)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
