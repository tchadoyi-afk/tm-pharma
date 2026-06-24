import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';
import '../../core/sync/sync_service.dart';
import '../stock/stock_models.dart';
import '../stock/stock_repository.dart';
import 'purchase_order_repository.dart';
import 'reorder_suggestion.dart';

/// Suggestions de réappro (Sprint 10, affiné) : produits sous le point de
/// commande (seuil bas, ou vélocité de vente × délai fournisseur si connus),
/// avec quantité suggérée couvrant le délai + marge de sécurité. Génère un
/// bon de commande (DRAFT) par fournisseur à partir des suggestions
/// sélectionnées.
class ReorderScreen extends ConsumerStatefulWidget {
  const ReorderScreen({super.key});

  static const demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  ConsumerState<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends ConsumerState<ReorderScreen> {
  final Set<String> _selected = {};

  Future<void> _createOrders(List<ReorderSuggestion> suggestions) async {
    final chosen = suggestions
        .where((s) => _selected.contains(s.productId))
        .toList();
    if (chosen.isEmpty) return;
    final bySupplier = <String?, List<ReorderSuggestion>>{};
    for (final s in chosen) {
      bySupplier.putIfAbsent(s.supplierId, () => []).add(s);
    }
    final repo = ref.read(purchaseOrderRepositoryProvider);
    for (final entry in bySupplier.entries) {
      await repo.createFromSuggestions(
        tenantId: ReorderScreen.demoTenantId,
        suggestions: entry.value,
        supplierId: entry.key,
      );
    }
    setState(() => _selected.clear());
    if (mounted) {
      final s = Strings.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bySupplier.length > 1
                ? s.purchaseOrdersCreatedSummary(bySupplier.length)
                : s.purchaseOrderCreated,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(syncServiceProvider).isReady;
    final strings = Strings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.reorderTitle)),
      body: !ready
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  strings.localDbNotInitialized,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : StreamBuilder<List<StockLine>>(
              stream: ref.read(stockRepositoryProvider).watchStockLines(),
              builder: (context, snap) {
                final lines = snap.data ?? const [];
                return FutureBuilder<Map<String, double>>(
                  future: ref.read(stockRepositoryProvider).getDailySalesVelocity(),
                  builder: (context, velocitySnap) {
                    final velocity = velocitySnap.data ?? const {};
                    final suggestions = computeReorderSuggestions(
                      lines
                          .map(
                            (l) => ReorderStockLine(
                              productId: l.productId,
                              productName: l.productName,
                              quantity: l.quantity,
                              lowStockThreshold: l.lowStockThreshold,
                              dailyVelocity: velocity[l.productId] ?? 0,
                              leadTimeDays: l.supplierLeadTimeDays,
                              supplierId: l.defaultSupplierId,
                              supplierName: l.defaultSupplierName,
                            ),
                          )
                          .toList(),
                    );
                    if (suggestions.isEmpty) {
                      return Center(
                        child: Text(strings.noSuggestion),
                      );
                    }
                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: suggestions.length,
                            itemBuilder: (context, i) {
                              final s = suggestions[i];
                              return CheckboxListTile(
                                value: _selected.contains(s.productId),
                                onChanged: (v) => setState(() {
                                  if (v ?? false) {
                                    _selected.add(s.productId);
                                  } else {
                                    _selected.remove(s.productId);
                                  }
                                }),
                                title: Text(s.productName),
                                subtitle: Text(
                                  strings.reorderSubtitle(
                                    s.currentQuantity,
                                    s.suggestedQuantity,
                                    s.supplierName,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SafeArea(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: PermissionGate(
                              permission: Permissions.purchaseOrder,
                              child: FilledButton.icon(
                                icon: const Icon(Icons.shopping_cart_checkout),
                                label: Text(strings.createPurchaseOrders),
                                onPressed: _selected.isEmpty
                                    ? null
                                    : () => _createOrders(suggestions),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}
