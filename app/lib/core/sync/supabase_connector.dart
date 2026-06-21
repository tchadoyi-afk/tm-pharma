import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env.dart';

/// Connecteur PowerSync ⇄ Supabase.
///
/// - `fetchCredentials` : fournit le JWT Supabase de l'utilisateur connecté à
///   l'instance PowerSync (qui valide aussi la portée multi-tenant).
/// - `uploadData` : rejoue la file d'écritures locales (CRUD) vers Postgres.
///   Stratégie de conflit : **Last-Write-Wins** (upsert côté serveur) ; les
///   erreurs « fatales » (contrainte, RLS) sont écartées pour ne pas bloquer la
///   file — l'état serveur fait alors foi.
class SupabaseConnector extends PowerSyncBackendConnector {
  SupabaseConnector();

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;
    return PowerSyncCredentials(
      endpoint: Env.powerSyncUrl,
      token: session.accessToken,
    );
  }

  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    final client = Supabase.instance.client;
    try {
      for (final op in transaction.crud) {
        final table = client.from(op.table);
        switch (op.op) {
          case UpdateType.put:
            final data = Map<String, dynamic>.of(op.opData ?? {});
            data['id'] = op.id;
            await table.upsert(data); // LWW : la dernière écriture l'emporte
            break;
          case UpdateType.patch:
            await table.update(op.opData ?? {}).eq('id', op.id);
            break;
          case UpdateType.delete:
            await table.delete().eq('id', op.id);
            break;
        }
      }
      await transaction.complete();
    } on PostgrestException catch (e) {
      final code = e.code ?? '';
      final isFatal =
          code.startsWith('22') || // type de données
          code.startsWith('23') || // contrainte d'intégrité
          code == '42501'; // violation RLS / droits
      if (isFatal) {
        // On écarte l'opération invalide : la file ne doit jamais se bloquer.
        await transaction.complete();
      } else {
        // Erreur transitoire (réseau, etc.) → on réessaiera plus tard.
        rethrow;
      }
    }
  }
}
