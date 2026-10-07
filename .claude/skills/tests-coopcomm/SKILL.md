---
name: tests-coopcomm
description: Conventions et gabarits imposés des tests du projet (Minitest, Rails, Pundit, Capybara). À lire AVANT d'écrire, de modifier ou de relire un test — test de policy, de contrôleur, de modèle, de job, de service ou système — ainsi que pour ajouter une fixture, marquer un test critique, placer un helper de test, ou rejouer les tests échoués.
---

# Tests — CoopComm

**Minitest** (`test/`, fixtures dans `test/fixtures/`), tests système Capybara + Selenium, couverture SimpleCov.

**Exigence : tout ce qui peut être testé doit l'être.** L'objectif n'est pas seulement d'éviter les mauvaises surprises, mais de forcer une réflexion sur les cas limites — un test difficile à écrire révèle souvent une décision de conception à prendre.

**Ce fichier porte les règles transverses** : elles valent pour **tous** les types de tests. Les fichiers d'aiguillage ne portent que ce qui leur est propre, et ne redisent une règle transverse que lorsqu'ils y **dérogent**.

## Aiguillage

| Ce que j'écris | Où sont les règles |
|---|---|
| Test de **policy** Pundit | `policies.md` — gabarit imposé, à lire en entier |
| Test de **contrôleur** (une action) | `controleurs.md` — gabarit imposé, à lire en entier |
| Test d'**intégration** (plusieurs actions enchaînées) | `integration.md` — gabarit imposé, à lire en entier |
| Test de **modèle** (ou de concern de modèle) | `modeles.md` — gabarit imposé, à lire en entier |
| Test d'**objet de service** (`app/services/`) | `services.md` — gabarit imposé, à lire en entier |
| Test **système** (parcours navigateur) | `systeme.md` — gabarit imposé, à lire en entier |
| Ajout ou choix d'une **fixture** | `fixtures.md` |
| Test de **job**, de **mailer**, de **helper**, de **tâche rake**, de **souscription**, de **canal**, de **mailbox**, de **markdown**, de **concern de contrôleur** | **Aucun gabarit imposé** — appliquer les règles transverses ci-dessous, et le gabarit du type le plus proche (un helper se teste comme un modèle, une tâche rake comme un objet de service). **Ne pas en inventer un.** |

