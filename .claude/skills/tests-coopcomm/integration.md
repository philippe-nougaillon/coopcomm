# Tests d'intégration — gabarit imposé

Un test d'intégration rejoue un **parcours utilisateur**, mais au niveau HTTP : une suite de `get` et de `post`, comme un test de contrôleur, sauf qu'il en enchaîne plusieurs.

Il vit dans `test/integration/`, sur la même classe qu'un test de contrôleur (`ActionDispatch::IntegrationTest`). La différence n'est donc pas technique, elle est de **portée** : une action contre une chaîne d'actions.

## Ce qu'il apporte, et lui seul

**La transition.** Ce qui survit d'une requête à la suivante : la redirection mène-t-elle où l'on croit, le flash y est-il affiché, le record créé apparaît-il vraiment dans l'index qu'on ouvre ensuite, la session est-elle toujours là.

C'est tout. Chaque action prise isolément est déjà couverte par son test de contrôleur.

⚠ **Ne pas redérouler la matrice du contrôleur.** Tous les filtres d'un index, toutes les branches d'erreur d'un `create` : ça se teste **une fois**, au niveau contrôleur. Le refaire ici crée deux endroits à maintenir, qui divergeront.

**Un test de contrôleur qui couvre déjà une transition n'a rien à faire dans `test/controllers`** : on le déplace ici plutôt que d'en écrire un second.

## Ce qui se teste

Le parcours **de création** d'un record avec ses dérivés, et le parcours **de consultation** de son index avec les siens :

```
je crée → je suis redirigé sur le record → sa donnée est là, le flash aussi
        → j'ouvre l'index → il y figure
```

## Assertions

Les mêmes que pour un contrôleur (`controleurs.md`), à chaque étape de la chaîne : la réponse aboutit, la redirection mène à la bonne page, la **donnée du record** est rendue (`assert_dom`, jamais le titre de la page), le flash porte le bon message, l'état en base a changé.

`follow_redirect!` entre deux étapes : sans lui on asserte sur la réponse 302, qui ne contient rien.

## Nommage

`test/integration/<parcours>_test.rb` — le nom du fichier dit le parcours, pas le contrôleur : `invitation_utilisateur_test.rb`, `formulaires_conservent_la_saisie_test.rb`.

Le nom d'un test est une phrase qui énonce le comportement (règle transverse de `SKILL.md`).

## Fixtures

Une fixture principale dans le `setup`, des dérivées au besoin — même règle que pour les contrôleurs.
