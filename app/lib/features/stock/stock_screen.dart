import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/i18n/strings.dart';
import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';
import '../../core/scanning/barcode_scanner_sheet.dart';
import '../../core/sync/sync_service.dart';
import '../catalog/product_model.dart';
import '../catalog/products_repository.dart';
import 'gs1_parser.dart';
import 'stock_models.dart';
import 'stock_repository.dart';

/// Stocks & lots + scan GS1 (Sprint 5).
/// Vue d'ensemble du stock par produit (ruptures signalées) + réception
/// de commande (saisie GS1 brute ou champs manuels lot/péremption).
class StockScreen extends ConsumerWidget {
  const StockScreen({super.key});

  static const demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ready = ref.watch(syncServiceProvider).isReady;
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.stockTitle)),
      floatingActionButton: PermissionGate(
        permission: Permissions.stockReceive,
        child: FloatingActionButton.extended(
          icon: const Icon(Icons.move_to_inbox_outlined),
          label: Text(s.receiveStock),
          onPressed: () => _openReceiveSheet(context),
        ),
      ),
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
          : StreamBuilder<List<StockLine>>(
              stream: ref.read(stockRepositoryProvider).watchStockLines(),
              builder: (context, snap) {
                final lines = snap.data ?? const [];
                if (lines.isEmpty) {
                  return Center(child: Text(s.noProductInStock));
                }
                return ListView.builder(
                  itemCount: lines.length,
                  itemBuilder: (context, i) => _StockTile(line: lines[i]),
                );
              },
            ),
    );
  }

  void _openReceiveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _ReceiveStockSheet(tenantId: demoTenantId),
    );
  }
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.line});
  final StockLine line;

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return ListTile(
      leading: Icon(
        line.isLow ? Icons.warning_amber_outlined : Icons.inventory_2_outlined,
        color: line.isLow ? Theme.of(context).colorScheme.error : null,
      ),
      title: Text(line.productName),
      subtitle: line.isLow
          ? Text(s.alertThreshold(line.lowStockThreshold))
          : null,
      trailing: Text(
        '${line.quantity}',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: line.isLow ? Theme.of(context).colorScheme.error : null,
        ),
      ),
    );
  }
}

class _ReceiveStockSheet extends ConsumerStatefulWidget {
  const _ReceiveStockSheet({required this.tenantId});
  final String tenantId;

  @override
  ConsumerState<_ReceiveStockSheet> createState() =>
      _ReceiveStockSheetState();
}

class _ReceiveStockSheetState extends ConsumerState<_ReceiveStockSheet> {
  final _gs1Controller = TextEditingController();
  final _searchController = TextEditingController();
  final _lotController = TextEditingController();
  final _expirationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  List<Product> _productResults = const [];
  Product? _selectedProduct;

  @override
  void dispose() {
    _gs1Controller.dispose();
    _searchController.dispose();
    _lotController.dispose();
    _expirationController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  /// Décode la chaîne GS1 scannée et pré-remplit lot/péremption ; le
  /// produit doit ensuite être retrouvé via son GTIN (code-barres).
  void _onGs1Scanned(String raw) {
    if (raw.isEmpty) return;
    final data = parseGs1(raw);
    if (data.isEmpty) return;
    setState(() {
      if (data.lotNumber != null) _lotController.text = data.lotNumber!;
      if (data.expirationDate != null) {
        _expirationController.text = data.expirationDate!
            .toIso8601String()
            .substring(0, 10);
      }
    });
    if (data.gtin != null) {
      _searchProducts(data.gtin!);
    }
  }

  Future<void> _searchProducts(String term) async {
    final results = await ref
        .read(productsRepositoryProvider)
        .watchProducts(search: term)
        .first;
    setState(() {
      _productResults = results;
      if (results.length == 1) _selectedProduct = results.first;
    });
  }

  Future<void> _save() async {
    final product = _selectedProduct;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (product == null || quantity <= 0) return;
    final expiration = DateTime.tryParse(_expirationController.text);
    await ref
        .read(stockRepositoryProvider)
        .receiveStock(
          tenantId: widget.tenantId,
          productId: product.id,
          quantity: quantity,
          lotNumber: _lotController.text.trim().isEmpty
              ? null
              : _lotController.text.trim(),
          expirationDate: expiration,
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
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
              s.receiveOrderSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _gs1Controller,
                    decoration: InputDecoration(
                      labelText: s.scanOrPasteGs1,
                      prefixIcon: const Icon(Icons.qr_code_scanner),
                    ),
                    onChanged: _onGs1Scanned,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: s.scanWithCamera,
                  onPressed: () async {
                    final code = await showBarcodeScannerSheet(context);
                    if (code == null) return;
                    _gs1Controller.text = code;
                    _onGs1Scanned(code);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: s.productSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _searchProducts,
            ),
            for (final p in _productResults)
              ListTile(
                dense: true,
                selected: p.id == _selectedProduct?.id,
                title: Text(p.name),
                subtitle: Text(p.barcode ?? s.noCodeBarres),
                onTap: () => setState(() => _selectedProduct = p),
              ),
            if (_selectedProduct != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(s.selectedProduct(_selectedProduct!.name)),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _lotController,
              decoration: InputDecoration(labelText: s.lotNumber),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _expirationController,
              decoration: InputDecoration(
                labelText: s.expirationDateHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.quantityReceived),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: Text(s.save)),
          ],
        ),
      ),
    );
  }
}
