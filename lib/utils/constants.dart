import 'dart:ui';

class AppConstants {
  static const List<String> columns = [
    'Backlog',
    'To Do',
    'In Progress',
    'Done',
  ];

  static const List<Color> labelColors = [
    Color(0xFFEF5350), // Red
    Color(0xFFEC407A), // Pink
    Color(0xFFAB47BC), // Purple
    Color(0xFF7E57C2), // Deep Purple
    Color(0xFF42A5F5), // Blue
    Color(0xFF26C6DA), // Cyan
    Color(0xFF66BB6A), // Green
    Color(0xFFFFCA28), // Amber
  ];

  static const String dbName = 'praxis_events.db';
  static const int dbVersion = 3;
}
