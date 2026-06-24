import 'package:flutter/widgets.dart';

/// i18n léger FR/EN pour le socle (Sprint 1).
/// Migration vers ARB + flutter gen-l10n prévue quand le volume de chaînes
/// augmentera (Sprint 4+).
class Strings {
  Strings(this.locale);
  final Locale locale;

  static Strings of(BuildContext context) =>
      Localizations.of<Strings>(context, Strings)!;

  static const supportedLocales = [Locale('fr'), Locale('en')];

  static const _values = <String, Map<String, String>>{
    'appName': {'fr': 'TM Pharma', 'en': 'TM Pharma'},
    'tagline': {
      'fr': 'Gestion de pharmacie, même hors-ligne',
      'en': 'Pharmacy management, even offline',
    },
    'welcome': {'fr': 'Socle technique prêt', 'en': 'Technical core ready'},
    'sprint1': {
      'fr': 'Sprint 1 — Socle & sécurité',
      'en': 'Sprint 1 — Core & security',
    },
    'language': {'fr': 'Langue', 'en': 'Language'},
    'theme': {'fr': 'Thème', 'en': 'Theme'},

    // Shared / common actions.
    'cancel': {'fr': 'Annuler', 'en': 'Cancel'},
    'save': {'fr': 'Enregistrer', 'en': 'Save'},
    'edit': {'fr': 'Modifier', 'en': 'Edit'},
    'close': {'fr': 'Fermer', 'en': 'Close'},
    'none': {'fr': 'Aucun', 'en': 'None'},
    'noCodeBarres': {'fr': 'sans code-barres', 'en': 'no barcode'},
    'noCode': {'fr': 'sans code', 'en': 'no code'},
    'localDbNotInitialized': {
      'fr': 'Base locale non initialisée sur cette plateforme.',
      'en': 'Local database not initialized on this platform.',
    },
    'errorPrefix': {'fr': 'Erreur', 'en': 'Error'},

    // Home screen.
    'navDashboard': {'fr': 'Tableau de bord', 'en': 'Dashboard'},
    'navPos': {'fr': 'Caisse', 'en': 'Checkout'},
    'navPosDemo': {'fr': 'Démo vente offline', 'en': 'Offline sale demo'},
    'navCatalog': {'fr': 'Catalogue produits', 'en': 'Product catalog'},
    'navStock': {'fr': 'Stocks', 'en': 'Stock'},
    'navSuppliers': {'fr': 'Fournisseurs', 'en': 'Suppliers'},
    'navOnboarding': {
      'fr': 'Assistant d\'onboarding',
      'en': 'Onboarding assistant',
    },
    'navRoles': {'fr': 'Permissions & rôles', 'en': 'Permissions & roles'},
    'navPharmacySettings': {
      'fr': 'Paramètres de la pharmacie',
      'en': 'Pharmacy settings',
    },
    'navLifecycle': {
      'fr': 'Péremptions & sorties',
      'en': 'Expiry & stock exits',
    },
    'navPromotions': {'fr': 'Promotions', 'en': 'Promotions'},
    'navReorder': {
      'fr': 'Suggestions de réappro',
      'en': 'Reorder suggestions',
    },
    'navPurchaseOrders': {
      'fr': 'Bons de commande',
      'en': 'Purchase orders',
    },
    'navAudit': {'fr': 'Journal d\'audit', 'en': 'Audit log'},
    'navAssistant': {'fr': 'Assistant IA', 'en': 'AI assistant'},
    'languageFr': {'fr': 'Français', 'en': 'French'},
    'languageEn': {'fr': 'English', 'en': 'English'},

    // POS screen.
    'posTitle': {'fr': 'Caisse', 'en': 'Checkout'},
    'noOpenSession': {
      'fr': 'Aucune session de caisse ouverte.',
      'en': 'No open cash session.',
    },
    'openCashSession': {'fr': 'Ouvrir la caisse', 'en': 'Open cash session'},
    'searchOrScanProduct': {
      'fr': 'Scanner / chercher un produit',
      'en': 'Scan / search for a product',
    },
    'scanWithCamera': {
      'fr': 'Scanner avec la caméra',
      'en': 'Scan with the camera',
    },
    'closeSession': {'fr': 'Clôturer', 'en': 'Close session'},
    'emptyCart': {'fr': 'Panier vide.', 'en': 'Empty cart.'},
    'checkoutCash': {
      'fr': 'Encaisser (espèces)',
      'en': 'Check out (cash)',
    },
    'saleRecordedTitlePrefix': {
      'fr': 'Vente encaissée',
      'en': 'Sale recorded',
    },
    'printTicketOrInvoice': {
      'fr': 'Imprimer le ticket ou la facture ?',
      'en': 'Print the receipt or the invoice?',
    },
    'thermalTicket': {'fr': 'Ticket thermique', 'en': 'Thermal ticket'},
    'invoicePdf': {'fr': 'Facture PDF', 'en': 'PDF invoice'},
    'anomaliesDetected': {
      'fr': 'Anomalies détectées',
      'en': 'Anomalies detected',
    },
    'closeAnyway': {
      'fr': 'Clôturer malgré tout',
      'en': 'Close anyway',
    },

    // Catalog screen.
    'catalogTitle': {'fr': 'Catalogue produits', 'en': 'Product catalog'},
    'searchProductHint': {
      'fr': 'Rechercher (nom, DCI, code-barres)',
      'en': 'Search (name, INN, barcode)',
    },
    'noProductYet': {
      'fr': 'Aucun produit pour le moment.',
      'en': 'No product yet.',
    },
    'defaultSupplier': {
      'fr': 'Fournisseur par défaut',
      'en': 'Default supplier',
    },
    'editPrice': {'fr': 'Modifier le prix', 'en': 'Edit price'},
    'attachBarcode': {
      'fr': 'Associer un code-barres',
      'en': 'Attach a barcode',
    },
    'barcode': {'fr': 'Code-barres', 'en': 'Barcode'},
    'associate': {'fr': 'Associer', 'en': 'Attach'},
    'newProduct': {'fr': 'Nouveau produit', 'en': 'New product'},
    'searchReferenceCatalogHint': {
      'fr': 'Chercher dans le catalogue de référence (DCI)',
      'en': 'Search the reference catalog (INN)',
    },
    'productName': {'fr': 'Nom du produit', 'en': 'Product name'},
    'sellingPrice': {'fr': 'Prix de vente', 'en': 'Selling price'},

    // Onboarding screen.
    'onboardingTitle': {
      'fr': 'Assistant d\'onboarding',
      'en': 'Onboarding assistant',
    },
    'initialInventoryRecorded': {
      'fr': 'Inventaire initial enregistré.',
      'en': 'Initial inventory recorded.',
    },
    'stepImportCatalog': {
      'fr': 'Import du catalogue (CSV)',
      'en': 'Catalog import (CSV)',
    },
    'csvImportInstructions': {
      'fr':
          'Collez le contenu d\'un fichier CSV avec les colonnes : '
          'nom, code_barres, prix, dci, categorie.',
      'en':
          'Paste the contents of a CSV file with the columns: '
          'name, barcode, price, inn, category.',
    },
    'csvHint': {
      'fr': 'nom,code_barres,prix,dci,categorie',
      'en': 'name,barcode,price,inn,category',
    },
    'preview': {'fr': 'Prévisualiser', 'en': 'Preview'},
    'import': {'fr': 'Importer', 'en': 'Import'},
    'stepInitialInventory': {
      'fr': 'Inventaire initial',
      'en': 'Initial inventory',
    },
    'finishOnboarding': {
      'fr': 'Terminer l\'onboarding',
      'en': 'Finish onboarding',
    },

    // Purchase orders screen.
    'purchaseOrdersTitle': {
      'fr': 'Bons de commande',
      'en': 'Purchase orders',
    },
    'noPurchaseOrderYet': {
      'fr': 'Aucun bon de commande pour le moment.',
      'en': 'No purchase order yet.',
    },
    'supplierNotSet': {
      'fr': 'Fournisseur non renseigné',
      'en': 'No supplier set',
    },
    'statusDraft': {'fr': 'Brouillon', 'en': 'Draft'},
    'statusSent': {'fr': 'Envoyée', 'en': 'Sent'},
    'statusConfirmed': {
      'fr': 'Confirmée par le fournisseur',
      'en': 'Confirmed by supplier',
    },
    'statusPartiallyReceived': {
      'fr': 'Reçue partiellement',
      'en': 'Partially received',
    },
    'statusReceived': {'fr': 'Reçue', 'en': 'Received'},
    'statusCancelled': {'fr': 'Annulée', 'en': 'Cancelled'},
    'receiveOrder': {'fr': 'Réceptionner', 'en': 'Receive'},
    'validateAndSend': {
      'fr': 'Valider et envoyer',
      'en': 'Validate and send',
    },
    'receiveTheOrder': {
      'fr': 'Réceptionner la commande',
      'en': 'Receive the order',
    },
    'validate': {'fr': 'Valider', 'en': 'Validate'},

    // Roles screen.
    'rolesTitle': {'fr': 'Permissions & rôles', 'en': 'Permissions & roles'},
    'roles': {'fr': 'Rôles', 'en': 'Roles'},
    'availablePermissions': {
      'fr': 'Permissions disponibles',
      'en': 'Available permissions',
    },
    'localMode': {'fr': 'Mode local', 'en': 'Local mode'},
    'localModeRolesHint': {
      'fr':
          'La création de rôles et l\'assignation des permissions seront '
          'actives une fois Supabase configuré.',
      'en':
          'Role creation and permission assignment will be active once '
          'Supabase is configured.',
    },
    'noRoleYet': {'fr': 'Aucun rôle pour le moment.', 'en': 'No role yet.'},
    'systemRole': {'fr': 'Rôle système', 'en': 'System role'},

    // Stock screen.
    'stockTitle': {'fr': 'Stocks', 'en': 'Stock'},
    'receiveStock': {'fr': 'Réceptionner', 'en': 'Receive'},
    'noProductInStock': {
      'fr': 'Aucun produit en stock.',
      'en': 'No product in stock.',
    },
    'receiveOrderSheetTitle': {
      'fr': 'Réceptionner une commande',
      'en': 'Receive an order',
    },
    'scanOrPasteGs1': {
      'fr': 'Scanner / coller le code GS1-128',
      'en': 'Scan / paste the GS1-128 code',
    },
    'productSearchHint': {
      'fr': 'Produit (nom, DCI, code-barres)',
      'en': 'Product (name, INN, barcode)',
    },
    'lotNumber': {'fr': 'Numéro de lot', 'en': 'Lot number'},
    'expirationDateHint': {
      'fr': 'Date de péremption (AAAA-MM-JJ)',
      'en': 'Expiration date (YYYY-MM-DD)',
    },
    'quantityReceived': {'fr': 'Quantité reçue', 'en': 'Quantity received'},

    // Promotions screen.
    'promotionsTitle': {'fr': 'Promotions', 'en': 'Promotions'},
    'newPromotion': {'fr': 'Nouvelle promotion', 'en': 'New promotion'},
    'noPromotion': {'fr': 'Aucune promotion.', 'en': 'No promotion.'},
    'active': {'fr': 'Active', 'en': 'Active'},
    'discountPercent': {'fr': 'Remise (%)', 'en': 'Discount (%)'},
    'create': {'fr': 'Créer', 'en': 'Create'},

    // Lifecycle screen.
    'lifecycleTitle': {
      'fr': 'Péremptions & sorties',
      'en': 'Expiry & stock exits',
    },
    'stockExit': {'fr': 'Sortie de stock', 'en': 'Stock exit'},
    'noLotNearExpiry': {
      'fr': 'Aucun lot proche de la péremption.',
      'en': 'No lot close to expiry.',
    },
    'exitReasonDonation': {'fr': 'Don', 'en': 'Donation'},
    'exitReasonSupplierReturn': {
      'fr': 'Retour fournisseur',
      'en': 'Supplier return',
    },
    'exitReasonTransfer': {
      'fr': 'Transfert vers une autre pharmacie',
      'en': 'Transfer to another pharmacy',
    },
    'exitReasonScrap': {
      'fr': 'Rebut (périmé / abîmé)',
      'en': 'Scrap (expired / damaged)',
    },
    'alertExpired': {'fr': 'Expiré', 'en': 'Expired'},
    'alertJ7': {'fr': 'J-7', 'en': 'D-7'},
    'alertJ30': {'fr': 'J-30', 'en': 'D-30'},
    'alertJ90': {'fr': 'J-90', 'en': 'D-90'},
    'stockExitSheetTitle': {
      'fr': 'Sortie de stock (hors vente)',
      'en': 'Stock exit (non-sale)',
    },
    'exitType': {'fr': 'Type de sortie', 'en': 'Exit type'},
    'lot': {'fr': 'Lot', 'en': 'Lot'},
    'quantity': {'fr': 'Quantité', 'en': 'Quantity'},
    'reasonOptional': {'fr': 'Motif (optionnel)', 'en': 'Reason (optional)'},

    // Suppliers screen.
    'suppliersTitle': {'fr': 'Fournisseurs', 'en': 'Suppliers'},
    'noSupplierYet': {
      'fr': 'Aucun fournisseur pour le moment.',
      'en': 'No supplier yet.',
    },
    'newSupplier': {'fr': 'Nouveau fournisseur', 'en': 'New supplier'},
    'editSupplier': {
      'fr': 'Modifier le fournisseur',
      'en': 'Edit supplier',
    },
    'name': {'fr': 'Nom', 'en': 'Name'},
    'phone': {'fr': 'Téléphone', 'en': 'Phone'},
    'email': {'fr': 'Email', 'en': 'Email'},
    'usualLeadTime': {
      'fr': 'Délai de livraison habituel',
      'en': 'Usual lead time',
    },
    'daysSuffix': {'fr': 'jours', 'en': 'days'},

    // Reorder screen.
    'reorderTitle': {
      'fr': 'Suggestions de réappro',
      'en': 'Reorder suggestions',
    },
    'noSuggestion': {
      'fr': 'Aucune suggestion : stocks au-dessus du seuil.',
      'en': 'No suggestion: stock above threshold.',
    },
    'createPurchaseOrders': {
      'fr': 'Créer le(s) bon(s) de commande',
      'en': 'Create purchase order(s)',
    },
    'purchaseOrderCreated': {
      'fr': 'Bon de commande créé.',
      'en': 'Purchase order created.',
    },

    // POS demo screen.
    'posDemoTitle': {'fr': 'Démo vente offline', 'en': 'Offline sale demo'},
    'localDbNotInitializedAndroidWeb': {
      'fr':
          'Base locale non initialisée sur cette plateforme.\n'
          'Lancer sur Android/Web configuré pour tester.',
      'en':
          'Local database not initialized on this platform.\n'
          'Run on Android/Web with config to test.',
    },
    'salesInLocalDb': {
      'fr': 'ventes en base locale',
      'en': 'sales in local database',
    },
    'createTestSale': {
      'fr': 'Créer une vente de test',
      'en': 'Create a test sale',
    },
    'saleRecordedLocallyQueued': {
      'fr': 'Vente enregistrée en local, en file de synchro',
      'en': 'Sale recorded locally, queued for sync',
    },
    'offlineWorksHint': {
      'fr':
          'Fonctionne sans réseau. La synchro se fera dès qu\'une '
          'instance Supabase + PowerSync sera configurée et connectée.',
      'en':
          'Works without network. Sync will happen once a Supabase + '
          'PowerSync instance is configured and connected.',
    },

    // Dashboard screen.
    'dashboardTitle': {'fr': 'Tableau de bord', 'en': 'Dashboard'},
    'sectionDirectionFinancialKpis': {
      'fr': 'Direction — KPI financiers',
      'en': 'Management — financial KPIs',
    },
    'kpiSalesToday': {'fr': 'Ventes du jour', 'en': 'Sales today'},
    'kpiRevenueToday': {'fr': 'CA du jour', 'en': 'Revenue today'},
    'kpiStockValue': {'fr': 'Valeur du stock', 'en': 'Stock value'},
    'sectionPharmacistStock': {
      'fr': 'Pharmacien — stock & péremptions',
      'en': 'Pharmacist — stock & expiry',
    },
    'kpiLowStockCount': {
      'fr': 'Produits sous le seuil',
      'en': 'Products below threshold',
    },
    'kpiExpiringSoon': {
      'fr': 'Lots périment <30j',
      'en': 'Lots expiring <30d',
    },
    'sectionCashier': {'fr': 'Caissier', 'en': 'Cashier'},
    'seeCashierForDetail': {
      'fr': 'Voir « Caisse » pour le détail de la session du jour.',
      'en': 'See "Checkout" for today\'s session detail.',
    },

    // Audit screen.
    'auditTitle': {'fr': 'Journal d\'audit', 'en': 'Audit log'},
    'exportCsv': {'fr': 'Exporter en CSV', 'en': 'Export to CSV'},
    'noActionLogged': {
      'fr': 'Aucune action journalisée.',
      'en': 'No action logged.',
    },
    'csvExportCopied': {
      'fr': 'Export CSV copié dans le presse-papier.',
      'en': 'CSV export copied to the clipboard.',
    },

    // Lot traceability screen.
    'noMovementRecorded': {
      'fr': 'Aucun mouvement enregistré.',
      'en': 'No movement recorded.',
    },

    // Pharmacy settings screen.
    'pharmacySettingsTitle': {
      'fr': 'Paramètres de la pharmacie',
      'en': 'Pharmacy settings',
    },
    'settingsSaved': {
      'fr': 'Réglages enregistrés.',
      'en': 'Settings saved.',
    },
    'changeLogo': {'fr': 'Changer le logo', 'en': 'Change logo'},
    'legalName': {'fr': 'Raison sociale', 'en': 'Legal name'},
    'currencyHint': {
      'fr': 'Devise (ex. XOF, XAF)',
      'en': 'Currency (e.g. XOF, XAF)',
    },
    'invoicePrefixLabel': {
      'fr': 'Préfixe de numérotation des factures',
      'en': 'Invoice numbering prefix',
    },

    // Login screen.
    'email_': {'fr': 'Email', 'en': 'Email'},
    'password': {'fr': 'Mot de passe', 'en': 'Password'},
    'signIn': {'fr': 'Se connecter', 'en': 'Sign in'},
    'localModeLoginHint': {
      'fr':
          'Mode local : configurez Supabase pour activer la '
          'connexion (voir app/.env.example).',
      'en':
          'Local mode: configure Supabase to enable sign-in '
          '(see app/.env.example).',
    },

    // Assistant screen.
    'assistantTitle': {'fr': 'Assistant', 'en': 'Assistant'},
    'assistantNotConfigured': {
      'fr':
          'Assistant non configuré : le backend IA en ligne n\'est pas '
          'encore provisionné pour cette installation.',
      'en':
          'Assistant not configured: the online AI backend has not '
          'been provisioned yet for this installation.',
    },
    'assistantNotConfiguredBanner': {
      'fr':
          'Assistant non configuré sur cette installation (backend IA '
          'en ligne pas encore provisionné).',
      'en':
          'Assistant not configured on this installation (online AI '
          'backend not provisioned yet).',
    },
    'askAQuestionHint': {
      'fr': 'Poser une question…',
      'en': 'Ask a question…',
    },

    // Barcode scanner sheet.
    'scanABarcode': {
      'fr': 'Scanner un code-barres',
      'en': 'Scan a barcode',
    },

    // MFA.
    'mfaChallengeTitle': {
      'fr': 'Vérification en deux étapes',
      'en': 'Two-factor verification',
    },
    'mfaChallengePrompt': {
      'fr': 'Entrez le code à 6 chiffres de votre application d\'authentification.',
      'en': 'Enter the 6-digit code from your authenticator app.',
    },
    'mfaCodeLabel': {'fr': 'Code', 'en': 'Code'},
    'mfaVerify': {'fr': 'Vérifier', 'en': 'Verify'},
    'mfaInvalidCode': {
      'fr': 'Code invalide, veuillez réessayer.',
      'en': 'Invalid code, please try again.',
    },
    'mfaSettingsTitle': {
      'fr': 'Authentification à deux facteurs',
      'en': 'Two-factor authentication',
    },
    'mfaEnabledStatus': {
      'fr': 'Activée sur ce compte',
      'en': 'Enabled on this account',
    },
    'mfaDisabledStatus': {
      'fr': 'Non activée — votre compte est protégé uniquement par '
          'votre mot de passe.',
      'en': 'Not enabled — your account is only protected by your '
          'password.',
    },
    'mfaEnrollButton': {
      'fr': 'Activer la double authentification',
      'en': 'Enable two-factor authentication',
    },
    'mfaDisableButton': {
      'fr': 'Désactiver',
      'en': 'Disable',
    },
    'mfaScanQrPrompt': {
      'fr': 'Scannez ce code avec votre application d\'authentification '
          '(Google Authenticator, Authy…) ou saisissez la clé manuellement :',
      'en': 'Scan this code with your authenticator app (Google '
          'Authenticator, Authy…) or enter the key manually:',
    },
    'mfaConfirmCodePrompt': {
      'fr': 'Puis saisissez le code généré pour confirmer l\'activation :',
      'en': 'Then enter the generated code to confirm activation:',
    },
    'mfaEnrollSuccess': {
      'fr': 'Double authentification activée.',
      'en': 'Two-factor authentication enabled.',
    },
    'mfaDisableSuccess': {
      'fr': 'Double authentification désactivée.',
      'en': 'Two-factor authentication disabled.',
    },
    'navMfaSettings': {
      'fr': 'Double authentification',
      'en': 'Two-factor authentication',
    },
  };

