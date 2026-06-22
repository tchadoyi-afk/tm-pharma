# TM Pharma — Document commercial

> Document vivant : à enrichir à chaque nouvelle fonctionnalité livrée (ajouter une ligne dans la section concernée, ou un nouvel argument). Rédigé pour être réutilisé tel quel dans une plaquette, un pitch oral, une réponse à appel d'offres ou un argumentaire commercial face à un pharmacien/dirigeant de groupe.

## 1. Pitch en une phrase

**TM Pharma est le logiciel de gestion de pharmacie pensé pour l'Afrique : il fonctionne sans connexion internet stable, protège chaque centime et chaque boîte de médicament, et s'adapte à la taille de l'officine — du comptoir unique au groupe multi-pharmacies.**

## 2. Les problèmes qu'on résout (et qu'on connaît par cœur)

| Problème terrain | Réponse TM Pharma |
|---|---|
| Internet coupe en pleine vente | **Offline-first** : la caisse, le stock, les lots fonctionnent sans réseau ; la synchronisation reprend automatiquement dès que la connexion revient, sans perte de données. |
| Ruptures de stock découvertes trop tard | Suivi de stock par lot en temps réel + **suggestions de réapprovisionnement intelligentes**. |
| Pertes sur médicaments périmés | Alertes de péremption à J-90/J-30/J-7 + traçabilité FEFO (premier expiré, premier sorti) appliquée automatiquement à la vente. |
| Vols/fraudes en caisse difficiles à détecter | Journal d'audit **infalsifiable** (chaînage par hash) + détection de signaux suspects à la clôture de caisse (remises répétées, ventes hors horaires, montants anormaux). |
| Personnel non formé, turnover élevé | Interface **simple et rapide** : vendre en moins de 3 appuis, gros boutons, utilisable sur tablette d'entrée de gamme. |
| Aucune visibilité pour le dirigeant | Tableau de bord avec KPIs (chiffre du jour, valeur du stock, ruptures, péremptions à venir) accessible selon le rôle. |
| Pas de traçabilité en cas de contrôle | Fiche de traçabilité par lot (réception → vente) + export d'audit, conforme à l'exigence « qui a fait quoi, quand ». |
| Reprise de données d'un ancien système = cauchemar | Assistant d'onboarding : import CSV/Excel du catalogue existant, inventaire initial guidé. |
| Plusieurs pharmacies, plusieurs fournisseurs, gestion éclatée | Carnet de fournisseurs centralisé, fournisseur par défaut par produit, un bon de commande généré par fournisseur. |

## 3. Fonctionnalités — argumentaire détaillé

### 3.1 Vente & caisse
- **Scan code-barres** (caméra du téléphone/tablette OU douchette physique) — pas besoin de matériel spécifique pour démarrer.
- **Vente en 3 appuis maximum** — pensé pour un personnel non technicien, formation en quelques minutes.
- **Allocation FEFO automatique** — le système prélève toujours le lot qui périme le plus tôt, sans intervention manuelle, même quand la quantité vendue est répartie sur plusieurs lots.
- **Tickets thermiques + factures PDF** à l'impression, avec logo et identité de la pharmacie.
- **Application des promotions actives** automatiquement au moment de la vente (pas de remise oubliée ou mal appliquée).
- **Clôture de caisse fiable** : le total est calculé à partir des ventes réelles, jamais saisi à la main — impossible de « truquer » une clôture.

### 3.2 Stock & traçabilité
- **Gestion par lot** avec numéro de lot et date de péremption (norme GS1).
- **Alertes de péremption graduées** (90/30/7 jours) pour agir avant la perte sèche.
- **Sorties hors-vente traçées** : don, retour fournisseur, transfert — chaque mouvement journalisé.
- **Fiche de traçabilité complète par lot** : de la réception jusqu'à chaque vente, consultable en quelques secondes (utile en cas de rappel de lot ou de contrôle réglementaire).
- **Catalogue produit avec référentiel DCI pré-chargé** : ajout rapide d'un produit existant, ou création libre si nécessaire.

### 3.3 Réapprovisionnement intelligent
- **Suggestions de commande automatiques**, basées sur :
  - le **seuil bas** défini par produit,
  - la **vélocité de vente réelle** (moyenne des 30 derniers jours), pour ne pas se fier à un seuil statique arbitraire,
  - le **délai de livraison du fournisseur**, pour déclencher la commande au bon moment et non quand il est déjà trop tard.
- **Fournisseur par défaut par produit** : la suggestion arrive déjà pré-remplie avec le bon interlocuteur.
- **Un bon de commande généré automatiquement par fournisseur** quand plusieurs fournisseurs sont concernés — pas de tri manuel à refaire.
- Approche alignée sur les pratiques des logiciels d'officine de référence du marché (vélocité × délai + marge de sécurité), tout en restant utilisable sans aucun historique de ventes (repli automatique sur une règle simple).

