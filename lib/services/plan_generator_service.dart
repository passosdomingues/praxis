import 'dart:convert';
import 'package:praxis/models/task_card.dart';
import 'package:praxis/models/sprint.dart';
import 'package:praxis/services/ai_service.dart';

class PlanGeneratorService {
  final AIService _ai;

  PlanGeneratorService(this._ai);

  String generatePlanMarkdown(Sprint? sprint, List<TaskCard> cards) {
    if (sprint == null) return "# No Active Sprint";

    final buffer = StringBuffer();
    buffer.writeln("# Implementation Plan: ${sprint.name}");
    buffer.writeln("Sprint Range: ${sprint.formattedRange}\n");

    buffer.writeln("## To Do");
    for (var card in cards.where((c) => c.columnId == 1)) {
      buffer.writeln("- [ ] **${card.title}** (${card.points} pts)");
      if (card.description.isNotEmpty) {
        buffer.writeln("    > ${card.description.replaceAll('\n', '\n    > ')}");
      }
    }

    buffer.writeln("\n## In Progress");
    for (var card in cards.where((c) => c.columnId == 2)) {
      buffer.writeln("- [/] **${card.title}** (${card.points} pts)");
      if (card.description.isNotEmpty) {
        buffer.writeln("    > ${card.description.replaceAll('\n', '\n    > ')}");
      }
    }
    
    buffer.writeln("\n## Done");
    for (var card in cards.where((c) => c.columnId == 3)) {
      buffer.writeln("- [x] **${card.title}** (${card.points} pts)");
    }
    
    return buffer.toString();
  }

  // 100% REGEX - SEM AI, SEM ollama_dart
  Future<List<Map<String,dynamic>>> parsePlanWithAI(String markdown) async {
    return parseMarkdownRegex(markdown);
  }

  List<Map<String, dynamic>> parseMarkdownRegex(String markdown) {
    final lines = markdown.split('\n');
    List<Map<String, dynamic>> tasks = [];
    
    String? currentTitle;
    String currentDesc = "";
    int currentPoints = 1;
    String currentStatus = 'todo';
    
    void flush() {
      if (currentTitle != null) {
        tasks.add({
          'title': currentTitle,
          'description': currentDesc.trim(),
          'points': currentPoints,
          'status': currentStatus
        });
      }
      currentTitle = null;
      currentDesc = "";
      currentPoints = 1;
    }

    final taskRegex = RegExp(r'^\s*-\s*\[([ x/])\]\s*(?:\*\*)?(.*?)(?:\*\*)?\s*(?:\((\d+)\s*pts\))?$');
    
    for (var line in lines) {
      final taskMatch = taskRegex.firstMatch(line);
      if (taskMatch != null) {
        flush();
        
        final mark = taskMatch.group(1);
        if (mark == ' ') currentStatus = 'todo';
        else if (mark == '/') currentStatus = 'in_progress';
        else if (mark == 'x') currentStatus = 'done';
        
        currentTitle = taskMatch.group(2)?.trim();
        final ptsGroup = taskMatch.group(3);
        if (ptsGroup != null) {
          currentPoints = int.tryParse(ptsGroup) ?? 1;
        }
      } else if (line.trim().startsWith('>')) {
        currentDesc += "${line.trim().substring(1).trim()} ";
      }
    }
    flush();
    return tasks;
  }
}