  String _t(String key) =>
      _values[key]?[locale.languageCode] ?? _values[key]?['fr'] ?? key;

  bool get _isEn => locale.languageCode == 'en';

  String get appName => _t('appName');
  String get tagline => _t('tagline');
  String get welcome => _t('welcome');
  String get sprint1 => _t('sprint1');
  String get language => _t('language');
  String get theme => _t('theme');

  String get cancel => _t('cancel');
  String get save => _t('save');
  String get edit => _t('edit');
  String get close => _t('close');
  String get none => _t('none');
  String get noCodeBarres => _t('noCodeBarres');
  String get noCode => _t('noCode');
  String get localDbNotInitialized => _t('localDbNotInitialized');
  String get errorPrefix => _t('errorPrefix');

  String get navDashboard => _t('navDashboard');
  String get navPos => _t('navPos');
  String get navPosDemo => _t('navPosDemo');
  String get navCatalog => _t('navCatalog');
  String get navStock => _t('navStock');
  String get navSuppliers => _t('navSuppliers');
  String get navOnboarding => _t('navOnboarding');
  String get navRoles => _t('navRoles');
  String get navPharmacySettings => _t('navPharmacySettings');
  String get navLifecycle => _t('navLifecycle');
  String get navPromotions => _t('navPromotions');
  String get navReorder => _t('navReorder');
  String get navPurchaseOrders => _t('navPurchaseOrders');
  String get navAudit => _t('navAudit');
  String get navAssistant => _t('navAssistant');
  String get languageFr => _t('languageFr');
  String get languageEn => _t('languageEn');

