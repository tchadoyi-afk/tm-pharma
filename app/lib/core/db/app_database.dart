import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
// On masque Table/Column de PowerSync : ici c'est la DSL Drift qui prime.
import 'package:powersync/powersync.dart' show PowerSyncDatabase;

part 'app_database.g.dart';

/// Table Drift (typée) projetée sur la table `sales` gérée par PowerSync.
/// Les tables existent déjà côté SQLite (créées par PowerSync) : Drift ne fait
/// que les requêter de façon typée — il ne doit PAS les (re)créer.
class Sales extends Table {
  @override
  String get tableName => 'sales';

  TextColumn get id => text()();
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get userId => text().named('user_id').nullable()();
  RealColumn get totalAmount => real().named('total_amount')();
  TextColumn get status => text()();
  TextColumn get paymentMethod => text().named('payment_method')();
  TextColumn get soldAt => text().named('sold_at').nullable()();
  TextColumn get createdAt => text().named('created_at').nullable()();
  TextColumn get deletedAt => text().named('deleted_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Base Drift branchée sur la connexion SQLite de PowerSync.
/// Couche de requêtes typées ; la synchro reste pilotée par PowerSync.
@DriftDatabase(tables: [Sales])
class AppDatabase extends _$AppDatabase {
  AppDatabase(PowerSyncDatabase powerSync)
    : super(SqliteAsyncDriftConnection(powerSync));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // Tables gérées par PowerSync : ne rien créer/migrer côté Drift.
    onCreate: (m) async {},
    beforeOpen: (details) async {},
  );

  /// Exemple de requête typée : ventes non supprimées, plus récentes d'abord.
  Future<List<Sale>> recentSales({int limit = 50}) {
    return (select(sales)
          ..where((s) => s.deletedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
          ..limit(limit))
        .get();
  }
}
