---
description: Génération de tests (matrice de cas, CoT, bugs détectés mais non corrigés) — T13
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

**NE MODIFIE PAS LA *LOGIQUE* DE PRODUCTION** (contrôleurs, models, workflow, services, comportement des vues). **Seule exception** : l'ajout d'un attribut `data-testid` **inerte** sur un élément de vue, aux conditions fixées par la skill `tests-coopcomm` (tests système, élément sans texte ciblable, dernier attribut de la balise) ; signale les vues touchées dans ta réponse. Toute **autre** modif de prod (logique, correction de bug) reste **signalée, non appliquée** (point 5).

**Invoque d'abord la skill `tests-coopcomm`** (`.claude/skills/tests-coopcomm/`) : son `SKILL.md` porte les règles transverses (nommage, commentaires, ordre, tests critiques, helpers, `skip`, fixtures) et renvoie aux gabarits imposés par type de test. Le template T13 ci-dessous dit *comment conduire la session* ; la skill dit *à quoi doit ressembler le test écrit* — **en cas d'écart, la skill l'emporte**.

Lis le **template T13 — « Génération de tests »** dans `.claude/method/kit-prompting.md` (dans `.claude/method/` — sinon `~/aikku/CLAUDE/kit-prompting.md`). Applique-le rigoureusement au code suivant : $ARGUMENTS

Ordre strict :
1. **Chain of Thought** (« Raisonnement: » en gras) : contrat de chaque fonction publique, chemins (happy path, erreurs, cas limites : vide/null/zéro/négatif/très grand/unicode/concurrence/timeout/dépendance qui échoue), effets de bord à isoler.
2. **Matrice de tests** (cas → entrée → sortie/effet attendu → priorité). Si longue, attends ma validation avant d'écrire.
3. **Tests** : un comportement par test, AAA clair, mocks minimaux, pas de logique dans les tests, pas de dépendance à l'ordre. Conventions du projet (`CLAUDE.md`).
4. **Cas non couverts** : pourquoi (ex. « nécessite une refacto d'injection de dépendance »). Proposition de refacto séparée, pas appliquée ici.
5. **Bugs détectés dans la prod** : fichier:ligne + scénario, **sans les corriger**.
6. **Porte de sortie** : comportement attendu non spécifié → `skip` dont le message dit **ce qu'il faut trancher**, ne devine pas. Un test qui ne passe pas parce que l'application est cassée **reste rouge** : ni `skip`, ni assertion affaiblie.
