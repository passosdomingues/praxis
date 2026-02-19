import 'dart:convert';

class Event {
  final int? id;
  final String uuid;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final String author;

  Event({
    this.id,
    required this.uuid,
    required this.type,
    required this.payload,
    required this.timestamp,
    required this.author,
  });

  Map<String, dynamic> toMap() {
    return {
      'uuid': uuid,
      'type': type,
      'payload': jsonEncode(payload),
      'timestamp': timestamp.toIso8601String(),
      'author': author,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      uuid: map['uuid'],
      type: map['type'],
      payload: jsonDecode(map['payload']),
      timestamp: DateTime.parse(map['timestamp']),
      author: map['author'],
    );
  }
}
