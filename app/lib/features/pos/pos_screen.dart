import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../core/i18n/strings.dart';
import '../../core/rbac/permission_gate.dart';
import '../../core/rbac/permissions.dart';
import '../../core/scanning/barcode_scanner_sheet.dart';
import '../../core/sync/sync_service.dart';
import '../catalog/product_model.dart';
import '../catalog/products_repository.dart';
import '../fraud/fraud_signals.dart';
import '../invoicing/invoice_models.dart';
import '../invoicing/invoice_pdf.dart';
import '../invoicing/invoice_repository.dart';
import '../promotions/promotion_pricing.dart';
import '../promotions/promotions_repository.dart';
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

  Future<void> _addToCart(Product product) async {
    final promotions = await ref
        .read(promotionsRepositoryProvider)
        .watchPromotions()
        .first;
    final unitPrice = applyActivePromotion(
      unitPrice: product.sellingPrice,
      promotions: promotions,
      productId: product.id,
      now: DateTime.now(),
    );
    setState(() {
      _cart = _cart.addProduct(
        productId: product.id,
        productName: product.name,
        unitPrice: unitPrice,
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
          SnackBar(
            content: Text(Strings.of(context).insufficientStock(e.productName)),
          ),
        );
      }
    }
  }

  Future<void> _showPrintOptions(InvoiceData invoice) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        final s = Strings.of(context);
        return AlertDialog(
          title: Text(s.saleRecordedTitle(invoice.invoiceNumber)),
          content: Text(s.printTicketOrInvoice),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(s.close),
            ),
            TextButton(
              onPressed: () async {
                final bytes = await buildThermalTicketPdf(invoice, s);
                await Printing.layoutPdf(onLayout: (_) async => bytes);
              },
              child: Text(s.thermalTicket),
            ),
            FilledButton(
              onPressed: () async {
                final bytes = await buildInvoicePdf(invoice, s);
                await Printing.layoutPdf(onLayout: (_) async => bytes);
              },
              child: Text(s.invoicePdf),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openSession() async {
    await ref
        .read(posRepositoryProvider)
        .openCashSession(tenantId: PosScreen.demoTenantId);
  }

  Future<void> _closeSession(String sessionId) async {
    final repo = ref.read(posRepositoryProvider);
    final rows = await repo.getSalesForSession(sessionId);
    final signals = detectFraudSignals(
      rows
          .map(
            (r) => FraudSaleSample(
              totalAmount: (r['total_amount'] as num).toDouble(),
              soldAt: DateTime.parse(r['sold_at'] as String),
            ),
          )
          .toList(),
    );
    if (signals.isNotEmpty && mounted) {
      final proceed = await _showFraudSignalsDialog(signals);
      if (proceed != true) return;
    }
    await repo.closeCashSession(sessionId);
  }

  Future<bool?> _showFraudSignalsDialog(List<FraudSignal> signals) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final s = Strings.of(context);
        return AlertDialog(
          title: Text(s.anomaliesDetected),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final signal in signals)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('• ${signal.message}'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(s.closeAnyway),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = ref.watch(syncServiceProvider).isReady;
    final s = Strings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.posTitle)),
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
    final s = Strings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.noOpenSession),
            const SizedBox(height: 16),
            PermissionGate(
              permission: Permissions.posSell,
              child: FilledButton.icon(
                icon: const Icon(Icons.point_of_sale),
                label: Text(s.openCashSession),
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
  final Future<void> Function(Product) onAdd;
  final void Function(String productId) onRemove;
  final Future<void> Function(String sessionId) onCheckout;
  final Future<void> Function(String sessionId) onCloseSession;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = Strings.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.qr_code_scanner),
                    labelText: s.searchOrScanProduct,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.camera_alt_outlined),
                tooltip: s.scanWithCamera,
                onPressed: () async {
                  final code = await showBarcodeScannerSheet(context);
                  if (code == null) return;
                  searchController.text = code;
                  onSearchChanged(code);
                },
              ),
              const SizedBox(width: 8),
              PermissionGate(
                permission: Permissions.posCashClose,
                child: OutlinedButton(
                  onPressed: () => onCloseSession(sessionId),
                  child: Text(s.closeSession),
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
              ? Center(child: Text(s.emptyCart))
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
                    label: Text(s.checkoutCash),
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