  String get posTitle => _t('posTitle');
  String get noOpenSession => _t('noOpenSession');
  String get openCashSession => _t('openCashSession');
  String get searchOrScanProduct => _t('searchOrScanProduct');
  String get scanWithCamera => _t('scanWithCamera');
  String get closeSession => _t('closeSession');
  String get emptyCart => _t('emptyCart');
  String get checkoutCash => _t('checkoutCash');
  String get printTicketOrInvoice => _t('printTicketOrInvoice');
  String get thermalTicket => _t('thermalTicket');
  String get invoicePdf => _t('invoicePdf');
  String get anomaliesDetected => _t('anomaliesDetected');
  String get closeAnyway => _t('closeAnyway');

  String get catalogTitle => _t('catalogTitle');
  String get searchProductHint => _t('searchProductHint');
  String get noProductYet => _t('noProductYet');
  String get defaultSupplier => _t('defaultSupplier');
  String get editPrice => _t('editPrice');
  String get attachBarcode => _t('attachBarcode');
  String get barcode => _t('barcode');
  String get associate => _t('associate');
  String get newProduct => _t('newProduct');
  String get searchReferenceCatalogHint => _t('searchReferenceCatalogHint');
  String get productName => _t('productName');
  String get sellingPrice => _t('sellingPrice');