### 3.4 Pilotage & visibilité (tableau de bord)
- KPIs en un coup d'œil : ventes du jour, valeur du stock, produits en rupture, péremptions à venir.
- Vue adaptée au rôle : direction (indicateurs financiers), pharmacien responsable (stock), caissier (ses propres ventes).

### 3.5 Sécurité, conformité & confiance
- **Journal d'audit chaîné par hash** : toute action clé (vente, réception, ajustement, clôture de caisse) est horodatée et infalsifiable — preuve en cas de litige ou de contrôle.
- **Habilitations fines (RBAC)** : chaque utilisateur ne voit et ne fait que ce qui correspond à son rôle (caissier, pharmacien, dirigeant…), jusqu'au niveau de la permission individuelle.
- **Validation hiérarchique** automatique au-delà de certains seuils (remise, ajustement de stock, remboursement) — pas de dérive possible sans accord d'un responsable.
- **Multi-tenant sécurisé** : chaque pharmacie ne voit que ses propres données, même hébergées sur la même infrastructure (isolation au niveau base de données, pas seulement applicatif).
- **Détection de signaux de fraude** à la clôture de caisse (remises suspectes, horaires anormaux, montants hors norme) — alerte avant validation, pas après le constat de la perte.

### 3.6 Mise en route & reprise de données
- **Import du catalogue existant** depuis un fichier Excel/CSV.
- **Inventaire de démarrage guidé**, étape par étape.
- **Identité visuelle de la pharmacie** (logo) reprise automatiquement sur l'application, les tickets et les factures.

### 3.7 Multi-pharmacies / groupe
- **Carnet de fournisseurs partagé par tenant**, avec délai de livraison habituel par fournisseur.
- Architecture pensée pour gérer **plusieurs officines sous une même structure**, chacune avec ses propres droits et son propre stock, tout en gardant une cohérence de gestion.

## 4. Différenciateurs face à la concurrence

1. **Offline-first natif**, pas un correctif ajouté après coup : pensé dès le départ pour les coupures réseau fréquentes en Afrique de l'Ouest/Centrale.
2. **Traçabilité et anti-fraude intégrées au cœur du produit**, pas en option payante séparée.
3. **Réapprovisionnement qui s'améliore avec l'usage** (vélocité de vente réelle) sans jamais bloquer une pharmacie qui démarre sans historique.
4. **Modèle de licence par palier clair** : le tronc commun (gestion d'officine) est complet dès le MVP ; les modules avancés (planning du personnel, RH/paie élargie) s'ajoutent sans surcharger ni complexifier l'usage quotidien des pharmacies qui n'en ont pas besoin.
5. **Conçu pour un personnel non technicien** : adoption rapide, peu de formation, moins de résistance au changement.

## 5. Modèle de licence (paliers)

- **MVP** — gestion d'officine de base : vente/caisse, stock & lots, traçabilité, réapprovisionnement intelligent, facturation, tableau de bord, audit, fournisseurs. *(inclus dès le départ, aucun module additionnel à activer)*
- **V2** — module additionnel sous licence séparée : **emploi du temps / planning du personnel**.
- **V3** — module additionnel sous licence séparée : **gestion des salariés au sens large (RH/paie élargie)**.

> Argument commercial : on ne paie que ce dont on a besoin. Une petite officine reste sur le MVP indéfiniment si elle le souhaite ; un groupe qui grandit active les modules avancés sans changer de logiciel ni migrer ses données.

## 6. Objections fréquentes — réponses prêtes à l'emploi

- *« On n'a pas toujours internet. »* → C'est exactement pour ça que TM Pharma est conçu offline-first : la caisse et le stock fonctionnent sans réseau, la synchro se fait seule au retour de la connexion.
- *« Notre personnel n'est pas à l'aise avec l'informatique. »* → Interface simple, vente en 3 appuis, utilisable sur une tablette bas de gamme ; formation de quelques minutes.
- *« On a déjà un catalogue/stock dans un autre outil. »* → Import CSV/Excel + inventaire de démarrage guidé : la reprise de données est prévue dès la mise en route.
- *« Comment être sûr qu'il n'y a pas de vol en caisse ? »* → Journal d'audit infalsifiable + détection automatique de signaux de fraude à la clôture.
- *« On grandit, on aura besoin de plus que la simple gestion d'officine. »* → Modèle par paliers : planning du personnel (V2) puis RH/paie élargie (V3), activables sans changer de système.

## 7. Roadmap visible client (sans s'engager sur des dates fermes)

- **V2 prévu** : Mobile Money, comparateur multi-fournisseurs (prix/délai) pour le réapprovisionnement, envoi de commande direct au fournisseur (EDI/API), module planning du personnel.
- **V3 prévu** : vérification d'authenticité externe des médicaments (réseau GS1/base nationale), module RH/paie élargi.

---

*Dernière mise à jour : 2026-06-22 — suite à l'ajout du réapprovisionnement affiné (vélocité de vente, délai fournisseur, fournisseur par défaut, bons de commande par fournisseur).*
