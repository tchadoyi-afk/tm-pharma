import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';
import '../../core/sync/sync_service.dart';
import '../stock/stock_models.dart';
import '../stock/stock_repository.dart';
import 'purchase_order_model.dart';
import 'purchase_order_repository.dart';
import 'purchase_order_status.dart';

const _statusLabels = {
  'DRAFT': 'Brouillon',
  'SENT': 'Envoyée',
  'CONFIRMED': 'Confirmée par le fournisseur',
  'PARTIALLY_RECEIVED': 'Reçue partiellement',
  'RECEIVED': 'Reçue',
  'CANCELLED': 'Annulée',
};

/// Suivi des bons de commande (portail fournisseurs, MVP) : liste des
/// commandes avec leur statut, et actions de transition. La validation
/// manuelle avant envoi au fournisseur est une étape humaine explicite
/// (bouton « Valider et envoyer ») — aucune transition n'est automatique,
/// règle invariante posée pour tous les paliers (MVP/V2/V3).
class PurchaseOrdersScreen extends ConsumerWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(syncServiceProvider).isReady;

    return Scaffold(
      appBar: AppBar(title: const Text('Bons de commande')),
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
          : StreamBuilder<List<PurchaseOrder>>(
              stream: ref.read(purchaseOrderRepositoryProvider).watchPurchaseOrders(),
              builder: (context, snap) {
                final orders = snap.data ?? const [];
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('Aucun bon de commande pour le moment.'),
                  );
                }
                return StreamBuilder<List<Supplier>>(
                  stream: ref.read(stockRepositoryProvider).watchSuppliers(),
                  builder: (context, supplierSnap) {
                    final supplierNames = {
                      for (final s in supplierSnap.data ?? const [])
                        s.id: s.name,
                    };
                    return StreamBuilder<List<StockLine>>(
                      stream: ref.read(stockRepositoryProvider).watchStockLines(),
                      builder: (context, stockSnap) {
                        final productNames = <String, String>{
                          for (final l in stockSnap.data ?? const [])
                            l.productId: l.productName,
                        };
                        return ListView.builder(
                          itemCount: orders.length,
                          itemBuilder: (context, i) {
                            final order = orders[i];
                            return _PurchaseOrderTile(
                              order: order,
                              supplierName: order.supplierId == null
                                  ? null
                                  : supplierNames[order.supplierId],
                              productNames: productNames,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}

class _PurchaseOrderTile extends ConsumerWidget {
  const _PurchaseOrderTile({
    required this.order,
    required this.supplierName,
    required this.productNames,
  });

  final PurchaseOrder order;
  final String? supplierName;
  final Map<String, String> productNames;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(purchaseOrderRepositoryProvider);
    return ExpansionTile(
      leading: const Icon(Icons.receipt_long_outlined),
      title: Text(supplierName ?? 'Fournisseur non renseigné'),
      subtitle: Text(
        '${_statusLabels[order.status] ?? order.status} · '
        '${order.createdAt.toIso8601String().substring(0, 10)}',
      ),
      children: [
        StreamBuilder<List<PurchaseOrderItem>>(
          stream: repo.watchItems(order.id),
          builder: (context, snap) {
            final items = snap.data ?? const [];
            return Column(
              children: [
                for (final item in items)
                  ListTile(
                    dense: true,
                    title: Text(
                      productNames[item.productId] ??
                          'Produit ${item.productId.substring(0, 8)}',
                    ),
                    trailing: Text('qté ${item.quantity}'),
                  ),
              ],
            );
          },
        ),
        PermissionGate(
          permission: Permissions.purchaseOrder,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _actionsFor(order.status, repo, order.id),
            ),
          ),
        ),
      ],
    );
  }

  static const _actionLabels = {
    'SENT': ('Valider et envoyer', Icons.send_outlined),
    'CONFIRMED': ('Confirmée par le fournisseur', Icons.check_circle_outline),
    'PARTIALLY_RECEIVED': ('Reçue partiellement', Icons.inventory_outlined),
    'RECEIVED': ('Reçue intégralement', Icons.check),
    'CANCELLED': ('Annuler', Icons.close),
  };

  static final Map<String, Future<void> Function(PurchaseOrderRepository, String)>
  _actionCallbacks = {
    'SENT': (repo, id) => repo.markSent(id),
    'CONFIRMED': (repo, id) => repo.markConfirmed(id),
    'PARTIALLY_RECEIVED': (repo, id) => repo.markPartiallyReceived(id),
    'RECEIVED': (repo, id) => repo.markReceived(id),
    'CANCELLED': (repo, id) => repo.cancel(id),
  };

  /// Les boutons proposés découlent des transitions valides depuis [status]
  /// ([allowedNextStatuses]) — un seul point de vérité partagé avec le
  /// dépôt, qui applique le même garde-fou côté données.
  List<Widget> _actionsFor(
    String status,
    PurchaseOrderRepository repo,
    String orderId,
  ) {
    return [
      for (final next in allowedNextStatuses(status))
        if (_actionLabels[next] case (final label, final icon))
          next == 'RECEIVED' || next == 'SENT'
              ? FilledButton.icon(
                  icon: Icon(icon),
                  label: Text(label),
                  onPressed: () => _actionCallbacks[next]!(repo, orderId),
                )
              : next == 'CANCELLED'
              ? OutlinedButton.icon(
                  icon: Icon(icon),
                  label: Text(label),
                  onPressed: () => _actionCallbacks[next]!(repo, orderId),
                )
              : FilledButton.tonalIcon(
                  icon: Icon(icon),
                  label: Text(label),
                  onPressed: () => _actionCallbacks[next]!(repo, orderId),
                ),
    ];
  }
}
