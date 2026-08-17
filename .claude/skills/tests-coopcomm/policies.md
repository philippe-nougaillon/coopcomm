# Tests de policies — gabarit imposé

Un fichier par couple **rôle × ressource** : `test/policies/<rôle>/<rôle>_<ressource>_policy_test.rb`.

## Setup

La fixture `user` porte le rôle testé, puis les fixtures de record, puis une policy dérivée par situation — `@policy` (cas nominal), `@policy_autre_org`, `@policy_autre_service`, `@policy_user_myself`… **Rien d'autre dans le setup.**

## Structure des tests

**Un test = un bloc d'autorisations homogène** : que des `assert`, ou que des `refute`, jamais les deux dans le même test.

**Nom du test** = `accès ` + `autorisé`|`interdit` + ` pour un ` + rôle + ` sur un(e) ` + type de record + spécificité éventuelle.
Ex. : `accès interdit pour un administrateur sur une convention d'une autre organisation`.
**Aucun nom d'action dans le titre** — c'est le bloc qui les regroupe.

**Trois familles de blocs, jamais mélangées.** Une action de route mène à une page ; un prédicat d'affichage ou de saisie ne pilote qu'un morceau de page :

| Préfixe | Ce qu'il couvre |
|---|---|
| `accès …` | les **routes** |
| `affichage …` | les blocs de la page (`voir_*`) |
| `saisie …` | les champs du formulaire (`saisir_*`, `choisir_*`, `planifier_*`…) |

Même formule de nom, seul le premier mot change (`affichage autorisé pour un administrateur sur une intervention de son organisation`).

**Les deux blocs (autorisé + interdit) sont répétés pour chaque situation** testée : même organisation, autre organisation, autre service, soi-même, rôle de la cible… Un bloc qui n'aurait aucune assertion vraie ne s'écrit pas.

## Périmètre

**On ne teste QUE les prédicats écrits dans le fichier de policy du record.** Ni les défauts hérités d'`ApplicationPolicy` que la policy ne redéfinit pas (`edit?` sur `CommandePolicy`, `new?`/`create?` sur `FacturePolicy`…), ni ceux qu'elle a **mis en commentaire** (`ServicePolicy#index?`). Un fichier qui n'aurait qu'un seul bloc est normal.

⚠ Une action **qui ne regarde pas le record** (`index?`, `new?`, `create?` quand ils ne dépendent que du rôle) n'appartient qu'au **bloc nominal** : hors de lui il n'y a pas d'organisation précise à opposer, donc l'y inscrire n'a aucun sens — et rend le test faux.

**Un fichier = UN rôle × UN record**, jamais deux rôles dans le même fichier (un rôle sans aucun droit a droit à son propre fichier).

**Rester simple** : on teste uniquement « ce rôle a-t-il le droit sur ce record », rien d'autre. Aucune écriture en base, aucune assertion métier, aucun parcours contrôleur dans ces fichiers.

## Ordre du fichier

nominal → variantes d'état ou de type du record → autre service → autre organisation → cas particuliers → **scope**.

**Le scope en dernier, et seulement s'il filtre vraiment** (`visible_to`, `where(organisation:)`…) — un scope pass-through (`resolve = scope`) ne se teste pas. Nom **explicite** : `scope : un <rôle> ne voit que <ce qu'il voit>`, ou `scope : un <rôle> ne voit aucune <ressource>` quand il ne voit rien.
