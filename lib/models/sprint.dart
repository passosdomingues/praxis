import 'package:intl/intl.dart';

class Sprint {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  Sprint({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
  });

  // Calculate progress (0.0 to 1.0)
  double get progress {
    final totalDuration = endDate.difference(startDate).inSeconds;
    final elapsed = DateTime.now().difference(startDate).inSeconds;
    if (totalDuration <= 0) return 1.0;
    if (elapsed <= 0) return 0.0;
    if (elapsed >= totalDuration) return 1.0;
    return elapsed / totalDuration;
  }
  
  String get formattedRange {
    final start = DateFormat('MMM d').format(startDate);
    final end = DateFormat('MMM d').format(endDate);
    return '$start - $end';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Sprint.fromMap(Map<String, dynamic> map) {
    return Sprint(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      isActive: map['isActive'] == 1,
    );
  }
}
