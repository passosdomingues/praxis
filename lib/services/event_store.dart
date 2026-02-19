import 'dart:async';
import 'package:praxis/services/database_helper.dart';
import 'package:praxis/models/event.dart';

class EventStore {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final StreamController<Event> _eventStreamController = StreamController.broadcast();
  int _lastEventId = 0;
  Timer? _pollingTimer;

  Stream<Event> get eventStream => _eventStreamController.stream;

  void startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkForNewEvents();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> _checkForNewEvents() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id > ?',
      whereArgs: [_lastEventId],
      orderBy: 'id ASC',
    );

    for (var map in maps) {
      final event = Event.fromMap(map);
      _lastEventId = event.id!;
      // Only emit if not from self (Flutter) to avoid double processing if needed, 
      // but usually we want to process everything or handled via optimistic UI.
      // For now, emit everything.
      _eventStreamController.add(event);
    }
  }

  Future<void> appendEvent(Event event) async {
    final db = await _db.database;
    await db.insert('events', event.toMap());
    // We don't add to stream here immediately if we rely on polling, 
    // but for responsive UI we might want to.
    // Let's rely on polling for simplicity or manual optimistic update in Provider.
  }
  
  Future<List<Event>> getAllEvents() async {
    final db = await _db.database;
    final List<Map<String, dynamic>> maps = await db.query('events', orderBy: 'id ASC');
    return List.generate(maps.length, (i) => Event.fromMap(maps[i]));
  }
}
