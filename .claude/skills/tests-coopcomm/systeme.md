# Tests système — gabarit imposé

Un test système rejoue **un parcours utilisateur réel dans un navigateur**. Il ne vérifie pas du code : il vérifie qu'une personne, avec sa souris et son clavier, atteint son but sans obstacle et sans erreur.

Tout ce qui suit prime sur le confort d'écriture. **Un test ne s'adapte jamais aux contraintes de l'environnement de test** : si le parcours est pénible à automatiser, c'est souvent que l'application est pénible à utiliser.

## 0. Ce qu'on met ici, et rien d'autre

Un test système coûte environ **25 fois plus cher** qu'un test d'intégration (0,85 test/s contre 21). Deux choses seulement le justifient :

- **Les parcours critiques** : créer une intervention, réserver un outil, consulter son tableau de bord, pointer.
- **Le JavaScript**, et c'est le plus important — c'est la seule chose qu'aucun autre niveau ne peut couvrir. Un champ qui apparaît selon une condition, une couleur qui change, un bouton que Stimulus active, un menu qui s'ouvre, un widget qui remplace un `<select>`. Sans navigateur, tout ça est invisible : le formulaire d'invitation postait correctement au niveau HTTP alors que son bouton était `disabled` et qu'aucun invité ne pouvait valider (B97).

Tout ce qui se prouve avec un `get` ou un `post` se teste ailleurs — voir `controleurs.md` et `integration.md`.

## 1. La commande d'un test

Alex donne trois éléments :

| Élément | Exemple |
|---|---|
| **Rôle** | administrateur |
| **Action** | créer un utilisateur avec le rôle adhérent, à partir de la page home |
| **Résultat** | le toast confirme la création ; l'audit du nouvel utilisateur porte « Invitation envoyée » |

**Si l'un des trois manque, le demander avant d'écrire.** De même pour les données que le parcours exige et que la commande ne précise pas (quel service, quel secteur, quelle date) : les choisir, puis le dire explicitement dans le compte rendu.

## 2. Un test = une histoire

Trois étapes qui se suivent font **trois tests**, pas un seul. Un administrateur qui crée un compte, un invité qui ouvre son mail, un invité qui définit son mot de passe : trois tests, éventuellement dans deux fichiers si les rôles diffèrent.

## 3. Nommage

**Fichier** : `<rôle>_flow_on_<records>_test.rb`, le record au **pluriel** — `admin_flow_on_users_test.rb`, `adherent_flow_on_invitations_test.rb`. Classe en CamelCase correspondante. Le fichier vit dans `test/system/<rôle>/`.

Le rôle et le record sont deux informations distinctes : le nom du fichier doit dire **qui agit** et **sur quoi**.

**Nom du test : une user story**, et non une description technique comme dans les autres types de tests. Il dit ce que la personne veut faire, et pourquoi :

```ruby
test "En tant qu'administrateur, je veux créer un adhérent depuis la page d'accueil" do
test "En tant qu'adhérent invité, je veux définir mon mot de passe pour accéder à l'application" do
```

## 4. Point de départ

