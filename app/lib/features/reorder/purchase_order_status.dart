/// États possibles d'un bon de commande fournisseur.
const purchaseOrderStatuses = [
  'DRAFT',
  'SENT',
  'CONFIRMED',
  'PARTIALLY_RECEIVED',
  'RECEIVED',
  'CANCELLED',
];

/// États terminaux : aucune transition n'en part.
const _terminalStatuses = {'RECEIVED', 'CANCELLED'};

/// Transitions valides depuis chaque statut. L'envoi (DRAFT→SENT) n'est
/// jamais déclenché automatiquement : seule l'action humaine explicite
/// « Valider et envoyer » l'appelle (règle invariante, voir CDC).
const _allowedTransitions = <String, List<String>>{
  'DRAFT': ['SENT', 'CANCELLED'],
  'SENT': ['CONFIRMED', 'CANCELLED'],
  'CONFIRMED': ['PARTIALLY_RECEIVED', 'RECEIVED'],
  'PARTIALLY_RECEIVED': ['RECEIVED'],
  'RECEIVED': [],
  'CANCELLED': [],
};

/// Statuts atteignables depuis [status]. Liste vide si [status] est
/// terminal (ou inconnu).
List<String> allowedNextStatuses(String status) =>
    _allowedTransitions[status] ?? const [];

/// Vrai si la transition [from] → [to] est autorisée.
bool canTransition(String from, String to) =>
    allowedNextStatuses(from).contains(to);

/// Vrai si [status] est un état terminal (plus aucune transition possible).
bool isTerminalStatus(String status) => _terminalStatuses.contains(status);
