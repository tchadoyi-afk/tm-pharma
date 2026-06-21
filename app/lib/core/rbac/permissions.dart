/// Catalogue des permissions atomiques (miroir de `supabase/migrations/0002`).
/// Utiliser ces constantes plutôt que des chaînes en dur dans l'app.
class Permissions {
  Permissions._();

  // Caisse / vente
  static const posSell = 'pos.sell';
  static const posRefund = 'pos.refund';
  static const posDiscountApply = 'pos.discount.apply';
  static const posCashClose = 'pos.cash.close';

  // Stock
  static const stockView = 'stock.view';
  static const stockAdjust = 'stock.adjust';
  static const stockTransfer = 'stock.transfer';
  static const stockReceive = 'stock.receive';

  // Catalogue / prix
  static const productCreate = 'product.create';
  static const priceEdit = 'price.edit';

  // Achats / réappro
  static const supplierManage = 'supplier.manage';
  static const purchaseOrder = 'purchase.order';

  // Facturation
  static const invoiceIssue = 'invoice.issue';

  // Pilotage
  static const reportFinancialView = 'report.financial.view';

  // Traçabilité (accès restreint)
  static const traceLotView = 'trace.lot.view';
  static const auditViewOwn = 'audit.view.own';
  static const auditViewAll = 'audit.view.all';
  static const traceExport = 'trace.export';

  // Administration
  static const userManage = 'user.manage';
  static const settingsManage = 'settings.manage';

  // IA
  static const aiAssistantUse = 'ai.assistant.use';
}

/// Ensemble immuable des permissions d'un utilisateur, avec helpers.
class PermissionSet {
  PermissionSet(Iterable<String> codes) : _codes = Set.unmodifiable(codes);

  const PermissionSet.empty() : _codes = const {};

  final Set<String> _codes;

  bool can(String code) => _codes.contains(code);
  bool canAny(Iterable<String> codes) => codes.any(_codes.contains);
  bool canAll(Iterable<String> codes) => codes.every(_codes.contains);

  Set<String> get codes => _codes;
  bool get isEmpty => _codes.isEmpty;
}