  String get onboardingTitle => _t('onboardingTitle');
  String get initialInventoryRecorded => _t('initialInventoryRecorded');
  String get stepImportCatalog => _t('stepImportCatalog');
  String get csvImportInstructions => _t('csvImportInstructions');
  String get csvHint => _t('csvHint');
  String get preview => _t('preview');
  String get import => _t('import');
  String get stepInitialInventory => _t('stepInitialInventory');
  String get finishOnboarding => _t('finishOnboarding');

  String get purchaseOrdersTitle => _t('purchaseOrdersTitle');
  String get noPurchaseOrderYet => _t('noPurchaseOrderYet');
  String get supplierNotSet => _t('supplierNotSet');
  String get statusDraft => _t('statusDraft');
  String get statusSent => _t('statusSent');
  String get statusConfirmed => _t('statusConfirmed');
  String get statusPartiallyReceived => _t('statusPartiallyReceived');
  String get statusReceived => _t('statusReceived');
  String get statusCancelled => _t('statusCancelled');
  String get receiveOrder => _t('receiveOrder');
  String get validateAndSend => _t('validateAndSend');
  String get receiveTheOrder => _t('receiveTheOrder');
  String get validate => _t('validate');

  String get rolesTitle => _t('rolesTitle');
  String get roles => _t('roles');
  String get availablePermissions => _t('availablePermissions');
  String get localMode => _t('localMode');
  String get localModeRolesHint => _t('localModeRolesHint');
  String get noRoleYet => _t('noRoleYet');
  String get systemRole => _t('systemRole');

