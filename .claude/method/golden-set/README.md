# Golden set — fixtures d'évaluation

Jeu de tâches dérivées de travail réel (ici : 3 fixtures synthétiques mais réalistes pour démarrer ; à substituer par du réel anonymisé au fur et à mesure). Voir `../methode-evaluation-et-securite-agents.md` §A pour le protocole complet.

| Code | Tâche | Template | Fixture |
|---|---|---|---|
| **E1** | Revue de PR | T9 | `fixture.diff` — diff **Rails 7.x / Ruby 3.x** (`ProfilesController` + endpoint interne), specs **RSpec**. **3 bugs critiques de sécurité** (autorisation cassée via piège des chaînes truthy en Ruby, SQL injection par interpolation, fuite de secrets) + mass assignment + spec négatif manquant + nit idiomatique |
| **E4** | Tri de tickets ambigus | T12 | `fixture.md` — 10 tickets bruts métier (mauvais labels prétendus, doublons, vague, faille de sécurité déguisée en feature, etc.). *Agnostique à la stack.* |
| **E5** | Génération de tests | T13 | `fixture.rb` — **Ruby 3.x** : méthode `PricingService.compute_total_discount(cart:, codes:, now:, max_total_pct:)` avec `BigDecimal` + `Time.zone` (~90 lignes) ; **1 bug subtil de validité temporelle** (asymétrie inclusive/exclusive) + 1 comportement non spécifié (multi-exclusifs). Tests à générer en **RSpec** (`travel_to` natif). |

**Pour lancer** : `/eval E1` (ou `E4`, `E5`, `all`). Voir `.claude/commands/eval.md` pour le protocole.

**Structure** d'une fixture :
```
Eᵢ-<nom>/
├── README.md     ← contexte de la tâche, critères de notation A.3 applicables
├── prompt.md     ← le prompt gelé (renvoie au template Tn de kit-prompting.md)
├── fixture.*     ← l'entrée
├── reference.md  ← ce qu'un bon modèle doit trouver (NE PAS LIRE avant d'avoir produit la sortie)
└── runs/         ← les sorties datées : AAAA-MM-JJ-HHMM-<modele>.md
```

**Pré-requis** : les fixtures sont **gelées**. On ne modifie pas le prompt ni la fixture entre deux campagnes (sinon on mesure le prompt, pas le modèle). Si on doit changer, on repart d'une nouvelle ligne de base et on l'écrit dans `_journal.md`.

**Origine** : ces 3 fixtures sont synthétiques (rédigées le 2026-05-12) pour donner un point de départ. À remplacer par du réel anonymisé dès que possible — le « hors‑sol » est un risque connu (§17.1 angle mort #10 de la synthèse principale).
