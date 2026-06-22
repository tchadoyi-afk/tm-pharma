import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';
import '../../core/rbac/rbac_providers.dart';
import '../../core/sync/sync_service.dart';
import '../stock/stock_models.dart';
import '../stock/stock_repository.dart';
import '../traceability/lot_trace_screen.dart';
import 'expiry_alerts.dart';

const _exitTypeLabels = {
  'DONATION': 'Don',
  'SUPPLIER_RETURN': 'Retour fournisseur',
  'TRANSFER': 'Transfert vers une autre pharmacie',
};

/// Cycle de vie & péremptions (Sprint 9) : alertes J-90/J-30/J-7 sur les
/// lots en stock, et sorties non-ventes (don, retour fournisseur, transfert).
class LifecycleScreen extends ConsumerWidget {
  const LifecycleScreen({super.key});

  static const demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(syncServiceProvider).isReady;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Péremptions & sorties')),
      floatingActionButton: PermissionGate(
        permission: Permissions.stockAdjust,
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.outbox_outlined),
          label: const Text('Sortie de stock'),
          onPressed: () => _openExitSheet(context),
        ),
      ),
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
          : StreamBuilder<List<({Lot lot, String productName})>>(
              stream: ref.read(stockRepositoryProvider).watchAllLots(),
              builder: (context, snap) {
                final rows = snap.data ?? const [];
                final alerts = rows
                    .where(
                      (r) =>
                          expiryAlertLevel(r.lot.expirationDate, today) !=
                          ExpiryAlertLevel.none,
                    )
                    .toList()
                  ..sort((a, b) {
                    final da = a.lot.expirationDate!;
                    final db = b.lot.expirationDate!;
                    return da.compareTo(db);
                  });
                if (alerts.isEmpty) {
                  return const Center(
                    child: Text('Aucun lot proche de la péremption.'),
                  );
                }
                return ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, i) {
                    final row = alerts[i];
                    final level = expiryAlertLevel(row.lot.expirationDate, today);
                    final canTrace = watchCan(ref, Permissions.traceLotView);
                    return ListTile(
                      leading: Icon(
                        Icons.event_busy_outlined,
                        color: _alertColor(context, level),
                      ),
                      title: Text(row.productName),
                      subtitle: Text(
                        'Lot ${row.lot.lotNumber ?? '—'} · '
                        'péremption ${row.lot.expirationDate!.toIso8601String().substring(0, 10)} '
                        '· qté ${row.lot.quantity}',
                      ),
                      trailing: Text(_alertLabel(level)),
                      onTap: !canTrace
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => LotTraceScreen(
                                  lotId: row.lot.id,
                                  lotLabel:
                                      '${row.productName} (lot ${row.lot.lotNumber ?? '—'})',
                                ),
                              ),
                            ),
                    );
                  },
                );
              },
            ),
    );
  }

  Color? _alertColor(BuildContext context, ExpiryAlertLevel level) {
    final scheme = Theme.of(context).colorScheme;
    switch (level) {
      case ExpiryAlertLevel.expired:
      case ExpiryAlertLevel.j7:
        return scheme.error;
      case ExpiryAlertLevel.j30:
        return Colors.orange;
      case ExpiryAlertLevel.j90:
        return Colors.amber;
      case ExpiryAlertLevel.none:
        return null;
    }
  }

  String _alertLabel(ExpiryAlertLevel level) {
    switch (level) {
      case ExpiryAlertLevel.expired:
        return 'Expiré';
      case ExpiryAlertLevel.j7:
        return 'J-7';
      case ExpiryAlertLevel.j30:
        return 'J-30';
      case ExpiryAlertLevel.j90:
        return 'J-90';
      case ExpiryAlertLevel.none:
        return '';
    }
  }

  void _openExitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _StockExitSheet(tenantId: demoTenantId),
    );
  }
}

class _StockExitSheet extends ConsumerStatefulWidget {
  const _StockExitSheet({required this.tenantId});
  final String tenantId;

  @override
  ConsumerState<_StockExitSheet> createState() => _StockExitSheetState();
}

class _StockExitSheetState extends ConsumerState<_StockExitSheet> {
  final _quantityController = TextEditingController(text: '1');
  final _reasonController = TextEditingController();
  String _type = 'DONATION';
  ({Lot lot, String productName})? _selectedLot;

  @override
  void dispose() {
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final lot = _selectedLot;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (lot == null || quantity <= 0) return;
    await ref
        .read(stockRepositoryProvider)
        .recordStockExit(
          tenantId: widget.tenantId,
          lotId: lot.lot.id,
          productId: lot.lot.productId,
          quantity: quantity,
          type: _type,
          reason: _reasonController.text.trim().isEmpty
              ? null
              : _reasonController.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Sortie de stock (hors vente)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Type de sortie'),
              items: _exitTypeLabels.entries
                  .map(
                    (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<({Lot lot, String productName})>>(
              stream: ref.read(stockRepositoryProvider).watchAllLots(),
              builder: (context, snap) {
                final lots = snap.data ?? const [];
                return DropdownButtonFormField<({Lot lot, String productName})>(
                  initialValue: _selectedLot,
                  decoration: const InputDecoration(labelText: 'Lot'),
                  items: lots
                      .map(
                        (r) => DropdownMenuItem(
                          value: r,
                          child: Text('${r.productName} (qté ${r.lot.quantity})'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedLot = v),
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantité'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Motif (optionnel)'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
  }
}
