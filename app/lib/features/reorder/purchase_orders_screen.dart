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
                    trailing: Text(
                      item.receivedQuantity == 0
                          ? 'qté ${item.quantity}'
                          : 'qté ${item.quantity} (reçu ${item.receivedQuantity})',
                    ),
                  ),
                PermissionGate(
                  permission: Permissions.purchaseOrder,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _actionsFor(context, order, repo, items, productNames),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  static const _actionLabels = {
    'SENT': ('Valider et envoyer', Icons.send_outlined),
    'CANCELLED': ('Annuler', Icons.close),
  };

  static final Map<String, Future<void> Function(PurchaseOrderRepository, String)>
  _actionCallbacks = {
    'SENT': (repo, id) => repo.markSent(id),
    'CANCELLED': (repo, id) => repo.cancel(id),
  };

  /// Les boutons proposés découlent des transitions valides depuis le
  /// statut courant ([allowedNextStatuses]) — un seul point de vérité
  /// partagé avec le dépôt, qui applique le même garde-fou côté données.
  /// CONFIRMED et PARTIALLY_RECEIVED se résolvent en un seul bouton
  /// « Réceptionner » : c'est [PurchaseOrderRepository.receiveItems] qui
  /// décide ensuite, ligne par ligne, si la commande devient RECEIVED ou
  /// reste PARTIALLY_RECEIVED.
  List<Widget> _actionsFor(
    BuildContext context,
    PurchaseOrder order,
    PurchaseOrderRepository repo,
    List<PurchaseOrderItem> items,
    Map<String, String> productNames,
  ) {
    final next = allowedNextStatuses(order.status);
    return [
      if (next.contains('RECEIVED') || next.contains('PARTIALLY_RECEIVED'))
        FilledButton.icon(
          icon: const Icon(Icons.inventory_outlined),
          label: const Text('Réceptionner'),
          onPressed: () => _openReceiveDialog(context, repo, order.id, items, productNames),
        ),
      for (final status in next)
        if (_actionLabels[status] case (final label, final icon))
          status == 'SENT'
              ? FilledButton.icon(
                  icon: Icon(icon),
                  label: Text(label),
                  onPressed: () => _actionCallbacks[status]!(repo, order.id),
                )
              : OutlinedButton.icon(
                  icon: Icon(icon),
                  label: Text(label),
                  onPressed: () => _actionCallbacks[status]!(repo, order.id),
                ),
    ];
  }

  void _openReceiveDialog(
    BuildContext context,
    PurchaseOrderRepository repo,
    String orderId,
    List<PurchaseOrderItem> items,
    Map<String, String> productNames,
  ) {
    final pending = items.where((i) => i.remainingQuantity > 0).toList();
    showDialog<void>(
      context: context,
      builder: (context) => _ReceiveDialog(
        repo: repo,
        orderId: orderId,
        items: pending,
        productNames: productNames,
      ),
    );
  }
}

/// Saisie des quantités effectivement reçues pour chaque ligne en attente,
/// par défaut le reliquat (réception intégrale en un clic), modifiable pour
/// une réception partielle.
class _ReceiveDialog extends StatefulWidget {
  const _ReceiveDialog({
    required this.repo,
    required this.orderId,
    required this.items,
    required this.productNames,
  });

  final PurchaseOrderRepository repo;
  final String orderId;
  final List<PurchaseOrderItem> items;
  final Map<String, String> productNames;

  @override
  State<_ReceiveDialog> createState() => _ReceiveDialogState();
}

class _ReceiveDialogState extends State<_ReceiveDialog> {
  late final Map<String, TextEditingController> _controllers = {
    for (final item in widget.items)
      item.id: TextEditingController(text: '${item.remainingQuantity}'),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _confirm() async {
    final quantities = {
      for (final item in widget.items)
        item.id: int.tryParse(_controllers[item.id]!.text) ?? 0,
    };
    await widget.repo.receiveItems(widget.orderId, quantities);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Réceptionner la commande'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in widget.items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: TextField(
                  controller: _controllers[item.id],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: widget.productNames[item.productId] ??
                        'Produit ${item.productId.substring(0, 8)}',
                    helperText: 'Reliquat attendu : ${item.remainingQuantity}',
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _confirm, child: const Text('Valider')),
      ],
    );
  }
}