  String get stockTitle => _t('stockTitle');
  String get receiveStock => _t('receiveStock');
  String get noProductInStock => _t('noProductInStock');
  String get receiveOrderSheetTitle => _t('receiveOrderSheetTitle');
  String get scanOrPasteGs1 => _t('scanOrPasteGs1');
  String get productSearchHint => _t('productSearchHint');
  String get lotNumber => _t('lotNumber');
  String get expirationDateHint => _t('expirationDateHint');
  String get quantityReceived => _t('quantityReceived');

  String get promotionsTitle => _t('promotionsTitle');
  String get newPromotion => _t('newPromotion');
  String get noPromotion => _t('noPromotion');
  String get active => _t('active');
  String get discountPercent => _t('discountPercent');
  String get create => _t('create');

  String get lifecycleTitle => _t('lifecycleTitle');
  String get stockExit => _t('stockExit');
  String get noLotNearExpiry => _t('noLotNearExpiry');
  String get exitReasonDonation => _t('exitReasonDonation');
  String get exitReasonSupplierReturn => _t('exitReasonSupplierReturn');
  String get exitReasonTransfer => _t('exitReasonTransfer');
  String get exitReasonScrap => _t('exitReasonScrap');
  String get alertExpired => _t('alertExpired');
  String get alertJ7 => _t('alertJ7');
  String get alertJ30 => _t('alertJ30');
  String get alertJ90 => _t('alertJ90');
  String get stockExitSheetTitle => _t('stockExitSheetTitle');
  String get exitType => _t('exitType');
  String get lot => _t('lot');
  String get quantity => _t('quantity');
  String get reasonOptional => _t('reasonOptional');

