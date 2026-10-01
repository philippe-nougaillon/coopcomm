# CLAUDE.md — Aikku CoopComm

> **Mémoire de travail de l'agent** : à lire en premier, à chaque session.
>
> **Ce fichier reste court** (objectif : < 30 000 caractères). Il ne contient que ce qui doit être vrai **à chaque conversation** : identité du projet, conventions, pièges, état courant, périmètre. Les notes de session vont dans `suivi/journal/` (index : `suivi/journal-decisions.md`), **jamais ici** — seule une leçon durable y remonte, en une ligne dans « Pièges & leçons apprises ».

---

## 1. Le projet

**Objectif** — Application web de **coopération et de mutualisation de services entre communes**. Cœur métier : le suivi d'**Interventions** via un workflow d'états (Nouveau → Accepté → En cours → Terminé → Validé → Archivé), partagé entre les parties prenantes (Adhérent/Client, Agent technique, Manager, Comptabilité, Archives). Info unique, multi-support (PC/smartphone), avec notifications, exports et audit trail.

**Pour qui** — aujourd'hui une seule communauté de communes (Est de la France). **Vision** : produit commercialisable auprès d'autres communes ou organismes → garder le code **multi-organisations** et générique, aucune spécificité du client actuel codée en dur.

**Stack**
- **Ruby 4.0.7 + Rails 8.1** (monolithe), Bundler 4.0.20 (celui livré avec Ruby — jamais une bêta ni un Bundler plus récent que RubyGems). Front : Hotwire (Turbo + Stimulus) via **importmap**, **TailwindCSS 4.1**. PDF : Prawn (+ qrcode). Export Excel : `spreadsheet`. Pas de bundler JS, pas de linter (ni RuboCop ni Standard).
- **PostgreSQL** ; **Solid Queue / Cache / Cable** adossés à la base (pas de Redis). Jobs : Mission Control sur `/jobs`. Mail en dev : `letter_opener_web` sur `/letter_opener`.
- APIs tierces : Mailgun (emails), Twilio (SMS/WhatsApp), AWS S3, Google OAuth2, Google Maps, Météo Concept, OpenAI + Mistral via `langchainrb`.
- Transverses : `audited` (audit trail), `acts-as-taggable-on`, `friendly_id`, `pg_search`, `discard` (soft-delete), `pagy`, `workflow` (machine à états des `Intervention` — standard de l'équipe, ne pas remplacer sans raison forte), `pundit`, `rack-attack`.
- Secrets : dans `.env` (gitignoré, chargé par `dotenv`) ; la base est dans `dot.env.example`. ⚠ **Ne jamais lire ni recopier les valeurs de `.env`** — référence par nom uniquement.

**Commandes**
- Installer : `bin/setup` — Lancer : `bin/dev` (foreman : web, watch Tailwind, worker Solid Queue) — CSS : `bin/rails tailwindcss:build`
- **Tests : `bundle exec rails test:all`** (toute la suite, système incluse, en un seul run). Un fichier : `bin/rails test test/models/intervention_test.rb`. Relancer les échecs : `bin/rails test:failed`.
- **Couverture : `bin/coverage`** — la seule commande qui donne un chiffre juste (voir « Pièges »).

**Architecture** — Monolithe Rails MVC classique ; logique métier dans les modèles + `app/services/` (objets `ApplicationService`), I/O externe isolée dans les services et les jobs.
- `app/models/` : `Intervention` (entité centrale), `Organisation`, `Service`, `User`, `Convention`, `Cotation`/`CotationLigne`, `Commande`, `Facture`, `Prestation`, `Warehouse`/`Tool`/`Mouvement`, `Absence`, `Message`, `WikiPage`.
- `app/controllers/` : un contrôleur par ressource, autorisations via **Pundit** (`app/policies/`), filet global `after_action :verify_authorized`.
- `app/services/` (exports XLS, connecteurs), `app/jobs/` (notifications asynchrones), `app/pdfs/` (Prawn), `app/views/`.
- **Dashboard** : vues matérialisées **Scenic** (`db/views/`, modèles `DashboardAgentStat` / `DashboardInterventionStat`), rafraîchies **après chaque commit** d'`Intervention` et d'`AgentIntervention` (`after_commit` → `ActualiserDashboard.call`, `REFRESH … CONCURRENTLY` hors de la transaction d'écriture). Les calculs du tableau de bord sont des méthodes privées de `PagesController`. ⚠ Une écriture **sans callbacks** (`update_all`, `update_columns`, `delete_all`, SQL) ne rafraîchit rien et n'est pas auditée : règle de `CONTRIBUTING.md`, **aucune garde automatique** (décision équipe 2026-10-01), suivi en **R7**.

---

## 2. Conventions et règles de travail

**Code**
- Conventions Rails standard. Pas de secret en clair. Pas de dépendance ajoutée sans validation. Migrations versionnées.
- **Commentaires : le moins possible, par défaut aucun.** Si le nom de la méthode dit ce qu'elle fait, ne rien écrire. Jamais de nom de personne, d'historique, de numéro d'issue ni de paraphrase du code — tout cela vit dans `suivi/`. Une ligne maximum, réservée à ce qu'aucun lecteur ne peut déduire (forme d'un retour, comportement de gem contre-intuitif).
- **Le service est la racine du système** — l'organisation d'un utilisateur, son périmètre de visibilité, les listes d'agents, le cloisonnement entre communes : **tout dérive du rattachement aux services**. Un compte sans service n'appartient à aucune organisation et fait échouer tout ce qui lit `current_organisation`. Conséquence : **tout code touchant aux services doit être testé**, et ces tests sont **critiques** — aucun ne se supprime au titre d'une règle générale.
- **`private` clôt la classe** — dans **toute** classe Ruby du projet, fichiers de test compris : après `private`, rien d'autre que des méthodes privées. Jamais une constante, jamais un test. Rien ne le signale à l'exécution ; seul le relecteur est trompé.
- **Une nouvelle fonction se place en dernier dans son groupe de même catégorie** (actions de contrôleur, méthodes privées, scopes, callbacks…), jamais au milieu ni en tête.
- **Pas de nouveau concern** (règle PE, 2026-09-23 — « personne n'utilise du concern à part toi ») : une méthode vit dans la classe qui s'en sert ; un comportement partagé par plusieurs classes va dans `app/services/`.
- **Déplacer du code, c'est déplacer son voisinage** : commentaire d'en-tête, `end` de bloc, `<div>`, constantes, variables utilisées. Après tout déplacement outillé, relire le voisinage du point de départ **et** d'arrivée — deux défauts sur trois ne font rien tomber.
- **Checklist avant commit/PR : `CONTRIBUTING.md`** (8 familles d'erreurs récurrentes du projet). L'agent l'applique à tout code qu'il écrit.

**Tests**
- ⚠ **Invoquer la skill `tests-coopcomm` avant d'écrire, de modifier ou de relire un test.** Elle porte les gabarits imposés (policies, contrôleurs, modèles, services, système), les règles de fixtures, le marquage des tests critiques et le placement des helpers. Les faire évoluer = éditer la skill, pas ce fichier.
- **Exigence : tout ce qui peut être testé doit l'être.** Minitest, fixtures dans `test/fixtures/`, système en Capybara + Selenium.
- **Modèle de menace** : aucun utilisateur ne fera de mass assignment ou de requête forgée (seul scénario : compte volé). La menace réaliste, ce sont **les curieux via l'UI normale** — surtout leur propre évaluation (note/avis) et les infos privées d'autrui. Donc : matrice de tests centrée sur les **parcours réels et les données visibles** (pages, exports XLS/PDF, mails) ; tests de forge réservés à l'argent ou sur demande.
- **Un bug trouvé pendant une session de tests est signalé, pas corrigé** sans accord explicite : fiche au registre, et le test **reste rouge** — c'est le signal. Le `skip` est réservé à une **décision métier en attente** (son message dit ce qu'il faut trancher) ; quand la décision manque mais que le comportement actuel doit être figé, test d'**ÉPINGLAGE** avec « à inverser à la correction ». `flunk` est l'outil de l'équipe, pas de l'agent.
- **`data-testid` autorisé** : sous `/tests`, droit d'ajouter un `data-testid` **inerte** sur une vue, aux conditions de la skill `tests-coopcomm` (tests système, élément sans texte ciblable, dernier attribut). Uniquement `data-testid` (pas d'`id` ajouté) ; toute autre modification de prod reste signalée, non appliquée ; signaler les vues touchées.
- **Un correctif se prouve rouge** : saboter le code corrigé, vérifier que le test tombe, restaurer. Voir « Pièges — méthode » pour la manière de saboter sans rien casser.

**Git**
- Branches : **`main`** (prod, protégée), **`staging`** (pré-prod et instance de démo où le client teste), branches de fonctionnalités. Flux : `feature → staging → main`, merge par Pull Request.
- **Format des messages : `#XXX Thème : changements en bref`** — numéro d'issue en tête, **thème** = le modèle touché (`Intervention`, `Convention`, `Tool`…), ou `Test` pour l'écriture de tests, ou `Claude` pour la config de l'agent. Une seule ligne, pas de corps.
- ⚠ **Le numéro d'issue ne s'invente JAMAIS** : n'écrire un `#NNN` que s'il vient de PE ou qu'il est vérifiable dans `git log` ; sinon écrire littéralement `#XXX` et demander. Vaut aussi pour les numéros de PR. *(Deux commits ont déjà été rattachés à la mauvaise issue.)*
- ⚠ **Pas de ligne `Co-Authored-By: Claude`** dans les messages de commit (demande PE ; deux commits ont dû être réécrits pour la retirer).
- ⚠ **L'agent ne committe pas.** Quand des modifications sont prêtes, il **propose** un message de commit ; PE committe.
- La config Claude (`CLAUDE.md`, `.claude/`, `suivi/`) est **trackée et poussée**, donc lue par l'équipe : ne rien y mettre de sensible. Un fichier Claude qui doit rester hors dépôt va dans `.gitignore` (cas actuel : `.claude/method/fiches/contexte-projet.md`).

**Comptes rendus à PE**
- **Commencer chaque réponse par une ligne `TL;DR`.**
- **Ne pas raconter ce qui a été fait** : PE lit le code. Un compte rendu ne contient que ce qui **ne se lit pas dans le diff** — le résultat des tests, les **faits mesurés contre-intuitifs** qui justifient la conception, les **choix tranchés seuls** qui attendent validation, ce qui reste **ouvert ou à signaler**, et le message de commit. Supprimer l'inventaire des fichiers, la liste du « livré », la chronique de l'écriture des tests.
- **Distinguer fait / déduction / opinion.** Un comportement « mesuré » et un comportement « déduit » ne s'annoncent pas de la même manière.

---

## 3. Pièges & leçons apprises

> Extraits de trois mois de sessions. Chaque ligne a coûté au moins une erreur réelle. Le détail et le « pourquoi » sont dans `suivi/journal-decisions.md`.

**Zones fragiles — lire et comprendre avant de toucher, tester après**
- **Messagerie** (`messagerie_controller`, `Message`, vues associées).
- **`slim_select_controller`** (Stimulus) : beaucoup de comportements en dépendent.
- **`Mouvement` (matériel)** : ce qui se déclenche au clic sur une case pour réserver ou déclarer une panne, et les validations du modèle. Très sensible.
- **App en production** avec de vraies communes : prudence sur toute migration, tout envoi réel, toute tâche touchant les données.
- **Planificateur Hatchbox** : il ne comprend pas la syntaxe cron `0/10` — et **une seule expression invalide bloque TOUTES les tâches planifiées**, y compris les valides. Écrire `*/10`. À vérifier pour toute nouvelle tâche.

**Rails / ActiveRecord**
- `association.count` sur un enregistrement **neuf** fait un SQL avec `owner_id` nil et rend **0** ; `association.size` rend la taille en mémoire. Dans une validation ou un calcul appelé à la création, c'est toujours `size`.
- `assign_attributes(x_ids:)` sur un `has_many :through` **écrit les lignes de jointure immédiatement**, avant le `save` : un refus de validation laisse la base modifiée. D'où la **transaction avec rollback** dans `interventions#update` et `users#update`.
- Un `has_many :through` **sans `dependent:`** supprime ses lignes de liaison par `delete_all`, donc **sans callback ni audit** : un retrait n'est pas tracé.
- `update_all`, `update_column(s)`, `delete_all`, `insert_all`, `upsert_all` n'exécutent **aucun** callback : ni audit, ni rafraîchissement du dashboard. Proscrits dans `app/` et `lib/` — règle de `CONTRIBUTING.md`, sans sentinelle (décision équipe 2026-10-01), seule exception les trois `update_column(:total_ht, …)` des lignes de devis/commande/facture ; en console, relancer `ActualiserDashboard.call` après une correction de données.
- `mark_for_destruction` n'est **pas** honoré par `save` si l'association n'est pas en autosave — l'enregistrement peut être `valid?` tout en portant en base l'état que la validation interdit.
- `belongs_to_required_validates_foreign_key` vaut **`false`** (défaut Rails 7.1) : la présence n'est vérifiée que **si la clé est assignée**, pas à chaque `save`.
- Un `save` **à l'intérieur** d'une chaîne `after_commit` réinitialise `@_trigger_create_callback` : les callbacks déclarés **après** cessent de s'exécuter. Déclarer en dernier ce qui sauvegarde.
- Une chaîne vide écrite sur une colonne texte nullable est un **vrai changement** pour ActiveRecord → audit vide. Géré globalement par le concern `ChaineVideEnNil` (`ApplicationRecord`), qui exclut délibérément les colonnes `NOT NULL`.
- `String#to_date` **ne lève pas** sur une chaîne vide : il rend `nil`. Un `rescue Date::Error` seul ne suffit jamais.
- `where(colonne_datetime: une_Date)` couvre la **journée entière**, pas minuit.
- `GlobalID::Locator` **n'applique pas** `default_scope :kept` : un enregistrement soft-deleté reste désérialisable par un job, qui s'exécute alors sur un zombie.
- Postgres : `SELECT DISTINCT … ORDER BY <expression>` est refusé si l'expression n'est pas au SELECT ; et une requête refusée **empoisonne la transaction** → point de sauvegarde (`transaction(requires_new: true)`) pour toute sonde de requête.
- `REFRESH MATERIALIZED VIEW CONCURRENTLY` **passe dans une transaction** (mesuré) : le projet a cru l'inverse trois mois et maintenu une variante `concurrently: false` pour les tests. Un seul chemin de refresh, `CONCURRENTLY` partout.
- `validates numericality` refuse `nil` par défaut : le combiner à `presence` sans `allow_nil: true` produit **deux** messages pour un champ vide.
- Rails accompagne tout `<select multiple>` d'un **champ caché vide** → une sélection vidée arrive en `['']`, qui n'est **pas** `blank?`. Utiliser `Array(...).compact_blank`.
- Rails ajoute d'office une option vide à tout select **`required`** (inutile d'écrire `include_blank`) ; et sur un select simple, une option vide n'est un placeholder que **si elle est en première position** — d'où la garde de `slim_select_controller`.
- Un `before_action` qui **redirige** empêche les `after_action` : `verify_authorized` ne proteste pas, la garde « introuvable » est donc sûre.
- **Une validation permanente fige les lignes historiques invalides** : avant d'en poser une, mesurer le volume concerné en base (dev **et** prod) et dire la conséquence.
- Un `has_one :through` n'a pas de writer singulier utilisable : `record.organisation =` construit un objet vierge ou lève.

**Tests & fixtures**
- ⚠ **Jamais deux runs de tests simultanés sur la même base** — contamination des fixtures, deadlock `REFRESH MATERIALIZED VIEW`, rembobinage de séquence `audits_pkey`. Vaut aussi **entre deux sessions de l'agent** (quatre récidives). **Ne jamais lancer un run en arrière-plan** : un seul run à la fois, au premier plan, et vérifier `ps` avant de relancer.
- ⚠ **Ne jamais ancrer une fixture ni un test sur `Time.now` / `Date.today`** : ça produit des « bombes du jeudi » (une date relative retombe sur une fixture existante), des échecs entre 14 h et 15 h, ou entre minuit et 4 h. Ancrer sur une date passée fixe, choisie sans conflit de disponibilité.
- **`bin/coverage` est la seule mesure juste** : il vide `coverage/` (sinon le run précédent est fusionné avec le nouveau) et précharge SimpleCov **avant le boot de Rails** (sinon tout ce qui est chargé au boot est compté à 0 % alors qu'il est couvert — 12,8 points d'écart).
- ⚠ **`PARALLEL_WORKERS` est défini dans `.env`** : tous les runs sont donc parallèles. Pour un run réellement séquentiel : `PARALLEL_WORKERS=1 bin/coverage`.
- Un **échec** dans la suite empêche l'écriture de `coverage/.last_run.json` (le pourcentage imprimé reste juste).
- SimpleCov ne mesure **ni les `.erb` ni les contrôleurs Stimulus** (~1 700 lignes invisibles), fait de la couverture **de ligne** seulement, et ne compte pas le code commenté. Une ligne « couverte » ne dit rien de la qualité de l'assertion — les PDF et les exports étaient à 100 % sans qu'aucun montant ne soit asserté.
- Une **variable d'environnement lue par du code de prod** doit être posée **par le test qui en a besoin**, et restaurée : héritée de `.env`, elle marche en local et casse en CI.
- `ActionView::TestCase` ne charge **que** le helper testé : prévoir `include ApplicationHelper`, `include ERB::Util`, et `@request.path_parameters` pour que `url_for` trouve une route.
- `Devise.mappings` est **vide** hors test d'intégration → `Rails.application.reload_routes_unless_loaded` en `setup`.
- `record.attach(...)` sur un enregistrement **persisté** enregistre aussitôt : la pièce jointe n'est plus « nouvelle » et **échappe à la validation**. Tester par **assignation**.
- Les bases parallèles `coopcom_test-N` périment : un premier run massivement rouge (erreurs `RecordNotFound` ou `create_and_load_schema`) est auto-réparant — relancer avant de diagnostiquer.

**Système / Capybara**
- **Asserter l'état métier, jamais les toasts de flash** : ils s'auto-détruisent à 5 s, aucun timeout ne corrige ce pile ou face. Corriger la **forme** de l'assertion d'abord, le budget d'attente ensuite.
- `fill_in` sur un `input[type=date]` n'écrit la valeur que si on lui passe un **objet `Date`** ; une `String` est tapée caractère par caractère et interprétée selon la locale du navigateur.
- `assert_no_button` **ignore les boutons désactivés** par défaut (or `data-disable-with` les désactive au clic) → `disabled: :all`, sans quoi l'assertion est vraie en 1 ms et ne synchronise rien.
- Selenium aligne l'élément en **bas** du viewport, c'est-à-dire sous le dock fixe en largeur mobile → passer par les helpers `cliquer_element` / `cliquer_bouton`, qui recentrent.
- slim-select : re-cliquer une option déjà sélectionnée la **désélectionne** ; un menu resté ouvert intercepte le clic suivant ; la cascade `dynamic-select` reconstruit les listes et écrase une sélection posée trop tôt. Toujours passer par le helper `select_option` (retry + fermeture des menus).
- Le variant `hover:` de Tailwind 4 est **inerte en headless** (et sur mobile) : un effet de survol ne peut pas être testé ainsi.
- Les tests système déclenchent de **vraies requêtes vers `maps.googleapis.com`** (clé lue en test).
- Une méthode de test n'est mutualisée que si **plusieurs fichiers** l'appellent ; sinon elle vit sous `private` dans son fichier.

**Méthode**
- ⚠ **Restaurer un sabotage par copie de sauvegarde, jamais par `git checkout <fichier>`** : le fichier porte souvent des modifications non commitées, qui seraient effacées (vécu deux fois). Contrôler par `md5sum`, et **vérifier que le sabotage a bien pris** avant de conclure (un remplacement qui ne matche pas ne signale rien).
- **« Aucun test ne tombe » ne prouve pas qu'un code est mort** : il peut prouver que le test ne reproduit pas le parcours réel. Sonder dans les conditions de production avant de supprimer.
- **Un statut « corrigé » ne se déduit jamais** de la présence d'un identifiant qui ressemble au correctif : il se prouve en exécutant le test qui épingle le bug.
- **L'arbre de travail bouge sous la session** (onze occurrences : commits, merges, éditions de PE en parallèle). Relire un fichier à neuf avant de l'éditer, et prouver qu'un échec est **préexistant** en restaurant les fichiers à HEAD *par copie* puis en rejouant.
- **Avant d'ingénier un contournement à un workflow douloureux, chercher la voie canonique de l'outil** et présenter les deux (leçon `rails test:all`).
- Après avoir gardé une branche d'un `if/elsif` en cascade, **vérifier sur les données réelles** où tombe désormais le cas.
- Ne poser une sentinelle « ceci n'existe plus » que si la disparition peut être annulée **par accident et sans bruit**.
- Ce qui relève du rendu se vérifie **au navigateur** (capture d'écran), pas par déduction — la suite tourne en largeur téléphone, où les grilles s'effondrent et masquent les défauts.
- Une **sonde jetable** avant de rédiger une matrice de cas déplace des déductions vers des faits (et a déjà invalidé plusieurs hypothèses).
- **`embedded_svg` rend `''` sans bruit quand le fichier manque**, et plusieurs icônes sont référencées par un chemin **dynamique** (`"icons/#{nom}.svg"`) : avant d'en supprimer une, chercher aussi son nom nu (`'login'`), pas seulement `login.svg`.
- **Un fichier donné comme référence par une consigne peut la contredire** : `SKILL.md` désignait `commandes_controller_test.rb` comme modèle de nommage, or 22 de ses 24 noms portent la forme que la même page interdit. Ouvrir la référence avant de s'appuyer dessus.
- **Un statut « ouvert » ne se déduit pas du registre non plus** : un correctif posé par un collègue ne met aucune fiche à jour (B2 est resté six semaines en tête des bloquants après sa correction). Sonder le code avant de s'appuyer sur une fiche.

---

## 4. État d'avancement

- **Branche courante : `502`** ; `staging` = intégration et démo client ; `main` = prod.
- **Suite de tests** : `bundle exec rails test:all` → **2222 runs / 0 échec / 0 skip** en **3 min 29** (référence 2026-09-23, rafraîchissement du dashboard à chaque commit inclus — il ne coûte que 9 s ; les 7 min 27 de la veille venaient des triggers en transaction et de 5 flakes système). Flakes connus sous charge parallèle : les deux fichiers système Devise (famille R3), verts en isolation ; la suite système ne compte plus que 12 fichiers depuis #489. Couverture `bin/coverage` : **~96,7 %** — les ~160 lignes restantes sont du code mort inventorié (B89 au registre) ; « 100 % » s'atteindrait par suppression, pas par test.
- **Jalons** : **mise en prod client début septembre 2026** (aujourd'hui, seuls les comptes support/test servent) ; ~10 jours de dev restants, nouvelles fonctionnalités **en pause** ; fin de contrat mars 2028 ; **open-source envisagé mi-novembre 2026** (penser à purger la config Claude de l'historique). ~220 utilisateurs attendus, peu à l'aise avec l'informatique, agents sur Samsung S8, **zones blanches** pour le service technique.
- **Parcours critiques** : pointage QR (4 scans/agent/jour), bon d'intervention, réservation de matériel, dashboard manager, validation adhérent. **« Catastrophique » = tout ce qui touche à l'argent**, et un agent qui verrait son évaluation (le CCTP les réserve aux gestionnaires).
- **Équipe** : Dani = front, Alexandre + PE = back, PE merge `main` et déploie. Les issues GitHub (backlog) sont privées, inaccessibles à l'agent.
- ⚠ **A4 — aucune sauvegarde de la base de prod** alors que le CCTP exige quotidien + rétention 365 j + restauration. À traiter avant la mise en prod.

**Prochain jalon — tableau de bord CRM demandé au CCTP** (branche `CRM`, en sommeil) : demandes par statut ; devis en attente de réponse avec relances automatiques (livré : `cotations:relancer_adherents`) ; CA prévisionnel et réalisé ; taux de transformation devis/commandes ; note moyenne de satisfaction ; répartition par type de prestation et par commune. *(Trois de ces indicateurs restent bloqués par le modèle de données : la commune n'est pas modélisée, aucun lien `Cotation` ↔ `Intervention`, le type de prestation n'est lié que via `cotation_lignes`.)*

---

## 5. Où chercher

| Besoin | Fichier (aucun n'est chargé automatiquement) |
|---|---|
| Un bug connu, son parcours de reproduction, son statut | `suivi/bugs-ouverts.md` (3 niveaux 🔴🟠⚪) · `suivi/bugs-corriges.md` |
| Un défaut non reproductible, gardé, à re-signaler si la garde tombe | `suivi/risques-surveilles.md` · `suivi/risques-clos.md` |
| Une décision en attente, une action humaine à faire, une dette actée | `suivi/points-a-trancher.md` · `suivi/actions-a-faire.md` · `suivi/dettes-ouvertes.md` (clos : `points-tranches`, `actions-faites`, `dettes-reglees`) |
| **Pourquoi** telle décision a été prise, ce qu'une session a mesuré | `suivi/journal-decisions.md` (index, 110 entrées) → `suivi/journal/AAAA-MM.md` |
| Comment écrire un test ici | skill `tests-coopcomm` (à invoquer, pas à lire) |
| Contexte client détaillé, CCTP, modèle de menace | `.claude/method/fiches/contexte-projet.md` *(hors dépôt)* |
| Erreurs récurrentes du projet, checklist avant PR | `CONTRIBUTING.md` |
| Conduite de session, templates de prompting | `.claude/method/` |

**Ouvrir le journal des décisions** avant de revenir sur un choix ancien, ou avant de toucher à une zone qui a déjà coûté cher : pointage, tests système, cache de fragments, validations d'intervention, filtres d'index, audit.

**Tenue des registres** : chaque registre a un fichier **ouvert** (classé 🔴🟠⚪, définitions en tête, **prochain numéro libre** à incrémenter) et un fichier **clos** (du plus récent au plus ancien) : une fiche close **quitte** l'un pour l'autre, on ne la marque pas sur place. Une note de session s'écrit dans `suivi/journal/AAAA-MM.md`, avec sa ligne dans l'index `journal-decisions.md`. Ne remonte dans ce fichier-ci qu'une **leçon durable** (une ligne au §3), un **changement de convention**, ou une **mise à jour de l'état courant** — en *remplaçant* la ligne précédente, jamais en l'empilant.

---

## 6. Périmètre de l'agent

- **Autorisé** : lecture et édition dans tout le dépôt `coopcomm`.
- **Interdit sans accord explicite** : `git push`, `git reset --hard`, `git clean`, exécution de migration (`db:migrate` / `rollback` / `drop`), déploiement, envoi réel de mail/SMS/WhatsApp, toute action touchant la base de prod ou les APIs tierces (Mailgun, Twilio, OpenAI, Mistral, AWS). Ces interdits sont **techniquement appliqués** par le hook `.claude/hooks/guard-bash.py`, doublé de règles `deny` dans `.claude/settings.local.json`.
- **`git commit` n'est pas exécuté par l'agent** (cf. §2).
- Connecteurs MCP : aucun.

---

## 7. Protocole d'auto-contrôle

> **Toi, l'agent : applique-le.** Signalement bref, jamais un sermon. PE peut dire « je sais, vas-y » pour passer outre — dans ce cas, consigne l'écart dans le journal ci-dessous et continue, sans insister.

1. **Vérification 30 secondes au début de chaque tâche.** La demande est-elle (a) claire, (b) contextualisée, (c) cadrée (périmètre + livrable) ? Sinon → poser 3 à 10 questions **avant** d'exécuter.
2. **Avant de coder** : explorer l'existant, proposer un mini-plan, le faire valider. Pas une ligne avant. Chercher activement ce qui existe déjà (fonctions, helpers, motifs) plutôt que d'écrire du neuf.
3. **Vérifier à chaque étape, pas seulement à la fin.** Dix petites itérations vérifiées valent mieux qu'une grosse génération. Si c'est trop long pour être vérifié, c'est trop long.
4. **Après 2 ou 3 tentatives de correctif qui échouent, arrêter de tâtonner et chercher** (documentation officielle, issues GitHub, source de la gem, comportement en CI). Le tâtonnement masque souvent une hypothèse fausse ou un comportement non documenté ; la recherche donne la réponse qu'on aurait eue cinq essais plus tôt.
5. **Signaler en une phrase** — puis proposer le correctif, sans poursuivre sur le chemin fautif — quand : la demande est vague, je pars en one-shot sur du complexe, la sortie est acceptée sans relecture, des données sensibles apparaissent, la conversation s'allonge sans synthèse.
6. **Anti-flagornerie et contre-pouvoir** : sur une décision d'architecture ou de produit, donner le *steelman* de la position inverse et les conditions sous lesquelles la recommandation s'inverserait. Ne pas valider par défaut.
7. **Fin de réponse importante** : angles morts / ce qui reste incertain, prochaines étapes, questions ouvertes.

Le détail générique de la méthode (conduite de conversation, *context rot*, slash-commands) est dans `.claude/method/checklist-operationnelle.md`.

**Journal des écarts** *(format : `AAAA-MM-JJ — règle sautée — contexte`)*

| Date | Règle sautée | Contexte |
|------|--------------|----------|
| — | — | — |
