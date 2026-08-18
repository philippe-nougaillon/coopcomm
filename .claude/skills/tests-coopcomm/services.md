# Tests de services — gabarit imposé

Un test de service vérifie **ce que le service renvoie**, pas comment il s'y prend. Les services du projet font trois choses : produire un fichier (`ExportToXls::*`, `TransformToPdf::*`), interroger une API tierce (`MeteoConceptConnexion`, `FetchRoutesInfos`, `FetchMailgunInfos`, `FetchTwilioInfos`), ou écrire en base (`ImportUtilisateursXls`, `CreateCommandeFromCotation`, `CreateFactureFromCommande`).

## Un fichier par classe de service

`test/services/<répertoire>_<fichier>_test.rb` — le répertoire, s'il y en a un, puis `_`, puis le nom du fichier source, puis `_test.rb`. **Jamais le mot `service` en plus.**

| Source | Fichier de test |
|---|---|
| `app/services/export_to_xls/agents.rb` | `test/services/export_to_xls_agents_test.rb` |
| `app/services/transform_to_pdf/base_pdf_for_crm.rb` | `test/services/transform_to_pdf_base_pdf_for_crm_test.rb` |
| `app/services/fetch_routes_infos.rb` | `test/services/fetch_routes_infos_test.rb` |

**Une classe de service = un fichier de test.** Deux services jumeaux (`DashboardManager` et `DashboardAdherent`, `Cotation`/`Commande`/`Facture`) ne partagent pas un fichier : ils ont chacun le leur, avec **exactement les mêmes tests**, pour que l'écart entre deux jumeaux se voie au diff.

## Ordre du fichier

1. **`initialize`** — uniquement s'il fait quelque chose (rejet d'un argument, dérivation, valeur par défaut). ⚠ **On ne teste pas qu'`initialize` range ses arguments dans les bonnes variables d'instance** : c'est du Ruby pur, pas notre contrat. Un `assert_equal @service.instance_variable_get(:@agents), @agents` ne s'écrit pas.
2. **`call`** et toutes ses branches — c'est le cœur du fichier : **ce que ça renvoie**, pas que ça ne lève pas.
3. **Les autres fonctions**, dans l'ordre du code, et seulement celles qui relèvent des trois exceptions ci-dessous.

## Faut-il tester chaque fonction, ou seulement `call` ?

**Par défaut, seulement `call`** : c'est le seul point d'entrée réel, et une erreur d'une fonction interne y remonte. Tester chaque fonction privée fige la découpe interne — un remaniement qui ne change aucun comportement fait alors tomber la suite, et la couverture donne une fausse assurance.

**Trois exceptions**, où l'on va directement à la fonction :

- **inatteignable ou hors de prix depuis `call`** — la charge utile d'un QRCode ne se lit ni dans le texte du PDF ni dans l'image ; les méthodes de `ExportToXls::Base` n'ont pas de `call` du tout ;
- **branche dont le résultat n'est pas visible** dans la valeur de retour — typiquement un `rescue` qui avale, ou un compteur interne ;
- **fonction de calcul pur à nombreux cas** (`get_icon_meteo`) — passer par `call` obligerait à refabriquer une réponse d'API complète à chaque cas.

## Fichiers produits (XLS et PDF) — ce qui se teste

Ni « tout le contenu », ni « le minimum qui prouve que rien n'a planté ». Trois niveaux, dont on prend ce que le service justifie :

1. **Le fichier est relisible par son parseur** (`Spreadsheet.open`, `LecturePdf#texte_pdf`). Nécessaire, **jamais suffisant** : un classeur vide est relisible lui aussi.
2. **La forme** — nombre de lignes (`données + 1` pour l'en-tête) et nombre de colonnes, avec 0 donnée puis avec plusieurs. Attrape la ligne oubliée, le décalage, la colonne conditionnelle. **L'ordre des en-têtes ne se teste pas.**
3. **Le contenu**, mais **uniquement les valeurs calculées, transposées, jointes ou filtrées** — un total, une somme, une transposition, une colonne masquée selon le rôle. Une valeur simplement recopiée d'un attribut n'apprend rien : `agent.nom` dans une cellule ne peut pas être faux autrement qu'en étant dans la mauvaise colonne.

⚠ **On n'asserte pas « chaque donnée apparaît »** : une cellule **témoin** par export suffit, et elle prouve ce que le compte de lignes ne prouve pas — que les données sont écrites dans la bonne colonne.

Pour un PDF, le niveau 2 n'a pas d'équivalent : ce sont les niveaux 1 et 3, et le niveau 3 y est obligatoire dès que le document porte de l'argent (un total imprimé à deux endroits se compte aux deux, un document qui s'auto-contredit sur son montant est le pire des cas).

## Services appelant une API tierce