⚠ **Homonymie à ne jamais confondre** : le **modèle `Service`** (le service d'une commune, racine du cloisonnement) n'a rien à voir avec un **objet de service** (`app/services/`). La règle « tout ce qui touche aux services est critique » ci-dessous vise le **modèle** ; `services.md` vise les **objets de service**.

## Hiérarchie : contrôleur < intégration < système

Trois niveaux, du moins cher au plus cher. **Un comportement ne se teste qu'à un seul.**

| Niveau | Ce qu'il couvre |
|---|---|
| **Contrôleur** | chaque cas particulier d'**une** action : ce que la machine doit faire, et ce qu'elle doit refuser |
| **Intégration** | un parcours utilisateur, mais toujours dans la couche contrôleur (`get`, `post`, `assert_dom`) : **plusieurs actions enchaînées** — créer une intervention → la voir dans l'index → la terminer |
| **Système** | les parcours utilisateurs **critiques**, et uniquement ce qui n'est testable à aucun des deux niveaux inférieurs : le JavaScript, la CSS, le clic réel |

**La règle de décision, dans cet ordre :** ça tient dans une seule action → contrôleur. Il faut enchaîner des actions → intégration. Il faut un navigateur → système.

**Jamais deux niveaux pour la même chose.** Un test système qui refait ce qu'un test de contrôleur prouve déjà se supprime, il ne se garde pas « au cas où » : il coûte **25 fois plus cher** (0,85 test/s contre 21), il flake, et le jour où le comportement change il faut corriger deux endroits.

Deux frontières souvent ratées :

- **Un lien qui ne fait que naviguer** se prouve en **intégration** (son `href`, puis la réponse de la destination), jamais en système : on ne clique en système que lorsque le clic **change l'état d'un enregistrement**.
- **Les messages d'erreur d'un formulaire** (`#error_explanation`) se vérifient en **système**, et on y asserte **chacun des messages** de la div, pas seulement sa présence. Le **refus** lui-même (statut 422, état inchangé en base) reste au niveau **contrôleur** : les deux ne se recouvrent pas.

## Nommage des tests

**Le nom d'un test est une phrase qui énonce un comportement.** Pas une coordonnée technique (`update : intitulé vide → 422`), mais une règle du domaine, lisible par quelqu'un qui ne connaît pas le code :

```ruby
test 'une commande est affichée avec succès'
test 'une commande est archivée lorsqu’elle est supprimée'
test 'la recherche dans la liste ne retourne que les commandes correspondantes'
test 'une commande à l’état envoyé peut être validée'
```

Le nom ne s'adresse pas au lecteur et ne raconte pas le décor : les formules « de son périmètre », « qu'il gère », « auquel il a droit » disparaissent — le contexte est dans le corps du test. **Exception** : le mot « périmètre » reste quand le test porte précisément dessus (un paramètre forgé hors périmètre, un résultat borné au périmètre).

**Une seule dérogation : les tests d'intégration et système**, qui partagent la même forme — une **user story**, parce qu'ils rejouent un parcours et non un contrat :

```ruby
test "En tant qu'administrateur, je veux créer un adhérent depuis la page d'accueil"
```

Les tests de **policy** ont une formule contrainte (`accès interdit pour un adhérent sur une convention d'un autre titulaire`) : c'est une **spécialisation** de la règle générale, pas une dérogation — voir `policies.md`.

**Tout le dépôt est à cette forme depuis le 2026-10-01.** Un nom non conforme rencontré dans un fichier qu'on touche se convertit au passage, même si on ne modifiait pas ce test.

**Chaque chose porte son nom, et un seul.** Aucune ambiguïté dans les noms de tests, les messages d'assertion, les variables et les commentaires : trois objets voisins se confondent sans arrêt, alors qu'ils n'ont rien à voir.

| L'objet | Son nom | Jamais |
|---|---|---|
| `MailLog` | un **mail log** | une notification, une alerte, un mail envoyé |
| `Message` (messagerie) | un **message** | une notification, une alerte, un mail |
| Le bandeau de flash à l'écran | une **notification** ou une **alerte** (le toast) | un message, un mail |

La règle vaut au-delà de ces trois : on désigne un objet par son nom, pas par un synonyme de circonstance.

## Ce qui ne se teste jamais

⚠ **Sauf si cela touche au modèle `Service`** — la règle ci-dessous prime sur toutes les exclusions de ce fichier et des fichiers d'aiguillage.

**Tout ce qui touche aux services se teste, et c'est critique.** Le rattachement aux services est la racine du système : l'organisation, le périmètre de visibilité, les listes d'agents et le cloisonnement entre communes en dérivent tous. Validation, rattachement, filtre, périmètre, dérivation d'organisation — chacun a son test, marqué critique. Un test de services ne se supprime pas parce qu'il porte sur une validation déclarative, une relation ou un audit de la gem.

Cela posé, **trois familles ne se testent jamais** :

1. **Ce qui vient de Rails ou d'une gem** — c'est censé fonctionner. Validations déclaratives, relations, enums, états de la gem `workflow`, audits écrits par `audited`, contrôleurs Devise, `mission_control_admin`, `service_worker`. Seule une contrainte dont la **portée** est une décision à nous se teste (l'unicité d'un nom d'outil **par organisation** dit le cloisonnement multi-organisations, pas l'unicité) ; les listes précises sont dans chaque fichier d'aiguillage.
2. **Ce qui est commenté** — méthode, action, route, transition ou bloc mis en commentaire : aucun test, d'aucune sorte, ni de refus, ni de non-régression, ni de sentinelle. Vaut aussi pour ce qui est **inatteignable** : route absente du `only:`, prédicat de policy écrit en dur à `false`. Le jour où la fonctionnalité rouvre, les tests s'écrivent à ce moment-là.
3. **Le code mort**, signalé dans la source par `# Classe inutilisée` / `# Fonction inutilisée`.

## Ordre du fichier

**L'ordre du fichier de test suit l'ordre du fichier source** : les éléments dans l'ordre où ils y sont écrits, tous les tests d'un même élément groupés. **Une condition à la fois, dans l'ordre du code** : C1, puis C2, puis C3 — jamais dans le désordre.

⚠ **Aucun mélange entre blocs ni entre fichiers** : un test du filtre Statut ne s'écrit pas dans le bloc des mots clés, un test de validation ne s'écrit pas dans le bloc d'un callback.

**Un nouveau test se place en dernier dans son groupe**, jamais au milieu ni en tête (règle générale du projet, `CLAUDE.md` §2).

Seuls les tests de **policy** ordonnent par situation plutôt que par ordre du code — voir `policies.md`.

**Déplacer du test, c'est déplacer son voisinage** (`CLAUDE.md` §2) : après tout déplacement outillé de méthode, de test, de bloc ou de constante, relire le voisinage du point de départ **et** du point d'arrivée ; relancer la suite ne suffit pas.

## Assertions

**On asserte toujours les enregistrements réellement reçus, nommés** — jamais « une relation est revenue », jamais un simple compte. C'est la seule assertion qui tombe si quelqu'un remplace un filtre par `scope.all`.

**Jamais le titre de la page** ni un intitulé de section dans un `assert_dom` : ce sont des libellés de gabarit, ils changent pour des raisons d'ergonomie et feraient tomber le test sans qu'aucun contrat soit rompu. Ce qu'on prouve, c'est que le bon enregistrement est arrivé jusqu'à la vue.

**Aucune assertion tordue pour faire passer un test.** Voir « `skip` » ci-dessous.

## Commentaires

**Aucun commentaire dans un fichier de test.** Le nom du fichier et celui de chaque test doivent suffire. Les précisions sur une fixture passent par le **nom de la variable** (`convention_autre_org`, `service_supprimable`), pas par un commentaire.

**Quatre exceptions, et rien d'autre :**

1. une **ligne en tête de fichier** quand la raison d'être du fichier ne se devine pas (typiquement un test d'intégration transverse), ou pour dire qu'un fichier est **vide faute de quoi que ce soit à tester** ;
2. le **commentaire d'un helper privé**, collé à lui ;
3. le **commentaire d'une constante** réutilisée (voir `controleurs.md`) ;
4. la **bannière des tests critiques** ci-dessous.

