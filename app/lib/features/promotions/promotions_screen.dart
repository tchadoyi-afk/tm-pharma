import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/sync/sync_service.dart';
import '../catalog/product_model.dart';
import '../catalog/products_repository.dart';
import 'promotion_model.dart';
import 'promotions_repository.dart';

/// Gestion des promotions (Sprint 9) : remise (%) temporaire sur un produit,
/// appliquée automatiquement au panier de la caisse pendant sa validité.
class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  static const demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(syncServiceProvider).isReady;

    return Scaffold(
      appBar: AppBar(title: const Text('Promotions')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.local_offer_outlined),
        label: const Text('Nouvelle promotion'),
        onPressed: () => _openCreateSheet(context),
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
          : StreamBuilder<List<Promotion>>(
              stream: ref.read(promotionsRepositoryProvider).watchPromotions(),
              builder: (context, snap) {
                final promos = snap.data ?? const [];
                if (promos.isEmpty) {
                  return const Center(child: Text('Aucune promotion.'));
                }
                final now = DateTime.now();
                return ListView.builder(
                  itemCount: promos.length,
                  itemBuilder: (context, i) {
                    final p = promos[i];
                    return ListTile(
                      leading: Icon(
                        Icons.local_offer_outlined,
                        color: p.isActiveAt(now)
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text('-${p.discountPercent.toStringAsFixed(0)} %'),
                      subtitle: Text(
                        'Du ${p.startsAt.toIso8601String().substring(0, 10)} '
                        'au ${p.endsAt.toIso8601String().substring(0, 10)}',
                      ),
                      trailing: p.isActiveAt(now) ? const Text('Active') : null,
                    );
                  },
                );
              },
            ),
    );
  }

  void _openCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _CreatePromotionSheet(tenantId: demoTenantId),
    );
  }
}

class _CreatePromotionSheet extends ConsumerStatefulWidget {
  const _CreatePromotionSheet({required this.tenantId});
  final String tenantId;

  @override
  ConsumerState<_CreatePromotionSheet> createState() =>
      _CreatePromotionSheetState();
}

class _CreatePromotionSheetState extends ConsumerState<_CreatePromotionSheet> {
  final _searchController = TextEditingController();
  final _discountController = TextEditingController(text: '10');
  List<Product> _productResults = const [];
  Product? _selectedProduct;
  final DateTime _startsAt = DateTime.now();
  final DateTime _endsAt = DateTime.now().add(const Duration(days: 7));

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _searchProducts(String term) async {
    final results = await ref
        .read(productsRepositoryProvider)
        .watchProducts(search: term)
        .first;
    setState(() => _productResults = results);
  }

  Future<void> _save() async {
    final product = _selectedProduct;
    final discount = double.tryParse(_discountController.text) ?? 0;
    if (product == null || discount <= 0) return;
    await ref
        .read(promotionsRepositoryProvider)
        .createPromotion(
          tenantId: widget.tenantId,
          productId: product.id,
          discountPercent: discount,
          startsAt: _startsAt,
          endsAt: _endsAt,
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
              'Nouvelle promotion',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Produit (nom, DCI, code-barres)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchProducts,
            ),
            for (final p in _productResults)
              ListTile(
                dense: true,
                selected: p.id == _selectedProduct?.id,
                title: Text(p.name),
                onTap: () => setState(() => _selectedProduct = p),
              ),
            if (_selectedProduct != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('Sélectionné : ${_selectedProduct!.name}'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Remise (%)'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Créer')),
          ],
        ),
      ),
    );
  }
}