**La requête se mocke, jamais le client.** `stub_request` (WebMock), avec la réponse rangée dans `test/fixtures/files/` — comme `responseMeteoConcept.json` et `responseRoutesInfos.json`. Stubber `Mailgun::Client.new` ou `Twilio::REST::Client.new` ne teste plus rien du service : ni l'URL appelée, ni les en-têtes, ni le décodage de la réponse.

- Le **chemin nominal** est stubé une fois pour toutes dans le `setup` de `test_helper.rb`, pour que toute la suite en profite.
- Les **cas particuliers** (API injoignable, réponse en erreur, corps illisible, réponse tronquée) redéclarent leur propre `stub_request` dans le test qui les vise.
- **Chaque service d'API a au moins un test « l'API tombe et l'utilisateur ne le voit pas »**, marqué critique : ces services décorent des pages que rien ne doit faire tomber. C'est le test le plus rentable du fichier.
- La réponse mise en fixture est **écrite à la main**, réduite aux champs que le service lit réellement. On ne capture une réponse réelle que si la forme ne se déduit pas du code — et alors elle est **relue et expurgée** avant d'être commitée : clé d'API, jeton, identifiant de compte, adresse et numéro de téléphone réels n'ont rien à y faire, le dépôt est candidat à l'open-source.

⚠ `WebMock.disable_net_connect!` ne garantit rien tant qu'on stube le **client** : aucune requête n'étant émise, WebMock n'a rien à intercepter et l'URL appelée n'est vérifiée par personne.

## Services qui écrivent en base

Ce qui se teste, en plus de la valeur de retour : ce qui est **réellement en base** après l'appel (et **rien** en mode simulation), les lignes refusées, et le fait qu'un refus **ne laisse rien derrière lui**.

⚠ **Les audits ne se testent pas ici** — même règle que pour les modèles : la trace laissée par la gem est l'affaire d'`audited`.

⚠ **Un changement de rôle ne se teste pas ici** : c'est le contrat de `User`, il se teste dans `test/models/user_test.rb`. Le service teste que la ligne est refusée, pas ce que le rôle devient.

## Frontière avec le test de contrôleur

Le **service** teste le contenu de ce qu'il produit. Le **contrôleur** teste l'autorisation, la route, le type MIME et le nom du fichier téléchargé. Aucun des deux ne refait le travail de l'autre : un total faux se voit dans le test de service, un export ouvert à un rôle qui ne devrait pas y avoir droit se voit dans le test de contrôleur.

## Ce qui ne se teste pas

- **`ApplicationService`** — la classe ne vient pas de nous, c'est un motif repris d'une source extérieure. Ses services filles, oui ;
- `initialize` qui se contente de ranger ses arguments (voir plus haut) ;
- la valeur de retour vérifiée **deux fois** — `assert result.is_a?(String)` puis `Spreadsheet.open(result)` : la seconde contient la première, la première se supprime ;
- les **tables de correspondance parcourues en entier** (`WEATHER.keys.each { … }`) — **un seul cas** suffit, plus un cas hors table. Une sentinelle qui balaie toute la table contredit cette règle et se supprime ;
- les audits, les rôles (voir plus haut) ;
- tout ce qui est **commenté**, et le **code mort** (règles transverses de `SKILL.md`).

## Tests critiques

Marqueur **et** bannière (règle transverse). Sont critiques, dans ce répertoire :

- **tout montant imprimé ou exporté** — total d'un PDF, prix unitaire distingué du total de ligne, colonne d'évaluation masquée selon le rôle ;
- **le cloisonnement multi-organisations** d'un service qui écrit (import) ou qui exporte ;
- **la charge utile du QRCode de pointage** — le premier maillon du parcours le plus utilisé de l'application ;
- **le fait qu'une API tierce en panne ne remonte pas jusqu'à l'utilisateur**.

## Aucune classe déclarée dans un fichier de test

Pas de sous-classe de circonstance (`class ImportQuiEchoue < ImportUtilisateursXls`) sous la classe de test : elle est chargée par toute la suite, hors de sa portée. Ce qu'il faut à sa place, dans l'ordre de préférence : provoquer le cas par les **données** ; sinon un `stub` posé **dans le test qui en a besoin** ; en dernier recours seulement, si rien d'autre ne marche, une fabrique sous `private`.

## Nommage des tests

`<élément testé> : <situation> → <effet>` — même formule que les modèles et les contrôleurs. Ex. : `call : aucun agent → classeur d'une seule ligne d'en-tête`, `get_icon_meteo : code inconnu → icône du jour`.

**Aucun commentaire** dans le fichier (règle transverse), et **rien après `private`** que des méthodes privées — un `test` écrit sous `private` reste collecté par Minitest, personne ne le voit passer, et le relecteur est trompé.

## Fixtures

Voir `fixtures.md`. Les réponses d'API vivent dans `test/fixtures/files/`, une par service et par cas.
