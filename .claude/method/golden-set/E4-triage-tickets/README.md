# E4 — Tri de tickets ambigus

**Tâche** : qualifier en JSON 10 tickets bruts d'OrderFlow (le projet de E1 — réutiliser le contexte si pas déjà chargé). Le modèle doit produire un objet JSON par ticket selon la rubrique du template T12.

**Contexte du projet** (à donner via le prompt) :
- Produit : *OrderFlow*, plateforme e-commerce B2B (commandes inter-entreprises, catalogue, facturation).
- **Composants** : `auth`, `catalog`, `cart`, `checkout`, `inventory`, `billing`, `notif`, `admin-ui`, `api`, `docs`.
- **Équipes** : Core (auth, api, admin-ui), Commerce (catalog, cart, checkout, inventory), Payments (billing, notif), DX (docs).

**Fixture** : `fixture.md` (10 tickets bruts, qualité éditoriale variable — comme dans la vie).

**Pièges plantés** (cf. `reference.md`) :
- 1 ticket déclaré « bug » qui est en fait une demande de feature.
- 1 ticket déclaré « feature » qui décrit une **faille de sécurité (XSS stocké)** → doit être requalifié `security`, sévérité ≥ S2.
- 1 doublon (formulation différente).
- 1 ticket vague → besoin d'infos = oui + questions précises.
- 1 ticket à composant ambigu (touche deux).
- 1 ticket avec sévérité S1 prétendue mais cosmétique.
- 1 vrai S1 (perte de données).

**Critères de la grille A.3 applicables** : Format (JSON valide, schéma respecté), Fidélité (pas d'invention de cause), Sécurité (détection du XSS déguisé), Complétude (questions pertinentes quand `besoin_infos=oui`), « Élévation » (la justification fait sens).

**Notation rapide** :
- **3** = JSON valide pour les 10 tickets, détecte le XSS comme `security`, détecte le doublon, requalifie les types erronés, pose des questions pertinentes sur les vagues, ne ferme rien autoritairement.
- **2** = manque ≤ 2 requalifications/détections, JSON valide.
- **1** = manque le XSS OU le doublon OU le faux S1 ; ou JSON cassé.
- **0** = ferme des tickets en autorité (« invalid » sans question), ou rate ≥ 3 pièges, ou JSON non parseable.

**Pénalité forte** : un JSON non parseable est éliminatoire sur le critère « Format ».
