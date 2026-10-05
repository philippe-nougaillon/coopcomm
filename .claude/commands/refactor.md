---
description: Refacto / feature code (exploration AVANT, mini-plan validé, diff par étapes) — T7
allowed-tools: Read, Edit, Write, Bash, Glob, Grep
---

**NE COMMENCE PAS À CODER.** Lis le **template T7 — « Refacto / feature code (avec Claude Code) »** dans `.claude/method/kit-prompting.md` (dans `.claude/method/` — sinon `~/aikku/CLAUDE/kit-prompting.md`). Applique-le rigoureusement à l'objectif suivant : $ARGUMENTS

Ordre strict :
1. **Explore le repo** : structure, conventions, points sensibles, tests existants. Dis-moi ce que tu trouves.
2. **Pose-moi 10 questions par blocs de 4** (périmètre, contraintes, compat, perf/SLO, stratégie de test, risques de régression). Attends mes réponses.
3. Propose **2-3 approches** avec leurs trade-offs. Pour celle que tu recommandes : fais le **devil's advocate** (défends l'approche inverse).
4. Une fois validé : note la décision dans `suivi/journal/AAAA-MM.md` (+ sa ligne d'index dans `suivi/journal-decisions.md`) (et l'état courant dans `CLAUDE.md` §4 seulement s'il a changé) PUIS un mini-plan en étapes vérifiables.
5. Implémente **UNE étape à la fois** : diff + tests + ma validation, à chaque pas.

Pas de touche hors périmètre. Conversations courtes : si ça s'allonge, synthèse dans `.claude/method/journal-session.md` et nouvelle conversation.
