# Programme de Développement — TM Pharma

> SaaS B2B multi-tenant, **offline-first**, de gestion de pharmacies pour l'Afrique.
> Document maître du projet. Mis à jour à chaque session.
> Dernière mise à jour : **2026-06-21** — Auteur : binôme PO (Toi) + Claude (associé/dev).
>
> ℹ️ Ce dossier est la copie de référence sur disque interne (`C:\Claude\TM_Projects\TM_Pharma`). Une copie existe aussi sur disque amovible (`E:`), non garantie connectée — **travailler ici sur `C:`**.

---

## 0. Décisions structurantes (actées le 2026-06-21)

| Sujet | Décision | Raison |
|---|---|---|
| **Architecture backend** | **Supabase** (Postgres + RLS multi-tenant + Auth + Storage + Realtime) + offline-first côté **Flutter** | Réutilise l'expertise maison (T&M Business, TM Médical), MVP plus rapide et moins cher, RLS déjà maîtrisé. Remplace NestJS/Redis/MinIO du CDC v3. |
| **Marché cible MVP** | **Togo + Gabon** | Terrains déjà connus du groupe ; oblige à généraliser réglementation + Mobile Money tôt (sain). |
| **Mini IA au lancement** | **Assistant conversationnel + alertes proactives** dès le MVP | L'IA est centrale, pas un gadget. Moteur local hors-ligne + assistant LLM online. |
| **Équipe** | **Binôme : Toi (PO/décision) + Claude (conception/dev)** | Sprints calibrés pour ce rythme. |
| **Langues** | FR (défaut) + EN | Déploiement régional, marchés anglophones en V3. |
| **Sync offline** | **PowerSync** sur Supabase + **Drift** (SQLite typé) côté Flutter | Sync engine éprouvé pour Supabase, résolution de conflits LWW personnalisable. À valider en PoC Sprint 0. |
| **Nom du produit** | **TM Pharma** | Décision binôme 21/06 (abandon de « OfficineOS » utilisé dans le CDC v0). |
| **Plan MVP** | **12 sprints (S1→S12)**, MVP enrichi = référence ; jalon Pilote à **S8** | Décision binôme 21/06 : qualité + durcissement même en binôme. |
| **MVP — ajouts validés** | Scan **GS1 capture** dès le MVP · **impression factures/tickets** dès le MVP · **traçabilité transversale soumise à habilitation** · **onboarding/reprise de données** · **logo pharmacie** | Différenciateurs + adoption terrain. |

> ⚠️ La décision Supabase **diverge volontairement** du CDC v3 (qui imposait NestJS/VPS). Tout le reste du CDC (Flutter, Postgres, UUID, RLS, soft-delete, audit, offline-first) est conservé.

