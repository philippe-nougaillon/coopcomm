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
| Test de **contrôleur** (une action) | `controleurs.md` — gabarit imposé, à lire en entier |
| Test d'**intégration** (plusieurs actions enchaînées) | `integration.md` — gabarit imposé, à lire en entier |
| Test de **modèle** (ou de concern de modèle) | `modeles.md` — gabarit imposé, à lire en entier |
| Test de **service** (`app/services/`) | `services.md` — gabarit imposé, à lire en entier |
| Ajout ou choix d'une **fixture** | `fixtures.md` |
| Test **système** (parcours navigateur) | `systeme.md` — gabarit imposé, à lire en entier |
| Test de **job** | Aucun gabarit imposé à ce jour — appliquer les règles transverses ci-dessous. Ne pas en inventer un. |

## Hiérarchie : contrôleur < intégration < système

Trois niveaux, du moins cher au plus cher. **Un comportement ne se teste qu'à un seul.**

| Niveau | Ce qu'il couvre |
|---|---|
| **Contrôleur** | chaque cas particulier d'**une** action : ce que la machine doit faire, et ce qu'elle doit refuser |
| **Intégration** | un parcours utilisateur, mais toujours dans la couche contrôleur (`get`, `post`, `assert_dom`) : **plusieurs actions enchaînées** — créer une intervention → la voir dans l'index → la terminer |
| **Système** | les parcours utilisateurs **critiques**, et uniquement ce qui n'est testable à aucun des deux niveaux inférieurs : le JavaScript, la CSS, le clic réel |

**La règle de décision, dans cet ordre :** ça tient dans une seule action → contrôleur. Il faut enchaîner des actions → intégration. Il faut un navigateur → système.

**Jamais deux niveaux pour la même chose.** Un test système qui refait ce qu'un test de contrôleur prouve déjà se supprime, il ne se garde pas « au cas où » : il coûte 25 fois plus cher, il flake, et le jour où le comportement change il faut corriger deux endroits.

**Les messages d'erreur d'un formulaire (`#error_explanation`) se vérifient en système**, et on y asserte **chacun des messages** de la div, pas seulement sa présence — c'est le seul moyen de savoir que l'utilisateur lit la bonne cause. Le **refus** lui-même (statut 422, état inchangé en base) reste au niveau contrôleur : les deux ne se recouvrent pas.

## `flunk` : le test échoue parce qu'il manque quelque chose

**Quand un test ne passe pas alors que la logique métier veut qu'il passe, on écrit `flunk` avec la raison** (règle Alex, 2026-08-26) — jamais un `skip`, jamais une assertion tordue pour faire passer.

```ruby
flunk "L'œil pour afficher le mot de passe est caché quand le champ a le focus, à corriger"
flunk "Le graphe « CO2 par mois » n'existe pas sur le tableau de bord"
```

Le message dit **ce qui manque**, pas « ça ne marche pas ». Il vaut aussi pour signaler un test **à écrire** : on le pose là où il devra vivre, avec ce qu'il devra prouver.

Le `skip` reste réservé à une décision métier en attente ; le `flunk`, à un défaut de l'application.

## Règles transverses (tous types de tests)

**Tout ce qui touche aux services se teste, et c'est critique.** Le rattachement aux services est la racine du système : l'organisation, le périmètre de visibilité, les listes d'agents et le cloisonnement entre communes en dérivent tous. Validation, rattachement, filtre, périmètre, dérivation d'organisation — chacun a son test, marqué critique. **Cette règle prime sur toutes les exclusions** de ce fichier et de `modeles.md` : un test de services ne se supprime pas parce qu'il porte sur une validation déclarative, une relation ou un audit de la gem.

**Ce qui est commenté ne se teste pas.** Méthode, action, route, transition ou bloc mis en commentaire : aucun test, d'aucune sorte — ni de refus, ni de non-régression, ni de sentinelle. Le jour où la fonctionnalité rouvre, les tests s'écrivent à ce moment-là.

**Une condition à la fois, dans l'ordre du code.** Quand on couvre une méthode et ses dérivées, on avance condition par condition : C1, puis C2, puis C3 — jamais dans le désordre. L'ordre des tests doit se relire en regard du code testé.

**Le nom d'un test est une phrase qui énonce un comportement (règle Alex, 2026-08-25).** Pas une coordonnée technique (`update : intitulé vide → 422`), mais une règle du domaine, lisible par quelqu'un qui ne connaît pas le code :

```ruby
test 'une commande est affichée avec succès'
test 'une commande est archivée lorsqu’elle est supprimée'
test 'la recherche dans la liste ne retourne que les commandes correspondantes'
test 'une commande à l’état envoyé peut être validée'
```

