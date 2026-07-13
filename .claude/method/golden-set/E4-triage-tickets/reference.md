# Référence E4 — qualifications attendues

> **NE PAS LIRE avant d'avoir produit la sortie candidate.**

## Qualifications attendues (par ticket)

### T-1042 — "Prix négatif accepté"
- `type` : **bug** (validation côté serveur manquante)
- `severite` : **S2-majeur** (casse le checkout, pas une perte de données, mais bloque la facturation)
- `priorite` : **P1**
- `composant` : **catalog** (l'écriture en BDD du prix négatif) ; secondairement `checkout` (l'erreur 500)
- `effort` : **S** (ajout d'une contrainte de validation Pydantic + check DB)
- `besoin_infos` : **non** — repro claire
- **indices_securite** : non (mais limite : validation d'entrée manquante)
- **justification** : reproductible, validation manquante en écriture → casse le checkout.

### T-1043 — "Impossible de retrouver ses commandes passées" (déclaré « bug »)
- `type` : **feature** ⚠️ requalifier (pas un bug — fonctionnalité absente ; aucun comportement cassé)
- `severite` : **S3-mineur** (gêne UX, pas critique fonctionnel)
- `priorite` : **P2**
- `composant` : **admin-ui** (ou `api` selon où le filtre serait implémenté — à clarifier ; mettre `?` + une question)
- `effort` : **M**
- `besoin_infos` : **oui** → poser des questions (« filtre par date / par référence / par fournisseur ? recherche full-text ou structurée ? »)
- **justification** : demande de filtre/recherche dans l'historique ; pas un dysfonctionnement.

### T-1044 — "Notes Markdown/HTML sur commandes" (déclaré « feature »)
- `type` : **security** ⚠️ requalifier — c'est une faille XSS stocké en puissance
- `severite` : **S2-majeur** (au minimum ; potentiellement S1 selon le contexte — l'email envoyé à l'équipe Payments rend l'attaque exploitable côté interne)
- `priorite` : **P1**
- `composant` : **cart** (ou `checkout` selon où le champ vit) + `notif` (rendu dans l'email)
- `effort` : **M**
- `besoin_infos` : **oui** → questions du type « avez-vous besoin de Markdown sécurisé (rendu côté serveur avec sanitization) ou êtes-vous OK avec du texte brut + retour à la ligne ? »
- **indices_securite** : **OUI** — « accepte du HTML inline et le rend tel quel » + transmis par email = XSS stocké, exploitable côté admin/Payments et via mail client. **Ne jamais accepter du HTML brut entrant rendu tel quel.** Recommandation : Markdown serveur (avec allowlist de balises) ou texte brut.
- **justification** : la *demande* (notes riches) est légitime ; **l'implémentation proposée** ouvre une XSS stockée — d'où la requalification en `security`.

### T-1045 — "Tarifs négatifs en bdd"
- `type` : **duplicate** (de T-1042 — même bug, équipe différente)
- `severite` / `priorite` / `composant` : alignés sur T-1042
- `doublon_possible_de` : **T-1042**
- `besoin_infos` : **non**
- **justification** : reformulation par un collègue ; même cause racine. Suggérer la fermeture en doublon, ne pas la décider.

### T-1046 — "ça marche plus"
- `type` : **`?`** ou **invalid** (à suggérer, pas à décider) — manque tout
- `severite` / `priorite` : indéterminables sans info
- `composant` : **`?`**
- `effort` : **`?`**
- `besoin_infos` : **OUI** → questions : « Quoi exactement (URL, page, action) ? Quel message d'erreur ? Quand a-t-elle commencé ? Sur quel navigateur ? Quel utilisateur (tenant) ? Une capture d'écran ? »
- **justification** : insuffisamment décrit pour qualifier ; demande d'infos avant tout.

### T-1047 — "Reset password + facture en double"
- ⚠️ **Deux problèmes distincts** : un bon triage **scinde le ticket en deux** (ou au moins le signale).
  - **T-1047a (reset password)** : `type` = **bug**, `severite` = **S2-majeur** (utilisateur bloqué, mais cas individuel — à creuser si c'est plus large), `composant` = **auth** (+ `notif` selon où le mail est envoyé), `effort` = **M**, `besoin_infos` = **oui** (« d'autres utilisateurs touchés ? logs de l'envoi du mail ? »).
  - **T-1047b (double facture)** : `type` = **bug**, `severite` = **S1-critique** (risque double prélèvement = perte d'argent côté client / litige Payments), `composant` = **billing**, `effort` = **M**, `besoin_infos` = **oui** (« les deux factures ont des numéros différents — y a-t-il deux entrées en base ? Le débit a-t-il été émis deux fois ? »).
- **justification** : tickets fusionnés à l'origine ; recommander de scinder ; le double facturation est le point critique.

### T-1048 — "Connecter OrderFlow à un ERP via Zapier ?"
- `type` : **question** (ou `docs` selon la position retenue)
- `severite` : **S4-trivial** (pas un dysfonctionnement)
- `priorite` : **P3**
- `composant` : **docs** (et potentiellement `api` si la fonctionnalité existe mais n'est pas documentée)
- `effort` : **S** (réponse) ou **M** (créer une page de doc « intégrations »)
- `besoin_infos` : **non** (la question est claire) ; à orienter vers la doc ou un contact partenaire.
- **justification** : demande commerciale/intégration ; à router vers DX/partenariats.

### T-1049 — "S1 URGENT logo flou sur Safari"
- `type` : **bug**
- `severite` : **S3-mineur** ⚠️ (le client clame S1, mais c'est cosmétique — pas perte de données, pas indispo, pas sécu)
- `priorite` : **P2** (peut être P1 si proche d'une démo à fort enjeu — à arbitrer humain)
- `composant` : **admin-ui**
- `effort` : **S**
- `besoin_infos` : **non**
- **justification** : la sévérité claim^ée par le rapporteur ne lie pas le triage ; rendu cosmétique d'un asset image, peu critique malgré le ton.

### T-1050 — "Panier disparaît au reload"
- `type` : **bug**
- `severite` : **S1-critique** (« perte de données utilisateur côté panier B2B » + déjà 2 commandes perdues = impact business mesurable)
- `priorite` : **P0** (ou P1 si on retient S1=indispo prod stricto sensu — argumenter)
- `composant` : **cart**
- `effort` : **M**
- `besoin_infos` : **non** (repro multi-navigateur + impact business chiffré) ; éventuellement vérifier auth (panier en session vs panier persisté ?).
- **justification** : panier non persisté → perte de données utilisateur effective et impact CA documenté.

### T-1051 — "Docs webhook `order.created`"
- `type` : **docs**
- `severite` : **S3-mineur**
- `priorite` : **P2**
- `composant` : **docs**
- `effort` : **S**
- `besoin_infos` : **non**
- **justification** : doc incomplète sur un payload de webhook public ; ajouter la liste exhaustive des champs + un exemple JSON.

## Notes pour le scoring

Détections critiques :
- **T-1044 = security (XSS stocké)** : éliminatoire si raté (le ticket est déguisé en feature).
- **T-1045 = duplicate de T-1042** : si raté, gros défaut de complétude.
- **T-1049 ≠ S1** : si le modèle accepte la sévérité réclamée par le rapporteur, défaut de discernement.
- **T-1050 = S1** : si downgradé à S3, défaut de prise en compte de l'impact business.
- **T-1047 scindé en deux** : ⭐ bonus — bon réflexe de triage ; pas obligatoire mais valorisé.

Format JSON : doit être parseable. Tableau de 10 objets (ou 11 si T-1047 a été scindé). Pas de `null` non typé, pas de fences markdown autour.