  String get suppliersTitle => _t('suppliersTitle');
  String get noSupplierYet => _t('noSupplierYet');
  String get newSupplier => _t('newSupplier');
  String get editSupplier => _t('editSupplier');
  String get name => _t('name');
  String get phone => _t('phone');
  String get email => _t('email_');
  String get usualLeadTime => _t('usualLeadTime');
  String get daysSuffix => _t('daysSuffix');

  String get reorderTitle => _t('reorderTitle');
  String get noSuggestion => _t('noSuggestion');
  String get createPurchaseOrders => _t('createPurchaseOrders');
  String get purchaseOrderCreated => _t('purchaseOrderCreated');

  String get posDemoTitle => _t('posDemoTitle');
  String get localDbNotInitializedAndroidWeb =>
      _t('localDbNotInitializedAndroidWeb');
  String get salesInLocalDb => _t('salesInLocalDb');
  String get createTestSale => _t('createTestSale');
  String get saleRecordedLocallyQueued => _t('saleRecordedLocallyQueued');
  String get offlineWorksHint => _t('offlineWorksHint');

  String get dashboardTitle => _t('dashboardTitle');
  String get sectionDirectionFinancialKpis =>
      _t('sectionDirectionFinancialKpis');
  String get kpiSalesToday => _t('kpiSalesToday');
  String get kpiRevenueToday => _t('kpiRevenueToday');
  String get kpiStockValue => _t('kpiStockValue');
  String get sectionPharmacistStock => _t('sectionPharmacistStock');
  String get kpiLowStockCount => _t('kpiLowStockCount');
  String get kpiExpiringSoon => _t('kpiExpiringSoon');
  String get sectionCashier => _t('sectionCashier');
  String get seeCashierForDetail => _t('seeCashierForDetail');

