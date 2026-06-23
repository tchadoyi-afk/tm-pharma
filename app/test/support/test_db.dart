import 'dart:io';

import 'package:powersync/powersync.dart';
import 'package:tm_pharma/core/sync/schema.dart';

/// Base PowerSync de test : un fichier temporaire par test (l'extension
/// PowerSync exige des connexions partageant un fichier réel — un
/// `:memory:` par connexion ne fonctionne pas avec le pool de workers).
class TestDb {
  TestDb._(this.db, this._dir);

  final PowerSyncDatabase db;
  final Directory _dir;

  static Future<TestDb> open() async {
    final dir = Directory.systemTemp.createTempSync('tm_pharma_test_db');
    final db = PowerSyncDatabase(
      schema: powerSyncSchema,
      path: '${dir.path}/test.db',
    );
    await db.initialize();
    return TestDb._(db, dir);
  }

  Future<void> dispose() async {
    await db.close();
    _dir.deleteSync(recursive: true);
  }
}
