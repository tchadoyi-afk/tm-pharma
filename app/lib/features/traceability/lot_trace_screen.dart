import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../stock/stock_repository.dart';
import 'lot_trace_models.dart';

/// Fiche de traçabilité d'un lot : chronologie réception → ventes/sorties
/// (Sprint 11). Accès soumis à l'habilitation `trace.lot.view`.
class LotTraceScreen extends ConsumerWidget {
  const LotTraceScreen({
    super.key,
    required this.lotId,
    required this.lotLabel,
  });

  final String lotId;
  final String lotLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(stockRepositoryProvider);
    final s = Strings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(s.tracabilityTitle(lotLabel))),
      body: FutureBuilder<List<LotTraceEvent>>(
        future: Future.wait([
          repo.getLotMovements(lotId),
          repo.getLotSaleItems(lotId),
        ]).then(
          (results) => buildLotTraceTimeline(
            movements: results[0],
            saleItems: results[1],
          ),
        ),
        builder: (context, snap) {
          final events = snap.data ?? const [];
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (events.isEmpty) {
            return Center(child: Text(s.noMovementRecorded));
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, i) {
              final e = events[i];
              return ListTile(
                leading: Icon(
                  e.quantityDelta >= 0
                      ? Icons.add_circle_outline
                      : Icons.remove_circle_outline,
                  color: e.quantityDelta >= 0 ? Colors.green : Colors.red,
                ),
                title: Text(e.type),
                subtitle: e.detail == null ? null : Text(e.detail!),
                trailing: Text(
                  '${e.quantityDelta > 0 ? '+' : ''}${e.quantityDelta}  '
                  '${e.at.toIso8601String().substring(0, 16).replaceFirst('T', ' ')}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