## Tests critiques — marqueur ET bannière

*(vaut pour tous les types de tests, **sauf** les tests système)*. Les deux sont obligatoires et ne se remplacent pas :

1. **Chaque** test critique porte le marqueur **à la fin de son nom**, entre parenthèses, après la phrase de comportement. **Aucune exception**, y compris pour un test généré dans une boucle (le marqueur va dans la chaîne interpolée) et pour un test déjà entouré d'une bannière.

```ruby
test 'le prix de ligne forgé dans les paramètres laisse la commande inchangée (critique)'
```

2. Les tests critiques qui se suivent sont **groupés et encadrés** par exactement ces deux lignes, avec **une ligne vide avant la fermeture** pour ne pas la coller au dernier test :

```
# ==================== TESTS CRITIQUES ====================
# (le commentaire d'explication reste : il dit pourquoi ces tests sont critiques)
# ==================== /TESTS CRITIQUES ====================
```

*Pourquoi les deux* : la bannière explique **pourquoi** le groupe est critique et se lit dans le fichier ; le marqueur voyage avec le test — dans la sortie d'un run, dans `test/failed_tests.rb`, dans un rapport de couverture — là où la bannière est invisible. Un test critique déplacé hors de son groupe garde ainsi son statut.

Plusieurs blocs par fichier sont normaux — chacun vit auprès de ce qu'il vise. Un test critique isolé porte son marqueur **sans** bannière si aucun autre ne le rejoint.

**Est critique** : tout ce qui touche au modèle `Service` (voir plus haut), tout ce qui touche à l'argent, et le cloisonnement multi-organisations. `services.md` détaille la liste propre aux objets de service.

## Helpers, constantes et `private`

**Un helper utilisé par un seul fichier** vit sous `private`, en fin de classe, avec le commentaire qui l'explique collé à lui. **Utilisé par plusieurs fichiers**, il devient un module de `test/support/` que les fichiers `require_relative` et `include` — comme `fabrique_xls.rb`, `interventions_matrice.rb` et `lecture_pdf.rb` qui s'y trouvent déjà. Les helpers des tests **système** vivent dans `test/application_system_test_case.rb`.

