---
description: Tri/qualification de tickets en JSON (type, sévérité, priorité, composant…) — T12
---

Lis le **template T12 — « Tri / qualification de tickets »** dans `.claude/method/kit-prompting.md` (dans `.claude/method/` — sinon `~/aikku/CLAUDE/kit-prompting.md`). Applique-le rigoureusement aux tickets suivants (un par bloc) : $ARGUMENTS

Réponds **UNIQUEMENT en JSON valide** (un objet par ticket), aucun texte autour. Champs : `id`, `type`, `severite`, `priorite`, `composant`, `effort`, `besoin_infos`, `questions_a_poser`, `doublon_possible_de`, `indices_securite`, `justification`. Si un champ ne peut pas être déterminé : `"?"` + ajouter une question. Tout indice de sécurité → `type=security`, `severite ≥ S2`, signaler explicitement. Tu **suggères**, tu ne fermes pas (« invalid »/« duplicate » sont des propositions, pas des décisions).

Si tu n'as pas le contexte projet (composants/équipes), demande-le-moi avant de répondre.
