# Slash-commands de projet

10 commandes « action » + `/eval`. Chacune **renvoie** vers un template de `.claude/method/kit-prompting.md` (source de vérité unique — ne PAS dupliquer le contenu des templates ici). `$ARGUMENTS` = ce que tu tapes après le nom de la commande.

| Commande | Template | À quoi ça sert |
|---|---|---|
| `/extract` | T1 | Extraction + Gestalt + steelman d'un document (RFC, design doc, rapport, doc d'API…) |
| `/deep-research` | T4 | Recherche approfondie : CoT, 4 questions + 5ᵉ contradictoire, porte de sortie |
| `/image-prompt` | T6 | Génération d'un prompt image (intention + JSON de style) |
| `/refactor` | T7 | Refacto / feature code (exploration AVANT, mini-plan, diff par étapes) |
| `/session-start` | T8 | Démarrage / reprise / clôture de session d'agent (`CLAUDE.md`, `.claude/method/journal-session.md`) |
| `/review` | T9 | Revue de PR (correctness, sécurité, tests, lisibilité, devil's advocate) |
| `/post-mortem` | T10 | Post-mortem d'incident (blameless, fait/déduction, causes racines, actions) |
| `/api-doc` | T11 | Documentation d'API (fidèle à la source, porte de sortie sur les ambiguïtés) |
| `/triage` | T12 | Tri/qualification de tickets en JSON (type/sévérité/priorité/composant…) |
| `/tests` | T13 | Génération de tests (CoT, matrice cas → entrée → sortie, bugs détectés non corrigés) |
| `/eval` | — | Lance une éval du `.claude/method/golden-set/` (un cas ou tous) + écrit dans `.claude/method/golden-set/_journal.md` |

**Méta-méthodes laissées hors slash-commands** (à invoquer verbalement, cf. `.claude/method/kit-prompting.md`) :
- **T2 — Dialogue Engineering** (« partenaire de réflexion » : convoquer des penseurs, anti-flagornerie, phase 4 de Polya)
- **T3 — Écriture sans clichés** (contraintes anti-lissage, Open Loop, structure WSJ)
- **T5 — Critique steelman** (revue de décision : steelman des deux côtés)

Ce sont des postures à orchestrer dans la conversation, pas des actions ponctuelles — les figer en commandes nuirait.

**Pré-requis pour utiliser ces commandes dans un autre projet** : copier `kit-prompting.md` dans `.claude/method/` (ou ajuster le chemin dans chaque commande pour pointer vers `~/aikku/CLAUDE/kit-prompting.md` si tu préfères un emplacement central).

**Sécurité** : les commandes héritent de tes `settings.json`/`settings.local.json`. Pas de secret dans ces fichiers.