  String get auditTitle => _t('auditTitle');
  String get exportCsv => _t('exportCsv');
  String get noActionLogged => _t('noActionLogged');
  String get csvExportCopied => _t('csvExportCopied');

  String get noMovementRecorded => _t('noMovementRecorded');

  String get pharmacySettingsTitle => _t('pharmacySettingsTitle');
  String get settingsSaved => _t('settingsSaved');
  String get changeLogo => _t('changeLogo');
  String get legalName => _t('legalName');
  String get currencyHint => _t('currencyHint');
  String get invoicePrefixLabel => _t('invoicePrefixLabel');

  String get password => _t('password');
  String get signIn => _t('signIn');
  String get localModeLoginHint => _t('localModeLoginHint');

  String get assistantTitle => _t('assistantTitle');
  String get assistantNotConfigured => _t('assistantNotConfigured');
  String get assistantNotConfiguredBanner =>
      _t('assistantNotConfiguredBanner');
  String get askAQuestionHint => _t('askAQuestionHint');

  String get scanABarcode => _t('scanABarcode');

  String get mfaChallengeTitle => _t('mfaChallengeTitle');
  String get mfaChallengePrompt => _t('mfaChallengePrompt');
  String get mfaCodeLabel => _t('mfaCodeLabel');
  String get mfaVerify => _t('mfaVerify');
  String get mfaInvalidCode => _t('mfaInvalidCode');
  String get mfaSettingsTitle => _t('mfaSettingsTitle');
  String get mfaEnabledStatus => _t('mfaEnabledStatus');
  String get mfaDisabledStatus => _t('mfaDisabledStatus');
  String get mfaEnrollButton => _t('mfaEnrollButton');
  String get mfaDisableButton => _t('mfaDisableButton');
  String get mfaScanQrPrompt => _t('mfaScanQrPrompt');
  String get mfaConfirmCodePrompt => _t('mfaConfirmCodePrompt');
  String get mfaEnrollSuccess => _t('mfaEnrollSuccess');
  String get mfaDisableSuccess => _t('mfaDisableSuccess');
  String get navMfaSettings => _t('navMfaSettings');