**Le nom d'un helper dit ce qu'il rend**, pas ce qu'il fait en général — `dashboard_manager_xls` et `dashboard_manager_xls_vide` plutôt que `export` et `export_vide`, `lire_fichier_xls` plutôt que `lire`. Un fichier de test se lit sans remonter à la définition du helper.

**Pas de `**options` ni d'argument générique dans un helper de test** : le helper reproduit un appel que l'application fait vraiment, avec ses valeurs. Le test qui exerce une variante appelle explicitement, en écrivant l'option sur place — sinon on ne voit plus, en lisant le test, ce qui est réellement passé.

⚠ **`private` clôt la classe** (`CLAUDE.md` §2) : après `private`, rien d'autre que des méthodes privées. Jamais une constante, jamais un `test` — il reste collecté par Minitest, personne ne le voit passer, et le relecteur est trompé.

⚠ **Aucune classe déclarée dans un fichier de test.** Pas de sous-classe de circonstance (`class ImportQuiEchoue < ImportUtilisateursXls`) : elle est chargée par toute la suite, hors de sa portée. Ce qu'il faut à sa place, dans l'ordre de préférence : provoquer le cas par les **données** ; sinon un `stub` posé **dans le test qui en a besoin** ; en dernier recours seulement, une fabrique sous `private`.

## Cibler un élément : `data-testid`

**Uniquement dans les tests système**, et seulement quand l'élément **n'affiche pas de texte ciblable** (bouton à icône seule, libellé masqué à la largeur testée). Partout ailleurs on cible par le texte que l'utilisateur voit.

Ajouter un `data-testid` dans une vue est la **seule** modification de production autorisée pendant une session de tests : l'attribut est **inerte**, il vaut mieux que le sélecteur CSS/XPath fragile qu'il remplace. On l'écrit **en tout dernier attribut** de l'élément, et on **signale les vues touchées** dans le compte rendu. Toute autre modification de production reste **signalée, non appliquée**.

## `skip` : un point à trancher, rien d'autre

**On écrit le test en entier, et un test qui ne passe pas reste rouge** — c'est son travail de dire que l'application est cassée, et c'est à l'équipe de surveiller ce qui clignote. Jamais un `skip`, jamais une assertion affaiblie pour retrouver le vert.

**`skip` est réservé à une décision métier en attente** : le comportement attendu n'est pas tranché, on ne devine pas. Le message dit **ce qu'il faut trancher**.

⚠ **Jamais de `skip` pour un pré-requis absent** (variable d'environnement, fixture, fichier, ligne en base). On l'**asserte**, pour que la situation fasse tomber le test au lieu de l'escamoter :

```ruby
assert File.exist?(image), "fixture manquante : #{image}"
assert_not_nil agent, 'aucun agent supprimé dans les fixtures'
```

Une variable d'environnement lue par du code de production se **pose par le test qui en a besoin, et se restaure** (`CLAUDE.md` §3) : héritée de `.env`, elle marche en local et casse en CI.

`flunk` existe dans le dépôt pour signaler un manque de l'application (« le graphe n'existe pas sur le tableau de bord ») : **c'est l'outil de l'équipe, l'agent ne l'écrit pas.**

## Savoir ce qui est rouge

Chaque run de tests écrit la liste des échecs dans **`test/failed_tests.rb`** (un `fichier:ligne` par ligne, via le reporter `test/failed_tests_reporter.rb`). **Lire ce fichier directement** pour savoir ce qui est rouge, au lieu de relancer la suite pour le découvrir.

Pour rejouer ces seuls tests : **`bin/rails test:failed`** — jamais une commande bricolée à la main.

⚠ Le fichier est **vidé au démarrage** de chaque run et ne reflète donc que le **dernier** run : s'il est vide ou périmé, relancer la suite pour le remplir, et le lire ensuite.

**La suite complète, c'est `bundle exec rails test:all`** (tests système inclus) — `bin/rails test` les laisse de côté. Un fichier : `bin/rails test test/models/intervention_test.rb`.

⚠ **Jamais deux runs simultanés sur la même base**, et **jamais un run en arrière-plan** : contamination des fixtures, deadlock `REFRESH MATERIALIZED VIEW`, rembobinage de séquence. Un seul run à la fois, au premier plan, après avoir vérifié `ps`.
