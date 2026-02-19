import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:praxis/utils/constants.dart';
import 'package:praxis/models/sprint.dart';
import 'package:praxis/models/task_card.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.dbName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    
    final dbPath = (await getApplicationSupportDirectory()).path;
    // For development, we might want to check for a local file first
    final path = join(dbPath, filePath);

    return await openDatabase(
      path, 
      version: AppConstants.dbVersion, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  uuid TEXT NOT NULL,
  type TEXT NOT NULL,
  payload TEXT NOT NULL,
  timestamp TEXT NOT NULL,
  author TEXT NOT NULL
)
''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE cards ADD COLUMN isAi INTEGER DEFAULT 0');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const boolType = 'INTEGER NOT NULL';
    const nullableTextType = 'TEXT';

    await db.execute('''
CREATE TABLE sprints ( 
  id $idType, 
  name $textType,
  startDate $textType,
  endDate $textType,
  isActive $boolType
  )
''');

    await db.execute('''
CREATE TABLE cards ( 
  id $idType, 
  sprintId $intType,
  columnId $intType,
  title $textType,
  description $textType,
  labelColorIndex $intType,
  points $intType,
  dueDate $nullableTextType,
  isAi $boolType DEFAULT 0,
  FOREIGN KEY (sprintId) REFERENCES sprints (id) ON DELETE CASCADE
  )
''');

    await db.execute('''
CREATE TABLE events (
  id $idType,
  uuid $textType,
  type $textType,
  payload $textType,
  timestamp $textType,
  author $textType
)
''');
  }

  Future<Sprint> createSprint(Sprint sprint) async {
    final db = await instance.database;
    final id = await db.insert('sprints', sprint.toMap());
    return Sprint(
        id: id,
        name: sprint.name,
        startDate: sprint.startDate,
        endDate: sprint.endDate,
        isActive: sprint.isActive);
  }
  
  Future<Sprint?> getActiveSprint() async {
    final db = await instance.database;
    final result = await db.query('sprints', where: 'isActive = ?', whereArgs: [1], limit: 1);
    if (result.isNotEmpty) {
      return Sprint.fromMap(result.first);
    }
    return null;
  }

  Future<List<Sprint>> getAllSprints() async {
    final db = await instance.database;
    final result = await db.query('sprints', orderBy: 'startDate DESC');
    return result.map((json) => Sprint.fromMap(json)).toList();
  }

  Future<TaskCard> createCard(TaskCard card) async {
    final db = await instance.database;
    final id = await db.insert('cards', card.toMap());
    return card.copyWith(id: id);
  }

  Future<List<TaskCard>> getCardsBySprint(int sprintId) async {
    final db = await instance.database;
    final result = await db.query('cards', where: 'sprintId = ?', whereArgs: [sprintId]);
    return result.map((json) => TaskCard.fromMap(json)).toList();
  }

  Future<int> updateCard(TaskCard card) async {
    final db = await instance.database;
    return db.update(
      'cards',
      card.toMap(),
      where: 'id = ?',
      whereArgs: [card.id],
    );
  }

  Future<int> deleteCard(int id) async {
    final db = await instance.database;
    return await db.delete(
      'cards',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<int> deleteSprint(int id) async {
    final db = await instance.database;
    return await db.delete('sprints', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> closeDatabase() async {
    final db = await instance.database;
    db.close();
  }
}