  // Parametrized strings (interpolation + static template).
  String insufficientStock(String productName) => _isEn
      ? 'Insufficient stock: $productName'
      : 'Stock insuffisant : $productName';

  String saleRecordedTitle(String invoiceNumber) => _isEn
      ? 'Sale recorded — $invoiceNumber'
      : 'Vente encaissée — $invoiceNumber';

  String alertThreshold(int threshold) =>
      _isEn ? 'Alert threshold: $threshold' : 'Seuil d\'alerte : $threshold';

  String qtyLine(int quantity) =>
      _isEn ? 'qty $quantity' : 'qté $quantity';

  String qtyLineReceived(int quantity, int received) => _isEn
      ? 'qty $quantity (received $received)'
      : 'qté $quantity (reçu $received)';

  String productFallback(String shortId) =>
      _isEn ? 'Product $shortId' : 'Produit $shortId';

  String permissionCount(int count) =>
      _isEn ? '$count permission(s)' : '$count permission(s)';

  String expectedRemaining(int remaining) => _isEn
      ? 'Expected remaining: $remaining'
      : 'Reliquat attendu : $remaining';

  String csvPreviewSummary(int lineCount, int duplicateCount) => _isEn
      ? '$lineCount line(s) — $duplicateCount duplicate(s) ignored'
      : '$lineCount ligne(s) — $duplicateCount doublon(s) ignoré(s)';

  String importedProductsSummary(int count) => _isEn
      ? '$count product(s) imported. Enter the starting quantity for '
          'each (0 = no stock for now).'
      : '$count produit(s) importé(s). Saisissez la quantité de départ '
          'pour chacun (0 = pas de stock pour le moment).';

  String selectedProduct(String productName) =>
      _isEn ? 'Selected: $productName' : 'Sélectionné : $productName';

  String stockLotDropdownLabel(String productName, int quantity) =>
      _isEn ? '$productName (qty $quantity)' : '$productName (qté $quantity)';

  String purchaseOrdersCreatedSummary(int count) => _isEn
      ? '$count purchase orders created (1 per supplier).'
      : '$count bons de commande créés (1 par fournisseur).';

  String leadTimeDaysLabel(int days) =>
      _isEn ? '$days day(s) delivery' : '$days j de livraison';

  String promotionDateRange(String startIso, String endIso) => _isEn
      ? 'From $startIso to $endIso'
      : 'Du $startIso au $endIso';

  String reorderSubtitle(int current, int suggested, String? supplierName) {
    final base = _isEn
        ? 'Current stock: $current · Suggested: $suggested'
        : 'Stock actuel : $current · Suggéré : $suggested';
    return supplierName != null ? '$base · $supplierName' : base;
  }

  String tracabilityTitle(String lotLabel) =>
      _isEn ? 'Traceability — $lotLabel' : 'Traçabilité — $lotLabel';

  String lotTraceLabel(String productName, String lotNumber) => _isEn
      ? '$productName (lot $lotNumber)'
      : '$productName (lot $lotNumber)';

  String errorWith(Object error) =>
      _isEn ? 'Error: $error' : 'Erreur : $error';

  String invoiceTotal(String amount, String currency) =>
      _isEn ? 'TOTAL: $amount $currency' : 'TOTAL : $amount $currency';

  String invoiceNumberLabel(String invoiceNumber) =>
      _isEn ? 'Invoice $invoiceNumber' : 'Facture $invoiceNumber';

  String get pdfColumnProduct => _isEn ? 'Product' : 'Produit';
  String get pdfColumnQty => _isEn ? 'Qty' : 'Qté';
  String get pdfColumnUnitPrice => _isEn ? 'Unit price' : 'Prix unit.';
  String get pdfColumnSubtotal => _isEn ? 'Subtotal' : 'Sous-total';
}

class StringsDelegate extends LocalizationsDelegate<Strings> {
  const StringsDelegate();

  @override
  bool isSupported(Locale locale) => Strings.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );

  @override
  Future<Strings> load(Locale locale) async => Strings(locale);

  @override
  bool shouldReload(StringsDelegate old) => false;
}