Le nom ne s'adresse pas au lecteur et ne raconte pas le décor : les formules « de son périmètre », « qu'il gère », « auquel il a droit » disparaissent — le contexte est dans le corps du test. **Exception** : le mot « périmètre » reste quand le test porte précisément dessus (un paramètre forgé hors périmètre, un résultat borné au périmètre).

**Migration au fil de l'eau (règle Alex, 2026-08-25) : à chaque fois qu'on touche un fichier de test, on convertit *tous* ses noms à cette forme**, même ceux qu'on ne modifiait pas. Jamais de passe globale sur le dépôt : la reprise se fait fichier par fichier, au moment où l'on y travaille de toute façon. `test/controllers/commandes_controller_test.rb` sert de référence.

Vaut pour **tous** les types de tests.

**Chaque chose porte son nom, et un seul (règle Alex, 2026-08-19).** Aucune ambiguïté dans les noms de tests, les messages d'assertion, les variables et les commentaires : trois objets voisins se confondent sans arrêt, alors qu'ils n'ont rien à voir.

| L'objet | Son nom | Jamais |
|---|---|---|
| `MailLog` | un **mail log** | une notification, une alerte, un mail envoyé |
| `Message` (messagerie) | un **message** | une notification, une alerte, un mail |
| Le bandeau de flash à l'écran | une **notification** ou une **alerte** (le toast) | un message, un mail |

La règle vaut au-delà de ces trois : on désigne un objet par son nom, pas par un synonyme de circonstance. *(Les tests antérieurs à cette règle n'ont pas été renommés.)*

**Aucun commentaire dans un fichier de test.** Le nom du fichier et celui de chaque test doivent suffire. Seule exception : une ligne en tête de fichier quand la **raison d'être** du fichier ne se devine pas (typiquement un test d'intégration transverse), et seulement si elle apprend quelque chose. Les précisions sur une fixture passent par le **nom de la variable** (`convention_autre_org`, `service_supprimable`), pas par un commentaire.

**Tests critiques — marqueur ET bannière, jamais l'un sans l'autre** *(vaut pour tous les types de tests, **sauf** les tests système)*. Les deux sont obligatoires et ne se remplacent pas :

1. **Chaque** test critique porte le marqueur **à la fin de son nom**, entre parenthèses (`… → <effet> (critique)`), jamais en préfixe. **Aucune exception**, y compris pour un test généré dans une boucle (le marqueur va dans la chaîne interpolée) et pour un test déjà entouré d'une bannière.
2. Les tests critiques qui se suivent sont **groupés et encadrés** par exactement ces deux lignes, avec **une ligne vide avant la fermeture** pour ne pas la coller au dernier test :

```
# ==================== TESTS CRITIQUES ====================
# (le commentaire d'explication reste : il dit pourquoi ces tests sont critiques)
# ==================== /TESTS CRITIQUES ====================
```

*Pourquoi les deux* : la bannière explique **pourquoi** le groupe est critique et se lit dans le fichier ; le marqueur voyage avec le test — dans la sortie d'un run, dans `test/failed_tests.rb`, dans un rapport de couverture — là où la bannière est invisible. Un test critique déplacé hors de son groupe garde ainsi son statut.

Plusieurs blocs par fichier sont normaux — chacun vit auprès de ce qu'il vise. Un test critique isolé porte son marqueur **sans** bannière si aucun autre ne le rejoint.

**Helpers de test** *(vaut pour tous les types de tests, **sauf** les tests système)*. Une méthode utilisée par **un seul** fichier vit sous `private`, en fin de classe, avec le commentaire qui l'explique **collé à elle**. Utilisée par **plusieurs** fichiers, elle devient un module de `test/support/` que les fichiers `require_relative` et `include` — comme `fabrique_xls.rb`, `interventions_matrice.rb` et `lecture_pdf.rb` qui s'y trouvent déjà.

**Déplacer du test, c'est déplacer son voisinage** — règle générale du projet, énoncée dans `CLAUDE.md` §1 : après tout déplacement outillé de méthode, de test, de bloc ou de constante, relire le voisinage du point de départ **et** du point d'arrivée ; relancer la suite ne suffit pas.

## Savoir ce qui est rouge

Chaque run de tests écrit la liste des échecs dans **`test/failed_tests.rb`** (un `fichier:ligne` par ligne, via le reporter `test/failed_tests_reporter.rb`). **Lire ce fichier directement** pour savoir ce qui est rouge, au lieu de relancer la suite pour le découvrir.

Pour rejouer ces seuls tests : **`bin/rails test:failed`** — jamais une commande bricolée à la main.

⚠ Le fichier est **vidé au démarrage** de chaque run et ne reflète donc que le **dernier** run : s'il est vide ou périmé, relancer `bin/rails test` pour le remplir, et le lire ensuite.
