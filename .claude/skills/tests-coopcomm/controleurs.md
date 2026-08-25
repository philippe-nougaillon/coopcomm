# Tests de contrôleurs — gabarit imposé

Un test de contrôleur vérifie **un seul contrat**, sur **une seule action** : l'action reçoit ces paramètres → le record est (ou n'est pas) modifié → on est redirigé au bon endroit, ou la bonne page est rendue. **Rien d'autre.** Dès qu'on enchaîne deux actions, c'est un test d'intégration : voir `integration.md`.

## Les cinq assertions

Toutes ne s'appliquent pas à chaque test, mais elles forment la liste dans laquelle on puise, et on n'en invente pas d'autres.

1. **La réponse aboutit** — `assert_response :success` pour un rendu, `assert_redirected_to` pour une redirection. Elle prouve du même coup que l'authentification est passée : un utilisateur non connecté serait redirigé. ⚠ Elle ne prouve **rien** sur le refus des autres — qui a le droit reste l'affaire des tests de policy ; ici on ne met en scène que des acteurs qui ont déjà le droit.
2. **La redirection mène à la bonne page** — jamais « quelque part ».
3. **La donnée du record est rendue** — son titre, sa description ou sa référence, dans la page ou dans la ligne du tableau, avec `assert_dom`. **Jamais le titre de la page** ni un intitulé de section : ce sont des libellés de gabarit, ils changent pour des raisons d'ergonomie et feraient tomber le test sans qu'aucun contrat soit rompu. Ce qu'on prouve, c'est que le bon enregistrement est arrivé jusqu'à la vue.
4. **L'alerte correspond à la situation** — le `flash[:notice]` ou `flash[:alert]` exact que l'action pose.
5. **L'état en base a changé, ou n'a pas changé** — avec un `reload` avant de lire.

**Requête AJAX** : ajouter `xhr: true`. Sans lui le contrôleur prend la branche HTML et le test couvre autre chose que ce qu'il annonce.

## Les trois actions courantes

**`show`** : on ouvre le show du record et on vérifie que la réponse aboutit, et que la donnée du record est là.

**`destroy`** : on supprime un record **valide**, on vérifie la redirection, et on prouve la suppression — `assert_difference('Record.count', -1)` pour une suppression réelle, `assert record.reload.discarded?` quand le modèle est en `discard`. ⚠ Se tromper de forme fait passer le test sans que rien ne soit supprimé.

**`update`** : on modifie le titre ou la description, on **recharge** le record, on vérifie la nouvelle valeur et la page d'arrivée.

## Fixtures du fichier

**Une fixture principale, posée dans le `setup`**, et des fixtures dérivées quand la situation l'exige (un acteur d'une autre organisation, un record dans un autre état). Une fixture utilisée **une seule fois** reste dans le test qui s'en sert ; dès qu'elle sert deux fois, elle remonte au `setup`.

## Un fichier par contrôleur

`test/controllers/<record>_controller_test.rb`, créé **même si le contrôleur est vide ou entièrement commenté** — il ne contient alors qu'une ligne de commentaire le disant.

⚠ **Rien de ce qui vient de Rails ou d'une gem ne se teste** (`mission_control_admin`, `service_worker`, les contrôleurs Devise de `app/controllers/users/`, eux-mêmes inutilisés) : c'est censé fonctionner.

**Dérive assumée** : `admin#create_new_user` et `admin#create_new_user_do` sont testés dans **`users_controller_test.rb`**, pas dans `admin_controller_test.rb`. Le fichier de test suit le **record** (`User`), pas la classe du contrôleur — la création d'utilisateur n'a été déportée dans `AdminController` que parce que Devise réserve `POST /users`. On reste ainsi ; **ne pas « corriger » ce cas**.

## Ordre du fichier

**L'ordre du fichier suit l'ordre du contrôleur** : les actions dans l'ordre où elles y sont écrites, tous les tests d'une action groupés (l'index et ses filtres d'abord si `index` est en tête, puis `show`, `new`+`create`, `edit`+`update`, `destroy`, puis les actions métier).

⚠ **Aucun mélange entre blocs ni entre fichiers** : un test du filtre Statut ne s'écrit pas dans le bloc des mots clés, et l'ordre des blocs de filtre suit celui de la méthode `filtrer` du contrôleur.

## Acteurs

**Tout se teste en administrateur.** On ne change d'acteur que lorsque la branche testée l'exige (`if current_user.manager?`, `unless agent?`…). Jamais un fichier par rôle : les tests de policy couvrent déjà « qui a le droit ».