> **Stratégie d'hébergement à coût minimal (décision 2026-06-22, révisée le même jour après recherche)** — contexte : marché cible (petites officines africaines) très sensible au coût récurrent en devise forte ; **PowerSync managé** (~250-300 $/mois) est identifié comme la ligne de coût la plus lourde du stack, disproportionnée pour un pilote à 1-5 pharmacies.
> - **Révision importante** : PowerSync existe en édition **« Open Edition »**, self-hébergeable gratuitement (image Docker `journeyapps/powersync-service`), sous licence FSL qui se convertit en **Apache 2.0** deux ans après publication — publiée en mai 2024, donc déjà pleinement permissive à ce jour. **Décision : pas de synchro maison à coder** — on garde PowerSync (même SDK client, aucun changement dans `app/lib/core/sync/`), seul le **service serveur** change d'hébergeur.
> - **Phase pilote/développement** : self-hébergement sur un VPS mutualisé bas coût (~10-25 $/mois selon dimensionnement) : Postgres+Auth (briques open-source Supabase) + service PowerSync Open Edition (stockage des buckets de sync sur Postgres, pas MongoDB, pour rester sur une seule techno). Aucun investissement matériel pharmacie requis à ce stade.
> - **Avant la mise en production réelle** : bascule possible vers **Supabase Cloud managé** (~25 $/mois) — migration facile/réversible (même schéma, juste changement d'URL/clé de connexion) — et/ou vers **PowerSync Cloud managé** si on préfère la tranquillité opérationnelle à ce stade. Les deux bascules sont indépendantes : on peut très bien rester sur PowerSync self-hébergé même en prod si l'économie reste prioritaire.
> - Piste V2/V3 si le volume de pharmacies grandit fortement : boîtier local par pharmacie (Raspberry Pi/mini-PC, ~60-90 $ une fois) avec base locale + synchro différée vers le cloud central — argument commercial fort (« fonctionne même 1 semaine sans internet ») mais plus de travail de dev (sync différée) et de logistique (provisioning matériel). Non retenu pour le pilote initial, à réévaluer après les premiers retours terrain.
> - Conséquence code : **aucune réécriture du moteur de synchro**. Le chantier devient une tâche d'infra (déployer/configurer le service PowerSync Open Edition + Postgres sur le VPS), pas un chantier de code applicatif.

---

## 1. Vision & objectifs

**Vision.** Devenir la plateforme de référence pour la gestion des pharmacies en Afrique.
**Objectif long terme (CDC).** 10 000 pharmacies connectées, marketplace + centrale d'achat continentale.

**4 douleurs terrain ciblées :**
1. Connexion internet instable → **offline-first absolu** sur la caisse.
2. Ruptures de stock → **prédiction de ruptures + réappro intelligent**.
3. Faux médicaments → **traçabilité par lot + scan GS1 DataMatrix**.
4. Absence de KPI fiables → **tableau de bord + KPIs précis + audit infalsifiable**.

---

## 2. Architecture cible

```
┌─────────────────────────── DEVICES (Flutter) ───────────────────────────┐
│  Tablette Caisse (POS)      Mobile Dirigeant       Web Back-office       │
│  - Drift / SQLite local     - lecture KPI          - admin, catalogue    │
│  - file de sync             - assistant IA          - habilitations       │
│  - moteur IA LOCAL (offline)                        - rapports/audit     │
└───────────────┬──────────────────────────────────────────────────────────┘
                │  PowerSync (sync bidirectionnel, LWW + règles)
                │  + appels API online (assistant IA, prévisions)
┌───────────────▼──────────────────────────────────────────────────────────┐
│                              SUPABASE                                       │
│  Postgres (multi-tenant, RLS par tenant_id)   Auth (JWT/OAuth2 + MFA)      │
│  Storage (S3-like : ordonnances, photos)      Realtime (alertes live)     │
│  Edge Functions (jobs IA online, webhooks Mobile Money, exports)          │
└───────────────┬──────────────────────────────────────────────────────────┘
                │
        ┌───────▼────────┐      ┌──────────────────────┐
        │  API Claude    │      │  Agrégateur Mobile    │
        │  (assistant NL,│      │  Money (Hub2/CinetPay │
        │  prévisions)   │      │  /PayGate/PayDunya)   │
        └────────────────┘      └──────────────────────┘
```

**Principes (conservés du modèle de données CDC) :**
- **UUID v4** partout (génération locale hors-ligne sans collision).
- `tenant_id` sur **toutes** les tables métier + **RLS** stricte (1 pharmacie ne voit jamais une autre).
- `created_at` / `updated_at` / `deleted_at` (**soft-delete**) partout → audit & conformité.
- Stock **calculé via les lots** (jamais un compteur global).
- **Journal d'audit immuable** sur chaque mutation.

---

## 3. La mini IA au cœur de l'app (2 étages)

### Étage 1 — Moteur LOCAL (offline, sur le device) — *dès le MVP*
Déterministe + statistiques légères, tourne sur la tablette **sans réseau** :
- **FEFO intelligent** : priorise la sortie des lots qui périment en premier ; alerte péremptions à J-90/J-30/J-7.
- **Prédiction de ruptures** : moyenne mobile + saisonnalité (jour de semaine, fin de mois, saisons palu/grippe) → « ce produit sera en rupture dans ~5 jours ».
- **Suggestion de réappro** : quantité conseillée par produit/fournisseur (point de commande + délai fournisseur).
- **Anti-fraude caisse (heuristique)** : anomalies sur annulations, remises manuelles excessives, écarts de caisse, ventes hors horaires.

### Étage 2 — Assistant & prévisions CLOUD (online, via API Claude) — *dès le MVP*
- **Assistant en langage naturel** pour le dirigeant : « Quel est mon CA cette semaine ? », « Quels produits vont périmer en mars ? », « Pourquoi ma marge a baissé ? ». Réponses ancrées sur les données (function-calling sur les KPI), résultats **mis en cache**, dégradation gracieuse hors-ligne.
- **Prévisions de ventes** affinées au niveau flotte (V2+ : modèles plus avancés type gradient boosting).
- **Scoring anti-fraude** plus fin et détection de contrefaçon (V2/V3).

> **Règle de coût/connectivité :** rien de critique ne dépend du cloud. L'étage 1 garantit la valeur même sans réseau ; l'étage 2 enrichit quand on est en ligne. Appels LLM mis en cache et budgétés.

Modèle Claude par défaut pour l'assistant : **Claude Haiku 4.5** (coût/latence) avec bascule **Sonnet 4.6** pour les analyses complexes.

---

## 4. Habilitation fine (RBAC granulaire)

On dépasse les 3 rôles du CDC (`ADMIN`, `PHARMACIST`, `CASHIER`) → **permissions atomiques** assignables, rôles = ensembles de permissions personnalisables par tenant.

**Exemples de permissions :** `pos.sell`, `pos.refund`, `pos.discount.apply`, `pos.cash.close`, `stock.view`, `stock.adjust`, `stock.transfer`, `price.edit`, `product.create`, `supplier.manage`, `report.financial.view`, `user.manage`, `ai.assistant.use`.

**Permissions de traçabilité (accès restreint) :** `trace.lot.view` (fiche de traçabilité d'un lot), `audit.view.own` (voir uniquement ses propres actions), `audit.view.all` (voir le journal complet de la pharmacie), `trace.export` (exporter pour inspection/rappel de lot). Par défaut : Dirigeant/ADMIN = tout ; Pharmacien responsable = `trace.lot.view` + `audit.view.all` ; Caissier = `audit.view.own` au plus. **Aucun accès traçabilité sans permission explicite.**

- **Validation hiérarchique** : certaines actions (remise > seuil, ajustement de stock, prix) exigent l'approbation d'un supérieur → tout est tracé.
- **Câblé dès le MVP** : ajouter une habilitation fine après coup est très coûteux.
- Chaque action sensible → entrée dans le **journal d'audit** (qui, quoi, quand, avant/après).

Tables : `roles`, `permissions`, `role_permissions`, `user_roles` (+ `tenant_id`, soft-delete). RLS aligne l'accès données sur les permissions.

---

## 4-bis. Traçabilité de bout en bout (transversale — MVP)

**Exigence : tout est traçable — « qui a fait quoi, sur quoi, et quand ».** Deux couches complémentaires, câblées dès le MVP.

### Couche A — Traçabilité produit (chaîne du médicament)
Reconstituer le parcours complet de **chaque lot**, de la réception à la délivrance (rappel de lot, suspicion de contrefaçon, inspection).
- **Entrée** : réception fournisseur horodatée (qui réceptionne, quel fournisseur, n° lot, **GTIN/GS1**, péremption, quantité, prix d'achat).
- **Mouvements** : ajustements, transferts inter-pharmacies, dons, retours fournisseur — chacun daté et attribué à un utilisateur.
- **Sortie** : la vente pointe le `lot_id` précis (déjà au modèle) → on sait quel lot exact est parti, sur quelle vente, par quel caissier.
- **Restitution** : « fiche de traçabilité d'un lot » = d'où il vient + où il est allé, en un écran.

### Couche B — Traçabilité des actions (audit infalsifiable)
`audit_log` **immuable** sur chaque mutation sensible :
- **QUI** = `user_id` authentifié (aucune action anonyme).
- **QUOI** = nature de l'action + valeurs **avant / après**.
- **QUAND** = horodatage **device + serveur** (clé en offline-first).
- **SUR QUOI** = entité concernée (lot, produit, vente, prix…).
- **Infalsifiable** : journal chaîné par hash (chaque entrée scelle la précédente) → toute altération détectable. Jamais de suppression physique (soft-delete partout).

### Accès à la traçabilité (soumis à habilitation)
**Tout le monde ne peut PAS voir la traçabilité** — elle contient des données sensibles (prix d'achat, marges, actions nominatives des employés).
- Gouvernée par les permissions `trace.*` / `audit.*` (cf. §4).
- Filtrage RLS : un caissier ne voit au mieux que ses propres actions (`audit.view.own`) ; la vue complète et les exports sont réservés au dirigeant / pharmacien responsable.
- Toute consultation de la traçabilité est elle-même journalisée (on trace qui consulte la trace).

### Vérification d'authenticité externe → V3
La capture GS1 (provenance interne) est au MVP ; l'**interrogation d'une base nationale / réseau GS1** pour vérifier l'authenticité d'une boîte est reportée en **V3**. On pose dès le MVP les 2-3 champs d'accroche dans le modèle (`gtin`, `serial`, `verification_status`) pour brancher V3 **sans refonte**.

### Qui fait quoi, et quand (par sprint)

| Brique de traçabilité | Ce qu'elle trace | Sprint |
|---|---|---|
| `audit_log` chaîné + `created_by`/`updated_by` + horodatage device/serveur | Socle « qui/quoi/quand » | **S0** (socle) |
| Identité forte : chaque action liée à un user, audit des droits | QUI (attribution) | **S1** |
| Réception fournisseur + lots + capture **GS1** + `stock_movements` | Entrée produit + provenance | **S2** |
| Vente → `lot_id`, audit caisse (ventes, annulations, remises) | Sortie produit + qui a vendu | **S3** |
| Dons, transferts, retours fournisseur tracés | Cycle de vie du lot | **S4** |
| Fiche traçabilité lot + journal d'audit consultable (sous habilitation) + exports | Restitution / inspection | **S6** |

> Conséquence : la traçabilité n'est pas un module isolé, c'est une **colonne vertébrale** construite à chaque sprint et consultable (selon droits) en fin de MVP.

---

## 5. Tableau de bord & KPIs précis

### Dashboard dirigeant (mobile + web)
3 niveaux : **temps réel** (caisse du jour) · **pilotage** (semaine/mois) · **stratégique** (tendances, prévisions IA).

### Catalogue KPI (MVP)
**Financier**
- CA (jour / semaine / mois / cumul), panier moyen, nombre de tickets.
- **Marge brute** (montant + %), top produits par marge / par volume.
- Encaissements par moyen de paiement (espèces / Mobile Money).
- Écart de caisse (théorique vs réel).

**Stock**
- Valeur du stock (coût + prix de vente), taux de rotation, jours de couverture.
- Nb de produits **en rupture** / **sous le seuil**, taux de service (demandes servies).
- **Capital immobilisé en périmés** + valeur à risque (péremption < 90 j).

**Péremptions / pertes**
- Quantité & valeur des produits périmés (mois), évités grâce au FEFO, dons/transferts.

**Anti-fraude / audit**
- Nb d'annulations, remises hors seuil, écarts caisse, actions sensibles loguées.

**IA / opérationnel**
- Ruptures **prévues** vs constatées (précision du modèle), réappro suggérés vs réalisés.

> Chaque KPI : défini précisément (formule + période + filtre par pharmacie/employé), exportable (CSV/PDF), et accessible selon les permissions.

---

## 6. Modèle de données (extension du MVP CDC)

**Du CDC, conservées :** `tenants`, `users`, `products`, `lots`, `sales`, `sale_items` (UUID, `tenant_id`, soft-delete).

**À ajouter pour couvrir le périmètre :**
- RBAC : `roles`, `permissions`, `role_permissions`, `user_roles`.
- Stock/cycle de vie : `suppliers`, `purchase_orders`, `stock_movements` (entrées/sorties/ajustements), `transfers` (inter-pharmacies), `donations`, `supplier_returns`, `promotions`.
- Caisse : `cash_sessions` (ouverture/clôture), `payments` (multi-moyens), `payment_mobile_money` (réf. transaction agrégateur).
- **Facturation : `invoices` (numérotation séquentielle par tenant, type ticket/facture), `invoice_lines`, `pharmacy_settings` (identité : raison sociale, n° fiscal/RCCM, adresse, contacts, **logo**, mentions légales).**
- **Onboarding/reprise : `import_jobs`, `import_rows` (imports Excel/CSV rejouables, traçables) ; catalogue de référence partagé (médicaments DCI + codes-barres).**
- Traçabilité produit : champs **GS1** sur `lots` (`gtin`, `serial`, DataMatrix, `verification_status` pour V3) pour l'anti-contrefaçon.
- Audit & IA : `audit_log` (immuable, chaîné par hash), `ai_alerts`, `ai_forecasts`, `sync_log`.

---

## 7. Spécificités contexte africain (intégrées au design)

- **Réseau 2G/3G / Android Go** : offline-first, payloads légers, images compressées, sync incrémentale, UI tolérante à la latence. (cf. contraintes déjà vécues sur TM Médical).
- **Paiements Mobile Money** (V2, à préparer côté modèle dès le MVP) :
  - *Togo* : T-Money + Flooz (Moov) via agrégateurs **PayGate**, **CinetPay**, **PayDunya**, **Hub2** (multi-UEMOA, intègre Gozem Money).
  - *Gabon* : Airtel Money + Moov Money (zone CEMAC, GIMACPAY) ; agrégateurs type **e-Billing**.
  - → Abstraction « PaymentProvider » pour brancher l'agrégateur le moins cher par pays.
- **Anti-contrefaçon** : scan **GS1 DataMatrix** (GTIN + lot + péremption + n° série) — **capture intégrée au MVP** (saisie rapide + traçabilité) ; vérification réseau d'authenticité reportée en V3.
- **Facturation & impression (MVP)** : ticket de caisse **thermique** (imprimante Bluetooth/USB ESC/POS, fonctionne **hors-ligne**) + **facture PDF** (A4/A5) imprimable/partageable. Numérotation séquentielle infalsifiable par tenant.
- **Facture normalisée / fiscale** : à VÉRIFIER par pays (Togo : facture normalisée OTR ; Gabon : exigences DGI/CEMAC). On conçoit `invoices` assez flexible pour absorber les mentions légales dès le MVP ; l'intégration fiscale officielle pourra être branchée ensuite sans refonte.
- **Réglementation pharma** : homologation produits (UEMOA règl. 04/2020), à approfondir par pays avant V3 (e-prescription/téléconsultation).

---

## 7-bis. Expérience & opérations quotidiennes (MVP)

> Principe directeur : **simple et intuitif avant tout**. Cible = caissier peu formé, tablette Android bas de gamme, écran tactile, ambiance pressée. Gros boutons, moins de 3 taps pour vendre, recherche instantanée, messages clairs en FR/EN, mode sombre/clair, fonctionne hors-ligne sans jamais bloquer.

### Scan code-barres à la caisse
- **Encaissement** : bip d'un produit → ajout immédiat au panier. Support **caméra** (tablette) **et** **douchette USB/Bluetooth** (plus rapide en flux).
- **Formats** : EAN-13 / Code-128 (le plus courant) + **GS1 DataMatrix** (capture lot + péremption en bonus).
- **Réalité terrain** : beaucoup de boîtes sans code lisible → **recherche manuelle rapide** (par nom/DCI, début de frappe) toujours disponible en secours, et possibilité d'**associer un code-barres à un produit** au vol.
- Lien traçabilité : si DataMatrix scanné, la vente connaît le lot exact ; sinon FEFO choisit le lot automatiquement.

### Réapprovisionnement (MVP = assisté ; V2 = automatique)
- **MVP** : point de commande par produit (seuil + délai fournisseur) → l'IA locale **suggère** quoi recommander et combien → le gérant génère un **bon de commande** (brouillon → envoyé → reçu).
- **Réception** = entrée en stock tracée (alimente la traçabilité couche A).
- **MVP** (révisé 23/06/2026, gestion fournisseurs complète) : **portail fournisseurs** (échange de commandes/bons de réception, suivi de statut côté fournisseur) inclus dès le MVP, pas seulement le bon de commande brouillon→envoyé→reçu.
- **V2** : génération **automatique** des commandes (sans validation manuelle) + envoi direct intégré (EDI/API fournisseur).

### Reprise de données / onboarding d'une nouvelle pharmacie
Brique de premier plan (adoption). Une nouvelle pharmacie doit être opérationnelle **vite et sans saisie pénible** :
- **Import Excel/CSV** via modèle fourni (produits, prix, stock initial, fournisseurs) avec **prévisualisation + détection d'erreurs/doublons**.
- **Catalogue de référence pré-chargé** (médicaments courants en DCI + codes-barres connus) → on coche/ajuste au lieu de tout saisir.
- **Inventaire initial assisté** : saisie par scan ou recherche, par lots avec péremption.
- **Assistant d'onboarding** guidé (pas-à-pas) : infos pharmacie → logo → utilisateurs/rôles → stock → 1ʳᵉ vente test.
- Tables : `import_jobs`, `import_rows` (traçabilité des imports, rejouables).

### Logo & identité de la pharmacie
- Écran **paramètres pharmacie** : upload/changement du **logo** (stocké dans Supabase Storage), raison sociale, n° fiscal/RCCM, adresse, contacts, mentions légales.
- Le logo apparaît sur : **facture PDF** (couleur), **ticket thermique** (version monochrome/basse résolution générée automatiquement), et **en-tête de l'app**.
- Multi-pharmacies : chaque tenant a son propre logo/identité.

---

## 8. Roadmap par phases & sprints

> **MVP livré sur 12 sprints (S1→S12)** — décision binôme 21/06/2026 : on garde **tout le périmètre MVP enrichi comme référence** (RBAC fin, IA, facturation, traçabilité, onboarding, logo), étalé sur 12 sprints courts (~1–2 semaines effectives) pour sécuriser la qualité et le durcissement. Mobile Money = V2.

### PHASE 1 — MVP « TM Pharma » (Sprints 1→12)

| Sprint | Contenu | Livrable / jalon |
|---|---|---|
| **S1** | Socle technique & sécurité : projet Supabase, schéma multi-tenant + **RLS**, scaffold Flutter (Riverpod, routing, i18n FR/EN, thème), CI/CD, **audit_log chaîné** de base, **paramètres pharmacie (identité + logo)**. | Socle déployable, multi-tenant isolé |
| **S2** | **Moteur de synchronisation offline** : PoC puis implémentation **PowerSync + Drift/SQLite**, file de sync persistante, résolution de conflits (LWW + règles), tests scénarios hors-ligne. | 🚩 Une vente créée hors-ligne se synchronise sans perte (risque n°1 levé) |
| **S3** | **Auth, RBAC fin & habilitations** : login + **MFA**, permissions atomiques, rôles personnalisables par tenant, validation hiérarchique, audit des droits. | Habilitation fine opérationnelle |
| **S4** | **Catalogue & référentiel produits** : produits, codes-barres, **catalogue de référence DCI**, prix. | Catalogue prêt |
| **S5** | **Stocks & lots + scan GS1** : lots, mouvements, fournisseurs, seuils, réception, **capture GS1** (lot/péremption/GTIN). | Stock par lots tracé dès l'entrée |
| **S6** | **Reprise de données / onboarding** : import **Excel/CSV** (prévisu + doublons), inventaire initial assisté, **assistant d'onboarding** guidé. | Une pharmacie peut être onboardée rapidement |
| **S7** | **POS offline-first (caisse)** : encaissement tactile, panier, **scan code-barres caisse** + recherche manuelle, paiement **espèces**, clôture de caisse. | Caisse fonctionnelle hors-ligne |
| **S8** | **Facturation & impression** : `invoices` (numérotation séquentielle), **ticket thermique ESC/POS**, **facture PDF avec logo**. | 🚩 **JALON PILOTE** : pharmacie onboardée qui encaisse en scannant et imprime ses tickets/factures, hors-ligne |
| **S9** | **Cycle de vie & péremptions** : **FEFO**, alertes J-90/J-30/J-7, dons, transferts inter-pharmacies, retours fournisseurs, **rebuts (workflow formalisé)**, promotions. | Pertes maîtrisées |
| **S10** | **Mini IA étage 1 (local) + réappro** : alertes ruptures, **suggestions de réappro + bon de commande**, anti-fraude heuristique, FEFO intelligent. | IA utile hors-ligne |
| **S11** | **Dashboard, KPIs, assistant IA (étage 2) & traçabilité consultable** : tableau de bord 3 niveaux, KPIs précis, **assistant Claude online**, **fiche traçabilité lot + journal sous habilitation**, exports. | Pilotage + traçabilité restituée |
| **S12** | **Durcissement, pentest & pilote terrain** : tests d'isolation RLS, conflits de synchro, audit infalsifiable, OWASP Top 10, résilience réseau, i18n complet ; déploiement **2–3 officines Togo & Gabon**, retours + durcissement final. | 🏁 **MVP complet livré & durci** |

**Critères de succès du MVP** (repris du CDC, validés) :
- **100 %** des ventes encaissées hors-ligne, **sans perte** après synchro.
- **0** fuite inter-tenant tolérée aux tests de durcissement.
- **2–3** officines pilotes actives en Togo & Gabon.

> Le **durcissement (sécurité) est un critère de sortie du MVP, pas une option.**

### PHASE 2 — V2 Croissance & RH (post-MVP)
- App mobile dirigeant dédiée, **paiements Mobile Money** (Togo + Gabon, câblage UI caisse), pointage RH (QR/NFC), **planning/emploi du temps du personnel** (module sous licence séparée, non inclus dans la licence MVP), génération **automatique** des commandes + EDI/API fournisseur (envoi direct), **prévisions IA avancées**, validation hiérarchique, anti-fraude ML, **ventes en attente/reprise de vente**, **programme de fidélité client (points/paliers)**, **stats de performance par vendeur**, **multi-boutique/vue consolidée gérant** (à confirmer en pilote).

### PHASE 3 — V3 Écosystème B2B
- Marketplace pharmaceutique, centrale d'achat, comparateur fournisseurs, téléconsultation, e-prescription, livraison, visiteurs médicaux, **IA visuelle anti-contrefaçon**, **vérification d'authenticité externe (réseau GS1 / base nationale)**, **gestion des salariés au sens large (RH/paie élargie)** — module sous licence séparée, non inclus dans la licence MVP/V2 — ainsi que **devis** (vente B2B), **flux comptables**, **prêt client/crédit** (à valider en pilote), **rappel SMS renouvellement traitement chronique**.

> **Licence par palier (décision 22/06/2026)** : MVP, V2 et V3 sont chacun un palier de licence. Le module **emploi du temps** (V2) et le module **RH/paie élargie** (V3) sont des add-ons sous licence distincte de la licence de base — la pharmacie doit souscrire séparément pour les activer. Gating technique posé dès le MVP (migration `0012_module_licensing.sql` : `tenants.licensed_modules` + RPC `has_licensed_module`), vide par défaut ; aucun code du tronc commun ne doit coder en dur l'accès à ces modules.

> **Gestion des fournisseurs = MVP, et complète (décision 22/06/2026, étendue le 23/06/2026)**, pas V2 — c'est la base de l'approvisionnement (réception de stock, bons de commande), donc une dépendance directe du tronc commun. Carnet d'adresses fournisseurs (nom/téléphone/email) géré dans l'écran `Fournisseurs` sous permission `supplier.manage` (lecture sous `stock.view`). **Extension 23/06/2026** : le **portail fournisseurs** (échange structuré de bons de commande/réception, suivi de statut côté fournisseur via l'abstraction `SupplierConnector`) est lui aussi avancé au MVP, pour offrir une gestion fournisseurs complète dès le pilote — seuls la **génération automatique des commandes** (sans validation manuelle) et l'**EDI/API direct** avec les systèmes fournisseurs restent en V2.

> **Analyse concurrentielle (décision 22/06/2026)** — comparaison de TM Pharma avec un logiciel concurrent (PHARMAXIEL) et avec des logiciels américains/chinois (PioneerRx, RedSail, écosystème pharmacie Alibaba Health), pour identifier les écarts fonctionnels transposables au marché africain.
> - **Gestion des retours fournisseurs = MVP**, pas V2 — complète le cycle commande/réception déjà au tronc commun (S5/S9), permission `supplier.manage`/`stock.adjust`.
> - **Gestion des rebuts (workflow formalisé péremption→rebut) = MVP** — actuellement géré de façon ad hoc via FEFO/`lifecycle/`, à formaliser en écran dédié dès le MVP pour la traçabilité des pertes.
> - **Alertes péremption proactives** : déjà couvertes au MVP (S9, `lifecycle/expiry_alerts.dart`, seuils J-90/J-30/J-7) — confirmé après comparaison avec les logiciels US, pas un écart réel, rien à ajouter.
> - **Devis** (vente B2B) → **V3** — pertinent seulement si extension vers la vente à des structures (cliniques) plutôt que comptoir.
> - **Flux comptables** (proche compta formelle) → **V3** — pertinent seulement pour des structures plus grosses ou intégration cabinets comptables.
> - **Prêt client / crédit** → **V3** — besoin réel probable sur ce marché (crédit informel courant en pharmacie de quartier) mais à valider par les retours du pilote avant développement ; nécessitera `loans`/`loan_repayments`.
> - **Ventes en attente / reprise de vente** → V2 — état panier en pause persisté, faible coût technique.
> - **Mobile Money en caisse (câblage UI)** → V2 — le schéma `payment_mobile_money` existe déjà côté données (S1/S2), juste l'écran caisse à câbler.
> - **Programme de fidélité client (points/paliers)** → V2 — inspiré du 会员管理 (member management) chinois et des programmes loyalty US, fort ROI/rétention attendu pour un faible coût de dev.
> - **Stats de performance par vendeur** → V2 — extension du module `audit` existant, inspiré des rapports employés US/Chine.
> - **Multi-boutique, vue consolidée gérant** → V2 (V3 si pas de besoin confirmé en pilote) — pertinent si un même client gère déjà plusieurs officines.
> - **Rappel SMS renouvellement traitement chronique** → V3 — nécessite intégration SMS gateway (coût récurrent), besoin réel à valider avant dev.
> - **Vente tiers payant / assurance**, **retour télétransmission**, **mode dégradé sans alimentation électrique** → écartés ou hors périmètre logiciel (le dernier point relève du matériel/hardware, cf. §0 stratégie d'hébergement) ; tiers payant/télétransmission à ne développer que si confirmé par le terrain (héritage probable du marché français/maghrébin de PHARMAXIEL, pas certain d'être pertinent au Togo/Gabon).

### PHASE 4 — V4 Impact sectoriel
- E-learning personnel officinal, certifications, bourse pharmaceutique continentale.

---

## 9. Risques & parades

| Risque | Impact | Parade |
|---|---|---|
| Sync offline complexe (conflits) | Élevé | PoC PowerSync dès Sprint 0 ; LWW + règles métier ; tests de scénarios hors-ligne. |
| Isolation multi-tenant (fuite de données) | Critique | RLS systématique + tests d'isolation automatisés (leçon T&M Business : RLS = axe pentest n°1). |
| Coût/latence IA cloud | Moyen | Étage 1 local autonome ; cache ; modèles Haiku par défaut ; budgets. |
| Dépendance agrégateur Mobile Money | Moyen | Abstraction PaymentProvider multi-agrégateurs. |
| Qualité données pharma (catalogue) | Moyen | Import référentiel + scan GS1 ; déduplication. |
| Migrations prod | Élevé | Règle groupe : **migration prod = feu vert explicite**, toujours préparée + testée + ROLLBACK avant application. |
| Fichiers projet sur disque amovible (E:) | Moyen | **Copie de référence sur `C:`** ; envisager un repo git + sauvegarde. |

---

## 10. Méthode de travail (binôme)

- **Recherches web** à l'appui des décisions techniques (réglementation, paiements, libs).
- **Sécurité d'abord** : RLS + audit + habilitations câblés tôt ; pentest planifié (cf. méthode T&M Business).
- **Règle des 80 % de contexte** : dès ~80 %, Claude prépare **automatiquement** la session suivante → mise à jour de `CONTEXTE_RAPIDE.md` (point de reprise), commit si repo, mémoire à jour, tâches à jour. Sans qu'on le demande.
- **Migrations Supabase prod** : jamais sans « applique » explicite.

---

## Sources (recherches du 2026-06-21)
- Offline-first Flutter : [PowerSync × Supabase](https://supabase.com/partners/integrations/powersync) · [Local-first Riverpod+Drift+PowerSync](https://dinkomarinac.dev/blog/building-local-first-flutter-apps-with-riverpod-drift-and-powersync/)
- Mobile Money : [Intégration paiement Togo 2026 (Kolonell)](https://kolonell.com/en/blog/integrate-mobile-payment-togo-tmoney-flooz-2026) · [PayGate](https://www.paygateglobal.com/) · [Mobile Money Gabon 2026 (Atek)](https://www.atekbot.space/blog/gabon-mobile-money-gabon-guide-2026) · [APIs Mobile Money Afrique de l'Ouest (OryStack)](https://orystack.com/integration-des-apis-mobile-money-en-afrique-de-louest-guide-technique-pour-les-equipes-produit/)
- Anti-contrefaçon : [GS1 DataMatrix (Meditrust)](https://meditrust.io/datamatrix-definition/) · [Médecine de qualité en Afrique (NCBI)](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12800327/)
- Prévision pharma : [Demand Forecasting Pharma Retail (MIT)](https://dspace.mit.edu/bitstream/handle/1721.1/159023/de%20Souza%20et%20al_2021.pdf?sequence=1&isAllowed=y) · [Pharmacy Inventory Forecasting (RxERP)](https://rxerp.com/2026/02/10/pharmacy-inventory-forecasting-guide/)
