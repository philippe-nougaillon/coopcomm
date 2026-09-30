---
description: Démarrage / reprise / clôture de session d'agent (CLAUDE.md, journal-session.md) — T8
allowed-tools: Read, Edit, Write, Bash, Glob, Grep
---

Lis le **template T8 — « Démarrage / reprise de session d'agent (anti context rot, mémoire persistante) »** dans `.claude/method/kit-prompting.md` (dans `.claude/method/` — sinon `~/aikku/CLAUDE/kit-prompting.md`). Choisis le mode selon ce que je te dis : $ARGUMENTS

- **DÉMARRAGE** (mots-clés : « démarre », « init », « new ») → crée `CLAUDE.md` à la racine + arborescence Notes/Projets/Publications avec un `CLAUDE.md` par sous-dossier qui dit à quoi il sert.
- **REPRISE** (mots-clés : « reprends », « continue ») → lis `CLAUDE.md` et `.claude/method/journal-session.md` ; résume où on en est, ce qu'on a appris, ce qu'il reste à faire ; puis on continue.
- **CLÔTURE** (mots-clés : « clôture », « fin », « end ») → synthèse de notre travail (20 lignes max : décisions, état du code, prochaines étapes) dans `suivi/journal/AAAA-MM.md` (+ sa ligne d'index dans `suivi/journal-decisions.md`) ; dans `CLAUDE.md`, ne touche que l'état courant (§4), une leçon durable (§3) ou une convention (§2) ; revue du dossier (refactoring = jardinage).

Si rien n'est précisé : demande-moi.
