import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:praxis/services/database_helper.dart';
import 'package:praxis/models/task_card.dart';

class ExportImportService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // =====================================================
  // EXPORT DATA
  // =====================================================
  Future<File> exportData() async {
    final sprints = await _dbHelper.getAllSprints();
    final allCards = <TaskCard>[];

    for (final sprint in sprints) {
      if (sprint.id != null) {
        final cards = await _dbHelper.getCardsBySprint(sprint.id!);
        allCards.addAll(cards);
      }
    }

    final data = {
      "version": 1,
      "timestamp": DateTime.now().toIso8601String(),
      "sprints": sprints.map((s) => s.toMap()).toList(),
      "cards": allCards.map((c) => c.toMap()).toList(),
    };

    final jsonString = jsonEncode(data);

    final archive = Archive();
    archive.addFile(
      ArchiveFile(
        "scrum_data.json",
        utf8.encode(jsonString).length,
        utf8.encode(jsonString),
      ),
    );

    final zipBytes = ZipEncoder().encode(archive);

    final tempDir = await getTemporaryDirectory();
    final file = File(
      p.join(
        tempDir.path,
        "scrum_backup_${DateTime.now().millisecondsSinceEpoch}.zip",
      ),
    );

    await file.writeAsBytes(zipBytes!);

    print("Backup created at ${file.path}");
    return file;
  }

  // =====================================================
  // IMPORT DATA
  // =====================================================
  Future<void> importData(File zipFile) async {
    final bytes = await zipFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    ArchiveFile? jsonFile;

    for (final file in archive.files) {
      if (file.name.endsWith("scrum_data.json")) {
        jsonFile = file;
        break;
      }
    }

    if (jsonFile == null) {
      throw Exception("scrum_data.json not found inside zip");
    }

    final jsonString = utf8.decode(jsonFile.content as List<int>);
    final data = jsonDecode(jsonString);

    if (data["sprints"] == null || data["cards"] == null) {
      throw Exception("Invalid backup structure");
    }

    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      try {
        await txn.delete("cards");
        await txn.delete("sprints");

        final sprintIdMap = <int, int>{};

        // Reinsert sprints without old IDs
        for (final s in data["sprints"]) {
          final map = Map<String, dynamic>.from(s);
          final oldId = map["id"];
          map.remove("id");

          final newId = await txn.insert("sprints", map);
          sprintIdMap[oldId] = newId;
        }

        // Reinsert cards with updated sprint_id
        for (final c in data["cards"]) {
          final map = Map<String, dynamic>.from(c);
          map.remove("id");

          final oldSprint = map["sprint_id"];
          map["sprint_id"] = sprintIdMap[oldSprint];

          await txn.insert("cards", map);
        }

        print("Import completed successfully");
      } catch (e) {
        print("Import failed: $e");
        rethrow;
      }
    });
  }
}
