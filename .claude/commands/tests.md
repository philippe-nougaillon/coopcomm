---
description: Génération de tests (matrice de cas, CoT, bugs détectés mais non corrigés) — T13
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

**NE MODIFIE PAS LE CODE DE PRODUCTION.** Lis le **template T13 — « Génération de tests »** dans `.claude/method/kit-prompting.md` (dans `.claude/method/` — sinon `~/aikku/CLAUDE/kit-prompting.md`). Applique-le rigoureusement au code suivant : $ARGUMENTS

Ordre strict :
1. **Chain of Thought** (« Raisonnement: » en gras) : contrat de chaque fonction publique, chemins (happy path, erreurs, cas limites : vide/null/zéro/négatif/très grand/unicode/concurrence/timeout/dépendance qui échoue), effets de bord à isoler.
2. **Matrice de tests** (cas → entrée → sortie/effet attendu → priorité). Si longue, attends ma validation avant d'écrire.
3. **Tests** : un comportement par test, AAA clair, mocks minimaux, pas de logique dans les tests, pas de dépendance à l'ordre. Conventions du projet (`CLAUDE.md`).
4. **Cas non couverts** : pourquoi (ex. « nécessite une refacto d'injection de dépendance »). Proposition de refacto séparée, pas appliquée ici.
5. **Bugs détectés dans la prod** : fichier:ligne + scénario, **sans les corriger**.
6. **Porte de sortie** : comportement attendu non spécifié → `xfail`/`skip` + commentaire « à clarifier », ne devine pas.
