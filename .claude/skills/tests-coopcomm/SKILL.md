---
name: tests-coopcomm
description: Conventions et gabarits imposés des tests du projet (Minitest, Rails, Pundit, Capybara). À lire AVANT d'écrire, de modifier ou de relire un test — test de policy, de contrôleur, de modèle, de job, de service ou système — ainsi que pour ajouter une fixture, marquer un test critique, placer un helper de test, ou rejouer les tests échoués.
---

# Tests — CoopComm

**Minitest** (`test/`, fixtures dans `test/fixtures/`), tests système Capybara + Selenium, couverture SimpleCov.

**Exigence : tout ce qui peut être testé doit l'être.** L'objectif n'est pas seulement d'éviter les mauvaises surprises, mais de forcer une réflexion sur les cas limites — un test difficile à écrire révèle souvent une décision de conception à prendre. Donc : modèles (validations, workflow, callbacks), policies Pundit, services, jobs, contrôleurs, et parcours critiques en tests système.

## Aiguillage

| Ce que j'écris | Où sont les règles |
|---|---|
| Test de **policy** Pundit | `policies.md` — gabarit imposé, à lire en entier |
| Test de **contrôleur** | `controleurs.md` — gabarit imposé, à lire en entier |
| Test de **modèle** (ou de concern de modèle) | `modeles.md` — gabarit imposé, à lire en entier |
| Ajout ou choix d'une **fixture** | `fixtures.md` |
| Test de **job, service, système** | Aucun gabarit imposé à ce jour — appliquer les règles transverses ci-dessous. Ne pas en inventer un. |

## Règles transverses (tous types de tests)

**Tout ce qui touche aux services se teste, et c'est critique.** Le rattachement aux services est la racine du système : l'organisation, le périmètre de visibilité, les listes d'agents et le cloisonnement entre communes en dérivent tous. Validation, rattachement, filtre, périmètre, dérivation d'organisation — chacun a son test, marqué critique. **Cette règle prime sur toutes les exclusions** de ce fichier et de `modeles.md` : un test de services ne se supprime pas parce qu'il porte sur une validation déclarative, une relation ou un audit de la gem.

**Ce qui est commenté ne se teste pas.** Méthode, action, route, transition ou bloc mis en commentaire : aucun test, d'aucune sorte — ni de refus, ni de non-régression, ni de sentinelle. Le jour où la fonctionnalité rouvre, les tests s'écrivent à ce moment-là.

**Une condition à la fois, dans l'ordre du code.** Quand on couvre une méthode et ses dérivées, on avance condition par condition : C1, puis C2, puis C3 — jamais dans le désordre. L'ordre des tests doit se relire en regard du code testé.

**Aucun commentaire dans un fichier de test.** Le nom du fichier et celui de chaque test doivent suffire. Seule exception : une ligne en tête de fichier quand la **raison d'être** du fichier ne se devine pas (typiquement un test d'intégration transverse), et seulement si elle apprend quelque chose. Les précisions sur une fixture passent par le **nom de la variable** (`convention_autre_org`, `service_supprimable`), pas par un commentaire.

**Tests critiques — marqueur et bannière** *(vaut pour tous les types de tests, **sauf** les tests système)*. Le marqueur se met **à la fin du nom**, entre parenthèses (`… → <effet> (critique)`), jamais en préfixe. Les tests critiques qui se suivent sont **groupés et encadrés** par exactement ces deux lignes, avec **une ligne vide avant la fermeture** pour ne pas la coller au dernier test :

```
# ==================== TESTS CRITIQUES ====================
# (le commentaire d'explication reste : il dit pourquoi ces tests sont critiques)
# ==================== /TESTS CRITIQUES ====================
```

Plusieurs blocs par fichier sont normaux — chacun vit auprès de ce qu'il vise.

**Helpers de test** *(vaut pour tous les types de tests, **sauf** les tests système)*. Une méthode utilisée par **un seul** fichier vit sous `private`, en fin de classe, avec le commentaire qui l'explique **collé à elle**. Utilisée par **plusieurs** fichiers, elle devient un module de `test/support/` que les fichiers `require_relative` et `include` — comme `fabrique_xls.rb`, `interventions_matrice.rb` et `lecture_pdf.rb` qui s'y trouvent déjà.

**Déplacer du test, c'est déplacer son voisinage** — règle générale du projet, énoncée dans `CLAUDE.md` §1 : après tout déplacement outillé de méthode, de test, de bloc ou de constante, relire le voisinage du point de départ **et** du point d'arrivée ; relancer la suite ne suffit pas.

## Savoir ce qui est rouge

Chaque run de tests écrit la liste des échecs dans **`test/failed_tests.rb`** (un `fichier:ligne` par ligne, via le reporter `test/failed_tests_reporter.rb`). **Lire ce fichier directement** pour savoir ce qui est rouge, au lieu de relancer la suite pour le découvrir.

Pour rejouer ces seuls tests : **`bin/rails test:failed`** — jamais une commande bricolée à la main.

⚠ Le fichier est **vidé au démarrage** de chaque run et ne reflète donc que le **dernier** run : s'il est vide ou périmé, relancer `bin/rails test` pour le remplir, et le lire ensuite.
