import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';
import '../../core/sync/sync_service.dart';
import 'dashboard_kpis.dart';
import 'dashboard_repository.dart';

/// Tableau de bord à 3 niveaux (Sprint 11) :
/// - Direction (KPI financiers) sous `report.financial.view` ;
/// - Pharmacien responsable (stock/péremptions/traçabilité) sous `stock.view` ;
/// - Caissier (rappel des raccourcis caisse) sous `pos.sell`.
/// Chaque section ne s'affiche que si l'utilisateur a l'habilitation requise.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(syncServiceProvider).isReady;

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: !ready
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Base locale non initialisée sur cette plateforme.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : FutureBuilder<DashboardKpis>(
              future: ref.read(dashboardRepositoryProvider).getKpis(),
              builder: (context, snap) {
                final kpis = snap.data;
                if (kpis == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    PermissionGate(
                      permission: Permissions.reportFinancialView,
                      child: _Section(
                        title: 'Direction — KPI financiers',
                        cards: [
                          _Kpi('Ventes du jour', '${kpis.salesTodayCount}'),
                          _Kpi(
                            'CA du jour',
                            '${kpis.salesTodayTotal.toStringAsFixed(0)} XOF',
                          ),
                          _Kpi(
                            'Valeur du stock',
                            '${kpis.stockValue.toStringAsFixed(0)} XOF',
                          ),
                        ],
                      ),
                    ),
                    PermissionGate(
                      permission: Permissions.stockView,
                      child: _Section(
                        title: 'Pharmacien — stock & péremptions',
                        cards: [
                          _Kpi('Produits sous le seuil', '${kpis.lowStockCount}'),
                          _Kpi(
                            'Lots périment <30j',
                            '${kpis.expiringSoonCount}',
                          ),
                        ],
                      ),
                    ),
                    PermissionGate(
                      permission: Permissions.posSell,
                      child: const _Section(
                        title: 'Caissier',
                        cards: [],
                        trailingHint: 'Voir « Caisse » pour le détail de la session du jour.',
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _Kpi {
  const _Kpi(this.label, this.value);
  final String label;
  final String value;
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.cards,
    this.trailingHint,
  });

  final String title;
  final List<_Kpi> cards;
  final String? trailingHint;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty && trailingHint == null) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (cards.isNotEmpty)
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: cards
                    .map(
                      (k) => SizedBox(
                        width: 160,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              k.value,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            Text(
                              k.label,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            if (trailingHint != null) Text(trailingHint!),
          ],
        ),
      ),
    );
  }
}