**L'utilisateur non connecté ne se teste pas** — c'est l'affaire de Devise — **sauf quand il peut légitimement accéder** à l'action (pages publiques, formulaire d'inscription à la newsletter, lien de désinscription) : là on teste qu'il y accède bien.

## Ce qui se teste

**Le premier test d'une action est le nominal le plus dépouillé possible** — l'action appelée avec le minimum de paramètres, une seule assertion sur la réponse (`get messagerie_url` → `assert_response :success`). Les cas particuliers viennent après.

**Chaque action est testée**, y compris celles qui ne rendent que du JSON (`agents_for_service`, la météo de `pages`) — on y asserte le contenu du JSON. On ne teste **pas** les blocs `format.json` d'une action HTML, ni les actions commentées.

⚠ **Une action que personne ne peut atteindre ne se teste pas.** Route commentée ou absente du `only:`, ou **prédicat de policy écrit en dur à `false`** (`ConventionPolicy#edit?`, et `update?` qui en dérive) : l'action est fermée, aucun rôle n'y accède, et écrire un test « accès refusé » n'a pas de sens. Ni un test de refus, ni un test de non-écriture, ni une sentinelle. Quand la fonctionnalité rouvrira, les tests s'écriront à ce moment-là.
**Vérifier la policy AVANT de rédiger la matrice**, pas après : c'est elle qui dit quelles actions ont un contrat à couvrir.

**Chaque dérivé de l'action est testé** : toute condition écrite dans l'action donne son test, branches d'erreur comprises.

**Chaque méthode privée est testée via l'action qui l'appelle**, sauf `is_user_authorized` et `set_[record]`. On asserte la sortie sur les variables d'instance (`assigns(...)`, gem `rails-controller-testing`), **jamais sur le HTML**. Vigilance sur `set_form_[record]` : il doit sortir les bons services/utilisateurs (administrateur → toute l'organisation, sinon → les siens).

**`[record]_params`** : testé **uniquement là où les champs permis divergent** (un agent ne doit pas pouvoir ajouter de photos de demande, `:rôle` réservé à l'administrateur…). Pas de test sur les permits identiques pour tous les rôles.

**`set_[record]`** : un test **obligatoire** dans chaque contrôleur qui en a un — id ou slug inconnu → redirection propre avec message, jamais un 500.

**Index** : chaque filtre et chaque cas (paramètre absent, vide, multiple, inconnu, malformé). Ni `pagy` ni `trier` ne se testent.

**Workflow** : on teste **chaque transition** (elle aboutit, le record change d'état, la redirection est la bonne). On ne teste pas que chaque état × chaque action ne plante pas ; la logique de la gem `workflow` ne se teste pas ; un état posé à la main ne se teste que s'il l'est vraiment dans le code (`update_column`), ce qui ne devrait pas arriver.

**PDF / XLS** : seulement l'extension et le type MIME. Le contenu se teste au niveau du service (`TransformToPdf::*`, `ExportToXls::*`).

## Frontières

**On ne teste ni la vue, ni le modèle, ni les policies, ni les services.** Asserter **quels records** sont dans la réponse = contrôleur ; asserter **comment** ils sont affichés = test système.

Si une erreur tombe dans une action mais vient d'ailleurs (service, méthode de modèle), on **signale sans corriger** tant qu'on écrit les tests du contrôleur ; le garde-fou ira ensuite soit dans l'action, soit dans la classe fautive.

**Priorité absolue : les crashs atteignables par un utilisateur via l'interface.** Premier critère d'arbitrage.

**Hors périmètre** : `super_admin`, contrôleur `twilio`, cas de l'utilisateur désactivé, fonctions primaires renvoyant une chaîne (couleur, type, libellé), temps négatifs d'intervention (patchés par #462 → tests à retirer). **`health` reste testé** : c'est le plus important du lot, il compile toute l'application via `eager_load!`.

**Ce qui n'est pas un test de contrôleur vit ailleurs** : les 4 **matrices** d'intervention (caractérisation acteur × type × état) sont **conservées** ; les **dashboards** gardent leurs fichiers propres, séparés d'`admin_controller_test` ; `menus_deroulants_test` et `tris_test` passent en **tests système** ; `securite_regressions_test` est **dispatché** dans le fichier du contrôleur concerné (sinon on ne s'y retrouve plus).

## Nommage et constantes

**Nom d'un test** : une phrase qui énonce le comportement, cf. `SKILL.md` — et `commandes_controller_test.rb` comme référence. **Aucun commentaire**, sauf la ligne signalant un contrôleur vide ou désactivé.

**Constantes** : une constante **utilisée une seule fois n'existe pas** — on met sa valeur à l'endroit qui s'en sert. Utilisée plusieurs fois, elle se déclare **en haut du fichier, juste sous le `setup`**, avec un commentaire d'une ligne qui dit à quoi elle sert.
*Exception de bon sens : une table de données de plusieurs lignes qui pilote des tests générés (les 4 matrices, les listes de pages des sentinelles) reste une constante même utilisée une fois — l'inliner rendrait la méthode illisible.*
