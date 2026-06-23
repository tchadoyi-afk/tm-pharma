# Cahier des Charges — TM Pharma · v1

> **TM Pharma** — Plateforme SaaS de gestion de pharmacies africaines.
> Éditeur : **T&M Logiciels** · Projet mené en association (PO + Claude).
> Pays pilotes : **🇹🇬 Togo · 🇬🇦 Gabon** — Espèces + Mobile Money (V2) · **FCFA**.
> Version : **v1 — cadrage consolidé** · 21/06/2026.
> Remplace le CDC v0 (« OfficineOS ») et intègre les décisions d'association. Le CDC v0 est conservé comme **archive historique**.

Un socle **offline-first, multi-tenant et auditable**, avec une **mini IA au cœur de l'app**, conçu pour la réalité des officines d'Afrique de l'Ouest et centrale.

---

## 01 · Contexte & problématiques
Les officines africaines opèrent dans un environnement contraint. Le MVP répond en priorité à la **survie opérationnelle et financière** de l'officine.

- ⚡ **Connexion instable** → la caisse fonctionne sans réseau et se synchronise au retour.
- 📦 **Ruptures de stock** → manque de visibilité temps réel sur quantités et lots.
- 🛡 **Faux médicaments** → besoin de traçabilité fine par lot et numéro de série.
- 📉 **Absence de KPI fiables** → le dirigeant manque d'indicateurs (CA, marge, pertes).

---

## 02 · Périmètre du MVP
MVP enrichi = **référence** du projet. Auto-réapprovisionnement et RH avancée décalés en V2.

