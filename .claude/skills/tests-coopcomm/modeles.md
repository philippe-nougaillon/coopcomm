# Tests de modèles — gabarit imposé

Un test de modèle vérifie **le contrat du modèle lui-même** : ce que ses scopes ramènent, ce que ses validations refusent, ce que ses callbacks produisent, ce que ses méthodes renvoient. **Rien d'autre.**

## Un fichier par modèle

`test/models/<modèle>_test.rb`, créé **même si rien n'est testable** — il ne contient alors qu'une ligne de commentaire le disant, comme pour un contrôleur vide.

## Ordre du fichier

**L'ordre du fichier suit l'ordre du modèle**, exactement comme un test de contrôleur suit son contrôleur : les éléments dans l'ordre où ils y sont écrits, tous les tests d'un même élément groupés — scopes, puis `validates`, puis les callbacks `before_*` dans leur ordre de déclaration, puis les `after_*`, puis les méthodes de classe et d'instance.

⚠ **Aucun mélange entre blocs** : un test d'une validation ne s'écrit pas dans le bloc d'un callback, et deux callbacks ne s'entrelacent pas.

## Ce qui se teste

**Les scopes** : que le scope ramène **exactement** les enregistrements voulus — les records attendus nommés, pas seulement leur nombre.

**`visible_to`** se teste **ici**, jamais dans le test de policy (voir `policies.md` pour ce qui reste à la charge du `Scope`).

**Les validations écrites à la main** (`validate :une_méthode`), et **chacune de leurs variantes** : chaque paramètre qui peut faire basculer la règle (rôle de l'acteur, état de workflow, présence d'une date, appartenance à un service…) a son test — le cas qui passe et le cas qui est refusé.

**Tous les `before_*` et `after_*`** : que le callback produit bien l'effet demandé. Quand il notifie, on asserte que **le job est mis en file** (`assert_enqueued_with`), pas le contenu du mail — c'est l'affaire du test du job et du mailer.

**Chaque méthode et chacune de ses dérivées**, condition par condition dans l'ordre du code (règle transverse de `SKILL.md`).

## Ce qui ne se teste pas

Une seule liste, à jour :

- les **audits écrits par la gem** — qu'une modification de colonne laisse une trace est l'affaire d'`audited`. ⚠ Seule exception : un audit **écrit à la main** par notre code (`audit_comment` posé par `PieceJointeAuditable` pour les pièces jointes) — là c'est notre contrat, il se teste, **dans le fichier du modèle concerné** ;
- les **validations déclaratives de Rails** (`presence: true`, `uniqueness: true`, `numericality`…) — c'est le framework. Seule une contrainte dont la **portée** est une décision à nous se teste (l'unicité d'un nom d'outil **par organisation** dit le cloisonnement multi-organisations, pas l'unicité) ;
- les **relations** (`belongs_to`, `has_many`, `has_one`, `through`…) ;
- les **enums** ;
- **`triable_par`** et les colonnes triables ;
- les **états de workflow** — c'est la logique de la gem `workflow` ;
- tout ce qui est **commenté** (règle transverse) ;
- les méthodes qui ne renvoient qu'une **chaîne écrite en dur** — regex, libellé (`Message#bad_words_regex`). ⚠ Deux exceptions : une méthode qui **compose** une valeur se teste (`User#nom_prénom`), et une **couleur qui distingue des états à l'écran** (styles de badges et de boutons du workflow) se fige, parce qu'une couleur fausse fait lire un mauvais état ;
- le **code mort**, signalé dans la source par `# Classe inutilisée` / `# Fonction inutilisée` (`User.from_omniauth`, `Users::OmniauthCallbacksController` : Devise `:omniauthable` est désactivé).

## Concerns

Un concern de modèle a **son propre fichier** dans `test/models/concerns/<concern>_test.rb` — jamais à la racine de `test/models/`. Il ne couvre que ce qui est **propre au concern**, indépendamment du modèle qui l'inclut.

⚠ Un concern dont le comportement ne s'observe **que** sur un modèle donné n'a **pas** de fichier : ses tests vivent dans les fichiers des modèles concernés, **un cas par modèle et jamais deux fois le même** — `PieceJointeAuditable` est de ceux-là (le `has_one` se constate sur `Tool`, le `has_many` sur `Intervention`).

## Fichiers séparés à conserver

Les **conflits de disponibilité** d'`Intervention` gardent **un fichier par cas** (`intervention_conflit_agent_matrix_test.rb`, `intervention_conflit_outil_matrix_test.rb`, `intervention_conflit_dates_partielles_test.rb`) : **ne pas les fusionner** dans `intervention_test.rb`, ni entre eux.

## Nommage

`<élément testé> : <situation> → <effet>` — **même formule que les tests de contrôleurs**. Ex. : `calc_temps_total : pause supérieure à la durée → refusé`, `scope ordered : deux services → tri sans accent ni casse`.

**Aucun commentaire**, sauf la ligne signalant un modèle sans rien de testable.

## Fixtures

Voir `fixtures.md`. Rappel : quand aucune fixture ne porte l'attribut nécessaire, **on en ajoute une** plutôt que de muter une fixture existante dans le test.
