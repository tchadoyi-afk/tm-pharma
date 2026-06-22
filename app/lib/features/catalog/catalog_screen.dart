import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';
import '../../core/sync/sync_service.dart';
import '../stock/stock_repository.dart';
import 'product_model.dart';
import 'products_repository.dart';

/// Catalogue & référentiel produits (Sprint 4).
/// Recherche instantanée (nom/DCI/code-barres) + ajout depuis le référentiel
/// DCI pré-chargé ou en saisie libre + association d'un code-barres au vol.
class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  // Tenant de démo (en réel : fourni par l'onboarding/auth).
  static const demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  final _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(syncServiceProvider).isReady;

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue produits')),
      floatingActionButton: PermissionGate(
        permission: Permissions.productCreate,
        child: FloatingActionButton(
          onPressed: () => _openAddProductSheet(context),
          child: const Icon(Icons.add),
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Rechercher (nom, DCI, code-barres)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<Product>>(
                    stream: ref
                        .read(productsRepositoryProvider)
                        .watchProducts(search: _search),
                    builder: (context, snap) {
                      final products = snap.data ?? const [];
                      if (products.isEmpty) {
                        return const Center(
                          child: Text('Aucun produit pour le moment.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, i) =>
                            _ProductTile(product: products[i]),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _openAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddProductSheet(
        tenantId: CatalogScreen.demoTenantId,
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.medication_outlined),
      title: Text(product.name),
      subtitle: Text([
        if (product.dciName != null && product.dciName != product.name)
          product.dciName!,
        product.barcode ?? 'sans code-barres',
        product.unit,
      ].join(' · ')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${product.sellingPrice.toStringAsFixed(0)} XOF'),
          PermissionGate(
            permission: Permissions.supplierManage,
            child: IconButton(
              icon: const Icon(Icons.local_shipping_outlined),
              tooltip: 'Fournisseur par défaut',
              onPressed: () => _pickDefaultSupplier(context, product),
            ),
          ),
          PermissionGate(
            permission: Permissions.priceEdit,
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _editPrice(context, product),
            ),
          ),
        ],
      ),
      onLongPress: () => _attachBarcode(context, product),
    );
  }

  Future<void> _pickDefaultSupplier(BuildContext context, Product product) async {
    final container = ProviderScope.containerOf(context);
    final suppliers = await container
        .read(stockRepositoryProvider)
        .watchSuppliers()
        .first;
    if (!context.mounted) return;
    final chosen = await showDialog<String?>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Fournisseur par défaut'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Aucun'),
          ),
          for (final s in suppliers)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, s.id),
              child: Text(s.name),
            ),
        ],
      ),
    );
    if (!context.mounted) return;
    await container
        .read(stockRepositoryProvider)
        .setDefaultSupplier(product.id, chosen);
  }

  Future<void> _editPrice(BuildContext context, Product product) async {
    final controller = TextEditingController(
      text: product.sellingPrice.toStringAsFixed(0),
    );
    final newPrice = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le prix'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'XOF'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (newPrice == null || !context.mounted) return;
    final repo = ProviderScope.containerOf(context).read(
      productsRepositoryProvider,
    );
    await repo.updatePrice(product.id, newPrice);
  }

  Future<void> _attachBarcode(BuildContext context, Product product) async {
    final controller = TextEditingController(text: product.barcode ?? '');
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Associer un code-barres'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Code-barres'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Associer'),
          ),
        ],
      ),
    );
    if (code == null || !context.mounted) return;
    final repo = ProviderScope.containerOf(context).read(
      productsRepositoryProvider,
    );
    await repo.attachBarcode(product.id, code);
  }
}

class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet({required this.tenantId});
  final String tenantId;

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _refSearchController = TextEditingController();
  final _nameController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _priceController = TextEditingController();
  List<ReferenceProduct> _refResults = const [];
  ReferenceProduct? _selectedRef;

  @override
  void dispose() {
    _refSearchController.dispose();
    _nameController.dispose();
    _barcodeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _searchReference(String term) async {
    final results = await ref
        .read(productsRepositoryProvider)
        .searchReferenceCatalog(term);
    setState(() => _refResults = results);
  }

  void _pickReference(ReferenceProduct r) {
    setState(() {
      _selectedRef = r;
      _nameController.text = r.dciName;
      _barcodeController.text = r.barcode ?? '';
      _refResults = const [];
      _refSearchController.text = r.dciName;
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final price = double.tryParse(_priceController.text) ?? 0;
    await ref
        .read(productsRepositoryProvider)
        .createProduct(
          tenantId: widget.tenantId,
          name: name,
          sellingPrice: price,
          barcode: _barcodeController.text,
          dciName: _selectedRef?.dciName,
          unit: _selectedRef?.unit ?? 'unité',
          category: _selectedRef?.category,
          referenceId: _selectedRef?.id,
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
              'Nouveau produit',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _refSearchController,
              decoration: const InputDecoration(
                labelText: 'Chercher dans le catalogue de référence (DCI)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _searchReference,
            ),
            for (final r in _refResults)
              ListTile(
                dense: true,
                title: Text(r.dciName),
                subtitle: Text(r.barcode ?? 'sans code'),
                onTap: () => _pickReference(r),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom du produit'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _barcodeController,
              decoration: const InputDecoration(labelText: 'Code-barres'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Prix de vente',
                suffixText: 'XOF',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
  }
}