| Module | Fonctionnalités clés (MVP) |
|---|---|
| **Caisse & Vente (POS)** | Encaissement tactile rapide, **offline-first** + synchro asynchrone, **scan code-barres** (caméra + douchette) avec recherche manuelle de secours, paiement **espèces**, clôture de caisse. |
| **Facturation & impression** | **Ticket thermique** (ESC/POS, hors-ligne) + **facture PDF** (A4/A5) **au logo de la pharmacie**, numérotation séquentielle infalsifiable. |
| **Gestion des stocks** | Entrées/sorties, alertes de rupture, traçabilité fine par lot, **capture GS1** (lot/péremption/GTIN). |
| **Cycle de vie & péremptions** | Alertes proactives (J-90/30/7), **FEFO**, dons, transferts inter-pharmacies, retours fournisseurs, **rebuts (workflow formalisé péremption→rebut)**, promotions. |
| **Gestion fournisseurs (complète)** | Carnet fournisseurs, seuils + suggestions IA → **bon de commande** (brouillon → envoyé → reçu), **portail fournisseurs** (échange structuré commandes/réceptions, suivi de statut côté fournisseur), retours fournisseurs. **Validation manuelle obligatoire avant tout envoi de commande — règle invariante à tous les paliers (MVP/V2/V3), aucune automatisation ne peut envoyer une commande sans confirmation humaine.** (auto-création de brouillon par seuil = V2, toujours soumise à cette validation). |
| **Reprise de données / onboarding** | Import **Excel/CSV**, catalogue de référence DCI, inventaire initial assisté, assistant guidé. |
| **Mini IA (cœur de l'app)** | Étage local hors-ligne (FEFO, ruptures, réappro, anti-fraude) + assistant langage naturel online. |
| **Habilitation fine** | RBAC granulaire (permissions atomiques) + validation hiérarchique. |
| **Administration & Audit** | Tableau de bord gérant (CA, marges), fournisseurs, **journal d'audit immuable**, **traçabilité soumise à habilitation**. |
| **Localisation** | Interface bilingue **Français / Anglais**, prête au déploiement régional. |

---

## 03 · Roadmap évolutive
- **V2 — Croissance & RH** : app mobile dirigeant, **paiements Mobile Money intégrés** (Togo + Gabon), pointage personnel (QR/NFC), planning/emploi du temps (licence séparée), **création automatique de brouillons de commande par seuil** + EDI/API fournisseur direct (validation manuelle toujours requise), IA prévisionnelle avancée, validation hiérarchique étendue, anti-fraude ML, **ventes en attente/reprise de vente**, **programme de fidélité client (points/paliers)**, **stats de performance par vendeur**, **multi-boutique/vue consolidée gérant** (à confirmer en pilote).
- **V3 — Écosystème B2B** : marketplace pharmaceutique, centrale d'achat, comparateur fournisseurs, téléconsultation, e-prescription, livraison, visiteurs médicaux, **IA visuelle anti-contrefaçon**, **vérification d'authenticité externe (réseau GS1 / base nationale)**, **gestion des salariés au sens large (RH/paie élargie, licence séparée)**, **devis** (vente B2B), **flux comptables**, **prêt client/crédit** (à valider en pilote), **rappel SMS renouvellement traitement chronique**.
- **V4 — Impact sectoriel** : e-learning & certifications du personnel officinal, bourse pharmaceutique continentale.

> ℹ️ Répartition issue de l'analyse concurrentielle du 22-23/06/2026 (comparaison PHARMAXIEL + logiciels US/Chine) — détail des décisions dans `PROGRAMME_DEVELOPPEMENT.md` §8.

---

## 04 · Architecture technique
SaaS multi-tenant, modulaire, taillé pour l'offline-first. **Décision : Supabase** (remplace NestJS/Redis/MinIO/VPS du v0) pour réutiliser l'expertise maison et accélérer.

- **Frontend** : **Flutter** — Web (back-office) + Mobile/Tablette (caisse & gérant). State management **Riverpod**.
- **Backend** : **Supabase** — Postgres multi-tenant (**RLS** par `tenant_id`), **Auth** (JWT/OAuth2 + **MFA**), **Storage** (S3-like : logo, ordonnances), **Realtime**, **Edge Functions** (jobs IA online, exports, futurs webhooks paiement).
- **Offline-first** : **PowerSync + Drift/SQLite** sur l'appareil ; synchronisation bidirectionnelle, **UUID v4** générés en local (zéro collision), résolution de conflits (LWW + règles métier).
- **IA** : moteur local sur device (offline) + **API Claude** (assistant & prévisions, online).
- **Sécurité** : RLS stricte, MFA, **journalisation immuable (chaînée par hash)**.

---

## 05 · Modèle de données (MVP)
Principes non négociables : **UUID v4**, `tenant_id` sur toutes les tables métier, **soft-delete + horodatage** partout.

- **Cœur** : `tenants`, `users`, `products`, `lots` (+ `gtin`, `serial`, `verification_status` pour V3), `sales`, `sale_items` (pointe `lot_id`).
- **Habilitation** : `roles`, `permissions`, `role_permissions`, `user_roles`.
- **Stock & cycle de vie** : `suppliers`, `purchase_orders`, `stock_movements`, `transfers`, `donations`, `supplier_returns`, `promotions`.
- **Caisse & facturation** : `cash_sessions`, `payments`, `invoices`, `invoice_lines`, `pharmacy_settings` (identité légale + **logo**).
- **Onboarding** : `import_jobs`, `import_rows` (+ catalogue de référence partagé).
- **Audit & IA** : `audit_log` (immuable, chaîné), `ai_alerts`, `ai_forecasts`, `sync_log`.

---

## 06 · Mini IA au cœur de l'app (2 étages)
- **Étage 1 — local / offline** (dès le MVP) : FEFO intelligent, prédiction de ruptures (moyenne mobile + saisonnalité), suggestions de réappro, anti-fraude caisse (heuristique).
- **Étage 2 — cloud / online** (dès le MVP) : **assistant en langage naturel** (questions CA/marge/péremptions, ancré sur les KPI, mis en cache), prévisions affinées. Modèle par défaut : **Claude Haiku 4.5**, bascule **Sonnet 4.6** pour l'analyse.
- **Règle** : rien de critique ne dépend du réseau ; l'étage 1 garantit la valeur hors-ligne.

---

## 07 · Habilitation fine (RBAC)
Au-delà des 3 rôles : **permissions atomiques** assemblées en rôles personnalisables par tenant (`pos.sell`, `pos.refund`, `stock.adjust`, `price.edit`, `report.financial.view`, `user.manage`, `ai.assistant.use`, etc.).
- **Validation hiérarchique** sur actions sensibles (remise > seuil, ajustement stock, prix).
- Câblé dès le MVP ; RLS aligne l'accès données sur les permissions.

---

## 08 · Traçabilité (transversale, soumise à habilitation)
« **Qui a fait quoi, sur quoi, et quand** » — deux couches dès le MVP :
- **Couche A — produit** : parcours complet de chaque lot (réception → mouvements → vente), **fiche de traçabilité du lot**.
- **Couche B — actions** : `audit_log` immuable **chaîné par hash**, horodatage **device + serveur**, valeurs avant/après.
- **Accès restreint** : permissions `trace.lot.view`, `audit.view.own`, `audit.view.all`, `trace.export`. **Tout le monde ne voit pas la traçabilité** (données sensibles : prix d'achat, marges, actions nominatives). La consultation de la trace est elle-même tracée.
- **Vérification d'authenticité externe (réseau GS1) = V3** (champs d'accroche posés au MVP).

---

## 09 · Facturation & impression (MVP)
- **Ticket thermique** Bluetooth/USB (ESC/POS), imprime **hors-ligne** ; **facture PDF** A4/A5 partageable (WhatsApp/email).
- **Logo de la pharmacie** sur facture (couleur) + ticket (monochrome auto) + en-tête app.
- **Numérotation séquentielle infalsifiable** par tenant.
- **Facture normalisée fiscale** (Togo : OTR ; Gabon : DGI/CEMAC) : modèle `invoices` conçu flexible pour absorber les mentions légales ; intégration officielle branchable sans refonte.

---

## 10 · Onboarding / reprise de données (MVP)
Facteur clé d'adoption : rendre une nouvelle pharmacie opérationnelle vite, sans saisie pénible.
- Import **Excel/CSV** (modèle fourni, prévisualisation, détection doublons/erreurs).
- **Catalogue de référence** pré-chargé (DCI + codes-barres) qui s'enrichit avec le réseau.
- **Inventaire initial assisté** (scan ou recherche, par lots avec péremption).
- **Assistant d'onboarding** guidé : infos pharmacie → logo → utilisateurs/rôles → stock → 1ʳᵉ vente test.

---

## 11 · KPIs & tableau de bord
Dashboard 3 niveaux (temps réel / pilotage / stratégique), exportable, filtré selon les permissions.
- **Financier** : CA (jour/sem/mois), panier moyen, nb tickets, **marge brute (€/%)**, top produits, écart de caisse.
- **Stock** : valeur, rotation, jours de couverture, ruptures/sous-seuil, taux de service.
- **Péremptions** : quantité/valeur périmés, capital à risque (<90j), pertes évitées (FEFO).
- **Anti-fraude/audit** : annulations, remises hors seuil, écarts caisse, actions loguées.
- **IA** : ruptures prévues vs constatées, réappro suggérés vs réalisés.

---

## 12 · Paiements (pays pilotes)
- **MVP** : **espèces** (FCFA). Mobile Money = **V2**.
- **V2** : intégration API Mobile Money — Togo (T-Money, Flooz) via PayGate/CinetPay/PayDunya/Hub2 ; Gabon (Airtel Money, Moov Money, zone CEMAC). Abstraction « PaymentProvider » multi-agrégateurs.

---

## 13 · Sécurité, audit & durcissement
**Zéro compromis. Le durcissement est un critère de sortie du MVP.**
- 🔐 **Isolation multi-tenant** : tests prouvant qu'aucune requête ne croise un autre `tenant_id` (RLS).
- 🔁 **Conflits de synchro** : offline→online concurrents, double-vente, horloge décalée.
- 📝 **Audit infalsifiable** : journal chaîné & signé, soft-delete vérifié, modifications rejetées.
- 🛡 **Pentest & abus** : OWASP Top 10, brute-force MFA, injection, escalade de privilèges par rôle.
- ✅ **Tests métier** : déduction de lot, marge, FEFO péremptions.
- 📡 **Résilience réseau** : coupures en pleine vente, file de sync persistante, reprise sans perte.

---

## 14 · Jalons du MVP (12 sprints)

| Sprint | Thème |
|---|---|
| **S1** | Socle technique & sécurité (Supabase, RLS, scaffold Flutter, CI/CD, audit chaîné, paramètres pharmacie + logo) |
| **S2** | Moteur de synchronisation offline (PowerSync + Drift) — 🚩 vente hors-ligne synchronisée sans perte |
| **S3** | Auth, RBAC fin & habilitations (MFA, validation hiérarchique) |
| **S4** | Catalogue & référentiel produits |
| **S5** | Stocks & lots + scan GS1 + **gestion fournisseurs complète** (carnet, bons de commande, **portail fournisseurs**) |
| **S6** | Reprise de données / onboarding |
| **S7** | POS offline-first (caisse, scan, espèces) |
| **S8** | Facturation & impression — 🚩 **JALON PILOTE** (encaisse + imprime, hors-ligne) |
| **S9** | Cycle de vie & péremptions (FEFO, alertes proactives, dons, transferts, retours fournisseurs, **rebuts**, promos) |
| **S10** | Mini IA locale + réappro assisté |
| **S11** | Dashboard, KPIs, assistant IA & traçabilité consultable |
| **S12** | Durcissement, pentest & pilote terrain (2–3 officines Togo & Gabon) — 🏁 **MVP livré** |

---

## 15 · Critères de succès du MVP
- **100 %** des ventes encaissées hors-ligne, **sans perte** après synchro.
- **0** fuite inter-tenant tolérée aux tests de durcissement.
- **2–3** officines pilotes actives en Togo & Gabon.

---

*TM Pharma — Cahier des charges v1 · Édition T&M Logiciels · Consolidé et mis à jour le 21/06/2026. Document vivant : voir `PROGRAMME_DEVELOPPEMENT.md` pour le plan d'exécution détaillé.*
