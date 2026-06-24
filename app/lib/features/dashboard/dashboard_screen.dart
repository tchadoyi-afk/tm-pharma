import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
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
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.dashboardTitle)),
      body: !ready
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  s.localDbNotInitialized,
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
                        title: s.sectionDirectionFinancialKpis,
                        cards: [
                          _Kpi(s.kpiSalesToday, '${kpis.salesTodayCount}'),
                          _Kpi(
                            s.kpiRevenueToday,
                            '${kpis.salesTodayTotal.toStringAsFixed(0)} XOF',
                          ),
                          _Kpi(
                            s.kpiStockValue,
                            '${kpis.stockValue.toStringAsFixed(0)} XOF',
                          ),
                        ],
                      ),
                    ),
                    PermissionGate(
                      permission: Permissions.stockView,
                      child: _Section(
                        title: s.sectionPharmacistStock,
                        cards: [
                          _Kpi(s.kpiLowStockCount, '${kpis.lowStockCount}'),
                          _Kpi(
                            s.kpiExpiringSoon,
                            '${kpis.expiringSoonCount}',
                          ),
                        ],
                      ),
                    ),
                    PermissionGate(
                      permission: Permissions.posSell,
                      child: _Section(
                        title: s.sectionCashier,
                        cards: const [],
                        trailingHint: s.seeCashierForDetail,
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
