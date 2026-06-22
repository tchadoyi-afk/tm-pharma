import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';
import '../../core/sync/sync_service.dart';
import '../stock/stock_models.dart';
import '../stock/stock_repository.dart';
import 'purchase_order_repository.dart';
import 'reorder_suggestion.dart';

/// Suggestions de réappro (Sprint 10) : produits sous le seuil bas, avec
/// quantité suggérée, et génération d'un bon de commande (DRAFT) à partir
/// des suggestions sélectionnées.
class ReorderScreen extends ConsumerStatefulWidget {
  const ReorderScreen({super.key});

  static const demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  ConsumerState<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends ConsumerState<ReorderScreen> {
  final Set<String> _selected = {};

  Future<void> _createOrder(List<ReorderSuggestion> suggestions) async {
    final chosen = suggestions
        .where((s) => _selected.contains(s.productId))
        .toList();
    if (chosen.isEmpty) return;
    await ref
        .read(purchaseOrderRepositoryProvider)
        .createFromSuggestions(
          tenantId: ReorderScreen.demoTenantId,
          suggestions: chosen,
        );
    setState(() => _selected.clear());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bon de commande créé.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(syncServiceProvider).isReady;

    return Scaffold(
      appBar: AppBar(title: const Text('Suggestions de réappro')),
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
          : StreamBuilder<List<StockLine>>(
              stream: ref.read(stockRepositoryProvider).watchStockLines(),
              builder: (context, snap) {
                final lines = snap.data ?? const [];
                final suggestions = computeReorderSuggestions(
                  lines
                      .map(
                        (l) => ReorderStockLine(
                          productId: l.productId,
                          productName: l.productName,
                          quantity: l.quantity,
                          lowStockThreshold: l.lowStockThreshold,
                        ),
                      )
                      .toList(),
                );
                if (suggestions.isEmpty) {
                  return const Center(
                    child: Text('Aucune suggestion : stocks au-dessus du seuil.'),
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
                              'Stock actuel : ${s.currentQuantity} · '
                              'Suggéré : ${s.suggestedQuantity}',
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
                            label: const Text('Créer le bon de commande'),
                            onPressed: _selected.isEmpty
                                ? null
                                : () => _createOrder(suggestions),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
