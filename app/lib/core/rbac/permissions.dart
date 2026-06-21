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

/// Métadonnée d'affichage d'une permission (pour l'UI de gestion des rôles).
class PermissionInfo {
  const PermissionInfo(this.code, this.label, this.module);
  final String code;
  final String label;
  final String module;
}

/// Catalogue présentable des permissions (miroir de `0002_seed_permissions`).
const permissionCatalog = <PermissionInfo>[
  PermissionInfo(Permissions.posSell, 'Encaisser une vente', 'Caisse'),
  PermissionInfo(Permissions.posRefund, 'Rembourser', 'Caisse'),
  PermissionInfo(
    Permissions.posDiscountApply,
    'Appliquer une remise',
    'Caisse',
  ),
  PermissionInfo(Permissions.posCashClose, 'Clôturer la caisse', 'Caisse'),
  PermissionInfo(Permissions.stockView, 'Consulter le stock', 'Stock'),
  PermissionInfo(Permissions.stockAdjust, 'Ajuster le stock', 'Stock'),
  PermissionInfo(Permissions.stockTransfer, 'Transférer', 'Stock'),
  PermissionInfo(Permissions.stockReceive, 'Réceptionner', 'Stock'),
  PermissionInfo(Permissions.productCreate, 'Créer un produit', 'Catalogue'),
  PermissionInfo(Permissions.priceEdit, 'Modifier un prix', 'Catalogue'),
  PermissionInfo(
    Permissions.supplierManage,
    'Gérer les fournisseurs',
    'Achats',
  ),
  PermissionInfo(Permissions.purchaseOrder, 'Bon de commande', 'Achats'),
  PermissionInfo(
    Permissions.invoiceIssue,
    'Émettre une facture',
    'Facturation',
  ),
  PermissionInfo(
    Permissions.reportFinancialView,
    'Rapports financiers',
    'Pilotage',
  ),
  PermissionInfo(
    Permissions.traceLotView,
    'Traçabilité d\'un lot',
    'Traçabilité',
  ),
  PermissionInfo(Permissions.auditViewOwn, 'Voir ses actions', 'Traçabilité'),
  PermissionInfo(Permissions.auditViewAll, 'Voir tout l\'audit', 'Traçabilité'),
  PermissionInfo(
    Permissions.traceExport,
    'Exporter la traçabilité',
    'Traçabilité',
  ),
  PermissionInfo(Permissions.userManage, 'Gérer utilisateurs & rôles', 'Admin'),
  PermissionInfo(Permissions.settingsManage, 'Paramètres pharmacie', 'Admin'),
  PermissionInfo(Permissions.aiAssistantUse, 'Assistant IA', 'IA'),
];

/// Tous les codes de permission (utile pour le mode dev local).
final allPermissionCodes = permissionCatalog.map((p) => p.code).toSet();
