---
description: Recherche approfondie avec Chain of Thought, 5e question contradictoire et porte de sortie (T4)
allowed-tools: WebFetch, WebSearch, Read, Bash, Glob, Grep
---

Lis le **template T4 — « Recherche approfondie (agent de recherche) »** dans `.claude/method/kit-prompting.md` (dans `.claude/method/` — sinon `~/aikku/CLAUDE/kit-prompting.md`). Applique-le rigoureusement au sujet suivant : $ARGUMENTS

Avant tout : liste les sources auxquelles tu as réellement accès (web, mes documents, ta connaissance + sa date limite). Demande-moi de valider chaque question avant de chercher. **Porte de sortie obligatoire** : si une donnée n'existe pas, dis-le — ne la déduis pas. Pour les listes factuelles simples, demande-les-moi avant de chercher.
