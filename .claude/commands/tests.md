---
description: Génération de tests (matrice de cas, CoT, bugs détectés mais non corrigés) — T13
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

**NE MODIFIE PAS LA *LOGIQUE* DE PRODUCTION** (contrôleurs, models, workflow, services, comportement des vues). **Exception explicite (décision PE 2026-07-22)** : tu **peux** ajouter un attribut `data-testid` sur un élément de vue quand c'est le moyen le plus fiable de le cibler. Préfère **toujours** ça à un sélecteur CSS/XPath/`title=`/`data-action` fragile ou à un helper de test qui contourne un markup non ciblable — **objectif : les tests les plus stables possible**. Ces attributs sont **inertes** (aucun effet sur le comportement, donc hors de l'interdit ci-dessus) ; signale-les dans ta réponse (ce sont des modifs de vue à relire). Toute **autre** modif de prod (logique, correction de bug) reste **signalée, non appliquée** (point 5).

**Invoque d'abord la skill `tests-coopcomm`** (`.claude/skills/tests-coopcomm/`) : elle porte les gabarits imposés du projet (policies, contrôleurs), les règles de fixtures, le marquage des tests critiques et le placement des helpers. Le template T13 ci-dessous dit *comment conduire la session* ; la skill dit *à quoi doit ressembler le test écrit*.

Lis le **template T13 — « Génération de tests »** dans `.claude/method/kit-prompting.md` (dans `.claude/method/` — sinon `~/aikku/CLAUDE/kit-prompting.md`). Applique-le rigoureusement au code suivant : $ARGUMENTS

Ordre strict :
1. **Chain of Thought** (« Raisonnement: » en gras) : contrat de chaque fonction publique, chemins (happy path, erreurs, cas limites : vide/null/zéro/négatif/très grand/unicode/concurrence/timeout/dépendance qui échoue), effets de bord à isoler.
2. **Matrice de tests** (cas → entrée → sortie/effet attendu → priorité). Si longue, attends ma validation avant d'écrire.
3. **Tests** : un comportement par test, AAA clair, mocks minimaux, pas de logique dans les tests, pas de dépendance à l'ordre. Conventions du projet (`CLAUDE.md`).
4. **Cas non couverts** : pourquoi (ex. « nécessite une refacto d'injection de dépendance »). Proposition de refacto séparée, pas appliquée ici.
5. **Bugs détectés dans la prod** : fichier:ligne + scénario, **sans les corriger**.
6. **Porte de sortie** : comportement attendu non spécifié → `xfail`/`skip` + commentaire « à clarifier », ne devine pas.
