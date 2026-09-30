# Tests de modèles — gabarit imposé

> Les règles transverses (nommage, commentaires, ordre, tests critiques, helpers, `skip`) sont dans `SKILL.md`. Ce fichier ne porte que ce qui est propre aux modèles.

Un test de modèle vérifie **le contrat du modèle lui-même** : ce que ses scopes ramènent, ce que ses validations refusent, ce que ses callbacks produisent, ce que ses méthodes renvoient. **Rien d'autre** — aucune requête HTTP, aucune vue, aucune policy.

C'est le niveau le plus proche du test unitaire : **un test = une logique d'une méthode**, sous la forme « avec ces entrées, cette méthode renvoie cela ». Une méthode qui a trois branches donne trois tests, pas un test qui les enchaîne.

## Un fichier par modèle

`test/models/<modèle>_test.rb`, créé **même si rien n'est testable** — il ne contient alors qu'une ligne de commentaire le disant.

## Ordre du fichier

L'ordre suit celui du modèle (règle transverse) : scopes, puis `validates`, puis les callbacks `before_*` dans leur ordre de déclaration, puis les `after_*`, puis les méthodes de classe et d'instance.

## Ce qui se teste

**Les scopes** : que le scope ramène **exactement** les enregistrements voulus, nommés (règle transverse des assertions).

**`visible_to`** se teste **ici**, jamais dans le test de policy (voir `policies.md` pour ce qui reste à la charge du `Scope`).

**Les validations écrites à la main** (`validate :une_méthode`), et **chacune de leurs variantes** : chaque paramètre qui peut faire basculer la règle (rôle de l'acteur, état de workflow, présence d'une date, appartenance à un service…) a son test — le cas qui passe et le cas qui est refusé.

**Tous les `before_*` et `after_*`** : que le callback produit bien l'effet demandé. Quand il notifie, on asserte que **le job est mis en file** (`assert_enqueued_with`), pas le contenu du mail — c'est l'affaire du test du job et du mailer, qui n'ont pas de gabarit imposé.

**Chaque méthode et chacune de ses dérivées**, condition par condition dans l'ordre du code.

## Ce qui ne se teste pas, en plus des trois familles transverses

⚠ **Sauf si cela touche au modèle `Service`** — cette règle prime sur toute la liste ci-dessous.

- les **enums** et les **relations** (`belongs_to`, `has_many`, `has_one`, `through`…) ;
- **`triable_par`** et les colonnes triables ;
- les **audits écrits par la gem**. ⚠ Seule exception : un audit **écrit à la main** par notre code (`audit_comment` posé par `PieceJointeAuditable` pour les pièces jointes) — là c'est notre contrat, il se teste, **dans le fichier du modèle concerné** ;
- les **validations déclaratives de Rails**, sauf quand leur **portée** est une décision à nous (l'unicité d'un nom d'outil **par organisation**) ;
- les méthodes qui ne renvoient qu'une **chaîne écrite en dur** — regex, libellé (`Message#bad_words_regex`). ⚠ Deux exceptions : une méthode qui **compose** une valeur se teste (`User#nom_prénom`), et une **couleur qui distingue des états à l'écran** (styles de badges et de boutons du workflow) se fige, parce qu'une couleur fausse fait lire un mauvais état.

## Concerns

Un concern de modèle a **son propre fichier** dans `test/models/concerns/<concern>_test.rb` — jamais à la racine de `test/models/`. Il ne couvre que ce qui est **propre au concern**, indépendamment du modèle qui l'inclut.

⚠ Un concern dont le comportement ne s'observe **que** sur un modèle donné n'a **pas** de fichier : ses tests vivent dans les fichiers des modèles concernés, **un cas par modèle et jamais deux fois le même** — `PieceJointeAuditable` est de ceux-là (le `has_one` se constate sur `Tool`, le `has_many` sur `Intervention`).

## Fichiers séparés à conserver

Les **conflits de disponibilité** d'`Intervention` gardent **un fichier par cas** (`intervention_conflit_agent_matrix_test.rb`, `intervention_conflit_outil_matrix_test.rb`, `intervention_conflit_dates_partielles_test.rb`) : **ne pas les fusionner** dans `intervention_test.rb`, ni entre eux.

## Fixtures

Voir `fixtures.md`.
