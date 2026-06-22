import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';
import '../../core/sync/sync_service.dart';
import '../catalog/product_model.dart';
import '../catalog/products_repository.dart';
import '../invoicing/invoice_models.dart';
import '../invoicing/invoice_pdf.dart';
import '../invoicing/invoice_repository.dart';
import 'cart_model.dart';
import 'pos_repository.dart';

/// Caisse offline-first (Sprint 7) : recherche/scan code-barres, panier,
/// encaissement espèces, clôture de caisse (total calculé, pas saisi).
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  static const demoTenantId = '00000000-0000-0000-0000-000000000001';

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  Cart _cart = Cart.empty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    setState(() {
      _cart = _cart.addProduct(
        productId: product.id,
        productName: product.name,
        unitPrice: product.sellingPrice,
      );
    });
  }

  void _removeFromCart(String productId) {
    setState(() => _cart = _cart.removeProduct(productId));
  }

  Future<void> _checkout(String cashSessionId) async {
    final repo = ref.read(posRepositoryProvider);
    try {
      final saleId = await repo.checkout(
        tenantId: PosScreen.demoTenantId,
        cashSessionId: cashSessionId,
        cart: _cart,
      );
      setState(() => _cart = Cart.empty);
      if (saleId.isEmpty) return;
      final invoice = await ref
          .read(invoiceRepositoryProvider)
          .createInvoice(tenantId: PosScreen.demoTenantId, saleId: saleId);
      if (mounted) await _showPrintOptions(invoice);
    } on InsufficientStockException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stock insuffisant : ${e.productName}')),
        );
      }
    }
  }

  Future<void> _showPrintOptions(InvoiceData invoice) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vente encaissée — ${invoice.invoiceNumber}'),
        content: const Text('Imprimer le ticket ou la facture ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          TextButton(
            onPressed: () async {
              final bytes = await buildThermalTicketPdf(invoice);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
            child: const Text('Ticket thermique'),
          ),
          FilledButton(
            onPressed: () async {
              final bytes = await buildInvoicePdf(invoice);
              await Printing.layoutPdf(onLayout: (_) async => bytes);
            },
            child: const Text('Facture PDF'),
          ),
        ],
      ),
    );
  }

  Future<void> _openSession() async {
    await ref
        .read(posRepositoryProvider)
        .openCashSession(tenantId: PosScreen.demoTenantId);
  }

  Future<void> _closeSession(String sessionId) async {
    await ref.read(posRepositoryProvider).closeCashSession(sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(syncServiceProvider).isReady;

    return Scaffold(
      appBar: AppBar(title: const Text('Caisse')),
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
          : StreamBuilder<Map<String, Object?>?>(
              stream: ref.read(posRepositoryProvider).watchOpenCashSession(),
              builder: (context, sessionSnap) {
                final session = sessionSnap.data;
                if (session == null) {
                  return _NoSessionView(onOpen: _openSession);
                }
                return _CheckoutView(
                  sessionId: session['id'] as String,
                  cart: _cart,
                  searchController: _searchController,
                  onSearchChanged: (v) => setState(() => _search = v),
                  search: _search,
                  onAdd: _addToCart,
                  onRemove: _removeFromCart,
                  onCheckout: _checkout,
                  onCloseSession: _closeSession,
                );
              },
            ),
    );
  }
}

class _NoSessionView extends StatelessWidget {
  const _NoSessionView({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aucune session de caisse ouverte.'),
            const SizedBox(height: 16),
            PermissionGate(
              permission: Permissions.posSell,
              child: FilledButton.icon(
                icon: const Icon(Icons.point_of_sale),
                label: const Text('Ouvrir la caisse'),
                onPressed: onOpen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutView extends ConsumerWidget {
  const _CheckoutView({
    required this.sessionId,
    required this.cart,
    required this.searchController,
    required this.onSearchChanged,
    required this.search,
    required this.onAdd,
    required this.onRemove,
    required this.onCheckout,
    required this.onCloseSession,
  });

  final String sessionId;
  final Cart cart;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String search;
  final void Function(Product) onAdd;
  final void Function(String productId) onRemove;
  final Future<void> Function(String sessionId) onCheckout;
  final Future<void> Function(String sessionId) onCloseSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.qr_code_scanner),
                    labelText: 'Scanner / chercher un produit',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              PermissionGate(
                permission: Permissions.posCashClose,
                child: OutlinedButton(
                  onPressed: () => onCloseSession(sessionId),
                  child: const Text('Clôturer'),
                ),
              ),
            ],
          ),
        ),
        if (search.isNotEmpty)
          SizedBox(
            height: 160,
            child: StreamBuilder<List<Product>>(
              stream: ref
                  .read(productsRepositoryProvider)
                  .watchProducts(search: search),
              builder: (context, snap) {
                final products = snap.data ?? const [];
                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, i) {
                    final p = products[i];
                    return ListTile(
                      dense: true,
                      title: Text(p.name),
                      subtitle: Text(
                        '${p.sellingPrice.toStringAsFixed(0)} XOF',
                      ),
                      onTap: () => onAdd(p),
                    );
                  },
                );
              },
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: cart.isEmpty
              ? const Center(child: Text('Panier vide.'))
              : ListView.builder(
                  itemCount: cart.lines.length,
                  itemBuilder: (context, i) {
                    final line = cart.lines[i];
                    return ListTile(
                      title: Text(line.productName),
                      subtitle: Text(
                        '${line.quantity} × ${line.unitPrice.toStringAsFixed(0)} XOF',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${line.subtotal.toStringAsFixed(0)} XOF'),
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => onRemove(line.productId),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Total : ${cart.total.toStringAsFixed(0)} XOF',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                PermissionGate(
                  permission: Permissions.posSell,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Encaisser (espèces)'),
                    onPressed: cart.isEmpty
                        ? null
                        : () => onCheckout(sessionId),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
