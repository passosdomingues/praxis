import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:praxis/services/app_provider.dart';
import 'package:praxis/ui/widgets/glass_container.dart';
import 'package:intl/intl.dart';

class HistorySidebar extends StatelessWidget {
  const HistorySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (!provider.isTimeTravelMode) {
            return const SizedBox.shrink();
        }
        
        final events = provider.events; // Need to expose _allEvents as getter
        final currentIndex = provider.timeTravelIndex ?? 0;
        final currentEvent = events.isNotEmpty && currentIndex < events.length 
            ? events[currentIndex] 
            : null;

        return GlassContainer(
          width: 300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Time Travel", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => provider.toggleTimeTravel(false),
                    )
                  ],
                ),
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final isSelected = index == currentIndex;
                    
                    return InkWell(
                      onTap: () => provider.setTimeTravelIndex(index),
                      child: Container(
                         color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         child: Row(
                           children: [
                             Text(
                               DateFormat('HH:mm').format(event.timestamp),
                               style: const TextStyle(color: Colors.white54, fontSize: 12),
                             ),
                             const SizedBox(width: 10),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(event.type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                                   Text(event.author, style: TextStyle(color: Colors.purple.shade200, fontSize: 10)),
                                 ],
                               ),
                             )
                           ],
                         ),
                      ),
                    );
                  },
                ),
              ),
              if (currentEvent != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Current State at:", style: TextStyle(color: Colors.white70)),
                      Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(currentEvent.timestamp), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
