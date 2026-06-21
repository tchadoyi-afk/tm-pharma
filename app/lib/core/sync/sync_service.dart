import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';
import 'schema.dart';
import 'supabase_connector.dart';

/// Service de synchronisation offline-first.
///
/// Cycle de vie :
///   1. `initialize()` — ouvre la base SQLite locale (toujours, même hors-ligne).
///   2. initialise Supabase si configuré.
///   3. `connect()` — branche PowerSync quand un utilisateur est authentifié.
///
/// La base locale est utilisable immédiatement ; la synchro réseau est un
/// bonus qui s'active dès que possible.
class SyncService {
  PowerSyncDatabase? _db;

  PowerSyncDatabase get db {
    final db = _db;
    if (db == null) {
      throw StateError('SyncService.initialize() doit être appelé d\'abord');
    }
    return db;
  }

  bool get isReady => _db != null;

  Future<void> initialize() async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = p.join(dir.path, 'tm_pharma.db');

    _db = PowerSyncDatabase(schema: powerSyncSchema, path: dbPath);
    await _db!.initialize();

    if (Env.isConfigured) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseKey,
      );
    }
  }

  /// Branche la synchro réseau (à appeler après authentification).
  Future<void> connect() async {
    if (!Env.isConfigured) return; // mode local pur
    await db.connect(connector: SupabaseConnector());
  }

  Future<void> disconnect() async {
    if (_db != null) await _db!.disconnect();
  }

  /// État de synchro observable (connecté, en cours d'upload/download…).
  Stream<SyncStatus> get statusStream => db.statusStream;
}

/// Provider du service (le cycle de vie est piloté au démarrage de l'app).
final syncServiceProvider = Provider<SyncService>((ref) => SyncService());