L'utilisateur est **déjà connecté** au démarrage : `login(...)` dans le `setup`, puis le test commence. Exceptions : le test porte précisément sur la connexion, ou l'acteur ne peut pas être connecté (un invité qui n'a pas encore de mot de passe).

**Le test démarre sur la page qui porte le bouton de l'action**, jamais sur la route de destination. Pour « créer une intervention », on part de l'index des interventions et on clique le bouton d'ajout — pas de `visit new_intervention_url` : le chemin qui mène au formulaire fait partie du parcours, et c'est souvent là que ça casse.

Quand la commande dit **« à partir de la page home »**, le test part de `home_path` et **navigue par les rubriques du menu** jusqu'à la page visée — il ne fait pas `visit users_url`.

**Un test n'est jamais lié à une seule largeur d'écran.** Il ne redimensionne pas la fenêtre pour se simplifier la vie : il doit passer en téléphone comme en PC, parce que l'application est utilisée des deux façons. Quand la page diffère entre les deux — la navbar du haut sous `lg:` d'un côté, le dock du bas de l'autre — c'est au **helper** de absorber l'écart, pas au test de choisir un camp. C'est le rôle d'`ouvrir_dropdown`.

## 5. Cliquer

**Par le texte quand le bouton porte du texte.** `cliquer_bouton 'Enregistrer'`, `cliquer_lien 'Utilisateurs'`. Si le libellé change un jour, le test doit être mis à jour pour repasser au vert — c'est voulu : le texte fait partie de ce que l'utilisateur voit.

**Par `data-testid` uniquement quand le bouton n'affiche qu'une icône** (ou que son texte est masqué à la largeur testée, `hidden md:block`). Si le testid n'existe pas, l'ajouter dans la vue, **en tout dernier attribut de l'élément** — c'est la dernière chose qu'on veut lire dans un gabarit. Puis `cliquer 'mon_testid'`.

`cliquer` accepte les variantes `_mobile` / `_pc` et **attend** l'apparition de l'élément : il ouvre donc correctement un menu déroulant.

Jamais de clic JS (`execute_script`) pour contourner un élément récalcitrant : si Selenium n'atteint pas le bouton, un utilisateur non plus.

## 6. Champs slim-select

`select_option('#id_du_select', 'Valeur')`. Le helper passe par le **HTML généré par slim-select** — il ouvre le `div.ss-main` frère du `<select>`, filtre dans `.ss-search input`, puis clique le `div.ss-option`. On ne pilote jamais le `<select>` natif, invisible à l'écran.

Enchaîner deux sélections : `fermer_menus_slim_select` entre les deux, sinon le menu resté ouvert intercepte le clic suivant.

## 7. Toast après chaque action

Après **chaque action qui en produit un**, vérifier le toast et son texte exact, puis le refermer par sa croix :

```ruby
assert_notification 'Utilisateur créé avec succès.'
```

Il n'y a **jamais qu'un seul toast à la fois** : pas de `all`, pas de boucle. `assert_notification` vérifie puis referme ; `fermer_notification` referme seul (utile après le `login` du setup).

Le toast de connexion ne s'asserte pas, sauf si le test porte sur la connexion.

`assert_notification` est aussi un point de **synchronisation** : le toast n'apparaît que sur la page d'arrivée, donc l'asserter attend la fin de la navigation. Pas besoin d'un `soumettre` en plus.

## 8. Vocabulaire

Le bandeau de flash à l'écran est une **notification** (ou une **alerte**) : c'est le toast. Un `MailLog` est un **mail log**, un `Message` de la messagerie est un **message** — jamais des notifications. Voir la règle « chaque chose porte son nom » dans `SKILL.md`.

## 9. Ce qu'on asserte

L'**état métier** et ce que la personne voit : un texte à l'écran, une URL d'arrivée, une ligne en base. Jamais une classe CSS. Une assertion sur un toast se double toujours d'une assertion durable (l'enregistrement existe, la page d'arrivée est la bonne) : le toast disparaît, pas la donnée.

## 10. Anomalies : deux listes séparées

Un test système fait remonter deux natures de problèmes, à **ne jamais mélanger dans le compte rendu** :

- **Anomalies côté utilisateur** — l'application se comporte mal : message absent, page cassée, bouton inopérant. Elles vont au registre `suivi/bugs-signales.md` et se corrigent (ou s'épinglent avec « à inverser à la correction »).
- **Anomalies côté tests** — l'environnement d'exécution : lenteur, parallélisation, session résiduelle, navigateur. Elles se signalent, **jamais en tordant l'assertion pour les contourner**.

La frontière est parfois instructive : un clic perdu parce que le bouton se déplace pendant une animation d'une seconde est une anomalie **utilisateur**, pas de test.

**Un test système ne se met jamais en `skip` parce que l'application est cassée.** Le `skip` est réservé à une décision métier en attente. Face à un défaut pur — un bouton mort, un jeton absent, une page qui n'enregistre rien — le test **reste rouge** : c'est son travail de le dire, et c'est à l'équipe de surveiller les endroits qui clignotent.

**Devant tout problème sur un test système, consulter Alex en proposant plusieurs solutions**, plutôt que de trancher seul.

## 11. Règles transverses

Aucun commentaire dans le corps d'un test ; une ligne en tête de fichier si sa raison d'être ne se devine pas, et le commentaire d'un helper privé collé à lui. Les tests système ne portent **ni marqueur `(critique)` ni bannière**. Les helpers partagés vivent dans `test/application_system_test_case.rb`, ceux d'un seul fichier sous `private` en fin de classe.

## 12. Helpers disponibles

| Helper | Rôle |
|---|---|
| `login(user)` | connexion par le vrai formulaire |
| `se_deconnecter` | déconnexion (clic JS documenté, dernier recours assumé) |
| `cliquer_bouton(texte)` / `cliquer_lien(texte)` | clic par le texte, recentré sous le dock |
| `cliquer_div_bouton(texte)` | clic sur une `div[role=button][tabindex]` (menu daisyUI) |
| `ouvrir_dropdown(nom)` | ouvre le menu, quelle que soit la largeur d'écran |
| `cliquer(testid)` | clic par `data-testid`, variantes `_mobile` / `_pc` |
| `click_sur_boutton_ajouter(record)` | bouton « + » des index |
| `assert_notification(texte)` | vérifie le toast puis le referme |
| `fermer_notification` | referme le toast par sa croix |
| `select_option(id, valeur)` | slim-select |
| `fermer_menus_slim_select` | referme les menus slim-select ouverts |
| `taille_pc` / `taille_tel` | dimensions de fenêtre |
| `fichier_volumineux(ext, taille)` | pièce jointe de test, nettoyée au teardown |
