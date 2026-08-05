# Guide de contribution — CoopComm

> Erreurs récurrentes constatées dans l'historique du projet, et checklist pour ne plus les refaire.
> Chaque règle est tirée d'un **vrai correctif** du dépôt (commit ou bug du registre `suivi/bugs-signales.md`).
> Principes de base déjà acquis : **une fonction ne fait qu'une chose · KISS · DRY**. Ce guide couvre le reste.

---

## 1. Les 8 familles d'erreurs qu'on a dû reprendre

### ① Sécurité : toute action qui modifie des données est un POST autorisé et scopé

L'audit du 2026-06-11 (`b7ac9963`) a corrigé 36 failles, presque toutes du même moule :
transitions de workflow en **GET**, `params.permit!` ou permits trop larges (`:rôle`,
`:workflow_state` modifiables par n'importe qui), contrôleurs **sans policy Pundit**
ni scoping à l'organisation (IDOR), webhook sans vérification de signature.

**La preuve que ça revient** : 8 jours après l'audit, `23b72bcf` (#310) répare le pointage
cassé parce qu'un bouton appelait encore en GET une route passée en POST.

Règles :
- Une action qui **change l'état** (création, update, transition workflow) = route **POST/PATCH/DELETE** + `button_to`, jamais un lien GET.
- Tout contrôleur appelle `authorize` (filet : `verify_authorized` global — un oubli lève une erreur, ne le contournez pas avec un skip non justifié).
- `params.require(...).permit(...)` en **liste blanche** ; les attributs sensibles (`rôle`, `workflow_state`, ids d'association) sont réservés aux rôles qui y ont droit, et les ids bornés à l'organisation courante.
- `find_by` peut renvoyer `nil` : gérer le cas (404), sinon c'est un 500 (`authorize nil` → NoMethodError — bug B9 du registre, cotations/commandes/factures).
- Transition workflow dans un contrôleur : **toujours** la garde `can_xxx?` (ou `rescue Workflow::NoTransitionAllowed`) — un double-clic ou un retour navigateur ne doit pas faire un 500 (bug B3 : `valider!`/`refuser!` sans garde, alors que `terminer`/`archiver` l'ont).

### ② Vérifier que ce qu'on appelle existe vraiment (schéma, associations, signatures)

Quatre bugs du même moule, tous découverts en écrivant les tests des jobs (session 2026-07-01) :
- `intervention.organisation_id` / `manager.organisation_id` : la colonne **n'existe pas** (l'organisation est dérivée via les services) → 4 jobs crashaient.
- `MailLog.create(commande_id: ...)` : la colonne `commande_id` **n'existait pas** → `UnknownAttributeError` (corrigé depuis par la réécriture #330).
- `user.organisation = x` : l'association est `has_many :through`, il n'y a **pas de writer** → NoMethodError (code omniauth/inscription, bug B6).
- `mailer(title: ...)` alors que la méthode attend `title` en **positionnel** → l'objet du mail rend littéralement `{title: "..."}` (bug B4).

Règles :
- Avant d'utiliser une colonne ou une association : la vérifier dans `db/schema.rb` ou en console (`Model.column_names`, `respond_to?`). Ne pas déduire son existence « parce que ce serait logique ».
- Avant d'appeler une méthode existante : ouvrir sa **signature** (positionnel vs kwargs).
- Le point commun de ces 4 bugs : **du code jamais exécuté avant la prod**. Un test qui exécute réellement le chemin (le mail se rend, le log se crée) les attrape tous. C'est la vraie raison de la règle « tout ce qui peut être testé doit l'être ».

### ③ Les échecs silencieux : `create` sans `!`

`MailLog.create` sans `organisation_id` (colonne NOT NULL) → l'insert échoue **en silence**,
le mail part mais n'est jamais tracé (bug B5, mails de bienvenue d'import). Personne ne l'a vu
pendant des mois.

Règle : pour une écriture qui **doit** réussir (log, trace d'audit, donnée métier), utiliser
`create!`/`save!` — ou tester explicitement le retour. Un `create` nu est un choix assumé
d'ignorer l'échec, pas un défaut d'attention.

### ④ Pièges des callbacks ActiveRecord

- `before_save :calc_temps_total` qui assigne une **variable locale** `temps_total = ...`
  au lieu de `self.temps_total = ...` → le callback ne fait rien depuis toujours (bug B1).
- `CommandeLigne#set_prix_from_prestation` **écrase** le prix copié depuis le devis signé
  avec le tarif courant (bug B2) : un callback qui pose une valeur par défaut doit tester
  `if prix_ht.blank?`, sinon il écrase toute valeur posée volontairement en amont.

Règles :
- Dans un callback, l'affectation d'un attribut c'est **`self.attr =`**, jamais `attr =`.
- Un callback « valeur par défaut » ne s'applique que si l'attribut est vide.
- Chaque callback a un test qui vérifie l'**effet en base** après `save` (pas juste que la méthode tourne).

### ⑤ Un changement de contrat se propage à TOUS les appelants

Les correctifs « oubli » les plus fréquents de l'historique :
- Route GET → POST : un bouton oublié (#310, `23b72bcf`).
- Renommage : la vue pas renommée (`a3f46510`), un fichier de notification oublié (`8d6278b0`).
- Suppression d'un job : son **fichier de test** laissé derrière → 2 erreurs dans la suite (#349).
- Revert **collé au lieu de remplacer** : `UsersController` défini deux fois dans le même fichier (corrigé par `b7ac9963`).

Règle : après avoir renommé/supprimé/changé la signature de quoi que ce soit, **grep sur
l'ancien nom** dans `app/`, `test/`, `config/` (routes !) et les vues. Puis lancer la suite.
Un diff de revert/merge se **relit ligne à ligne** avant commit.

### ⑥ Un outil appliqué en masse impose un balayage des dégâts

Le passage rubocop (2026-06-10) a ajouté `# frozen_string_literal: true` partout →
`filename.concat('.pdf')` a levé un **FrozenError en prod** (`44cc0fd0`), et un second
`concat` latent a dû être retiré en prévention (`df059767`).

Règle : après un formatage/lint/upgrade massif, chercher activement les motifs devenus
dangereux (ici : `grep -rn "\.concat\|<<" app/` sur les String), et faire tourner la suite
**complète** avant de committer — un lint « purement cosmétique » n'existe pas.

### ⑦ Tests : déterministes, isolés, qui assertent le métier

Leçons payées (sessions 2026-06-17, 2026-07-09, bug B10) :
- **Jamais d'heure réelle dans une fixture** (`DateTime.now`, `4.hours.ago`) ni dans un test :
  la suite passait sauf... entre 14 h et 15 h (B10). Ancrer avec `travel_to`/`freeze_time`
  et des dates fixes.
- Asserter l'**état métier en base** (`assert intervention.reload.terminé?`), pas les toasts
  flash (instables après navigation Turbo).
- Les tests système ne rollbackent pas : nettoyer ce qu'on crée (résidus → échecs
  ordre-dépendants) ; lancer `test:system` dans un job CI **séparé**.
- **En local, une seule commande : `bin/rails test:all`** — toute la suite, système inclus,
  en un seul run (validé 3 seeds le 2026-07-16 : 1336 runs / 0 échec, ~5 min).
  Ne **jamais** lancer deux runs de test en même temps sur la machine (`rails test` pendant
  un `rails test:system`, deux terminaux, `guard` actif pendant un run manuel) : ils
  partagent `coopcom_test` et le chargement de fixtures de l'un sabote l'autre — symptôme
  typique : `PG::UniqueViolation … audits_pkey` en pleine suite (cf. R2 au registre des
  bugs). Qui veut du vrai parallélisme utilise une base par processus (convention
  `TEST_ENV_NUMBER` du gem parallel_tests).
- Un test difficile à écrire révèle souvent un problème de conception : le signaler, pas le contourner.
- **Symétrie** : si deux ressources sont miroir (Commande/Facture), livrer les tests des deux.
  Facture avait été testée, Commande livrée en scaffold vide — et le même bug (B2) vivait des deux côtés.

### ⑧ Les `# TODO` : du code au mauvais endroit, pas des post-its

Les TODO du code disent presque tous la même chose : *« déplacer ce bloc dans un
service/model »*, *« à mettre dans le pub/sub »*, *« à mettre dans un job »*
(`interventions_controller.rb`, `cotations_controller.rb`, `lib/tasks/interventions.rake`...).
C'est de la logique métier née dans un contrôleur ou une rake task, qu'on paie ensuite.

Règles :
- **Le bon emplacement dès l'écriture** : logique métier → model ou `app/services/`
  (`ApplicationService`) ; effet de bord asynchrone (mail, notif) → job via le pub/sub ;
  le contrôleur ne fait que : autoriser, appeler, répondre.
- Un TODO qu'on écrit quand même = **une issue GitHub** avec le numéro dans le commentaire
  (`# TODO(#342) : ...`). Un TODO sans issue n'existe pas pour personne.
- Divers Rails : redirection **303** (`status: :see_other`) après create/update/destroy
  soumis par Turbo ; les `<label>` ont un `for=` (accessibilité + testabilité).

---

## 2. Checklist avant commit / PR

**Sécurité**
- [ ] Actions mutantes en POST/PATCH/DELETE (`button_to`), aucune route GET qui modifie
- [ ] `authorize` présent (ou skip justifié) ; permits en liste blanche ; ids scopés à l'organisation
- [ ] `find_by` → cas `nil` géré ; transitions workflow gardées par `can_xxx?`

**Solidité**
- [ ] Colonnes/associations/signatures **vérifiées** (schema.rb, console) — pas supposées
- [ ] `create!`/`save!` pour toute écriture qui doit réussir
- [ ] Callbacks : `self.attr =`, défauts appliqués seulement si vide

**Propagation**
- [ ] Grep sur tout nom/route/signature changé (app, test, config, vues) ; pas de code mort ni de test orphelin laissé
- [ ] Diff relu **ligne à ligne** (surtout revert/merge/lint massif)

**Placement (KISS/DRY/une-fonction-une-chose)**
- [ ] Logique métier dans model/service, pas dans le contrôleur ; effets de bord dans un job
- [ ] Pas de TODO sans issue GitHub

**Tests**
- [ ] Le nouveau code est testé (models, policies, jobs, contrôleurs) — y compris le miroir symétrique s'il existe
- [ ] Aucune heure réelle (fixtures et tests ancrés) ; assertions sur l'état en base
- [ ] `bin/rails test` complet vert (pas seulement le fichier modifié)

**Livraison**
- [ ] Commit préfixé `#<issue> : ...` ; 303 après create/update/destroy
- [ ] Tâche planifiée ? Syntaxe cron standard (`*/10`, jamais `0/10` — Hatchbox bloque **toutes** les tâches sinon)

---

## 3. Checklist « nouveau scaffold / nouvelle ressource »

Un `rails generate scaffold` produit du code générique qui ignore **toutes** les conventions
du projet. Passer cette liste **immédiatement après génération** — les scaffolds laissés bruts
ont déjà coûté cher (commandes/factures : tests générés sans login, libellés anglais,
réécrits intégralement le 2026-07-09).

**Modèle & données**
- [ ] La ressource est rattachée à **UNE organisation** — via `Service` (comme `Intervention`) ou par `organisation_id` direct NOT NULL (comme `Tool`), selon le cas. C'est le socle multi-organisations : personne ne doit pouvoir voir les données d'une autre organisation.
- [ ] **Validations dans le model** sur tous les champs requis (`presence`, formats, bornes) — double filet derrière les contraintes NOT NULL de la migration ; c'est le model qui produit le message d'erreur propre, la base ne fait que crasher.
- [ ] **`order` explicite** partout où on liste (scope dédié ou `order(...)` dans l'index) — sans lui, Postgres renvoie un ordre non déterministe : affichage instable et tests flaky.
- [ ] Transverses du projet si pertinents : `audited` (trace), `discard` (soft-delete — et alors penser `.kept` dans les scopes, tous les models n'ont pas de `default_scope`), `friendly_id` (slug), `pg_search`, tags.

**Contrôleur**
- [ ] **Policy Pundit créée** + `authorize` dans **chaque** action (le filet `verify_authorized` lèvera de toute façon) et **`policy_scope`** sur l'index, scopé à l'organisation.
- [ ] **Élément introuvable → redirection**, jamais un 500 : `find_by(slug/id)` renvoie `nil` → `redirect_to index, alert: "... introuvable"` (c'est exactement le bug B9 sur cotations/commandes/factures).
- [ ] **Permits restreints par rôle** : liste blanche minimale, et les attributs sensibles (rôle, état, ids d'association, prix) réservés aux rôles habilités — jamais un permit unique pour tout le monde.
- [ ] **Gardes nil en début de fonction** : si une valeur indispensable est `nil` (param absent, association vide, `User#organisation` peut être nil), `return`/rediriger tôt au lieu de continuer et crasher trois lignes plus loin.
- [ ] **Workflow** : avant toute transition, vérifier **`valid?` ET `can_xxx?`** — `transition!` sur un enregistrement invalide ou hors état lève une exception (500). Motif de référence : `terminer`/`archiver` dans `interventions_controller`. Et chaque transition = **route POST** + `button_to`.
- [ ] Redirections **303** (`status: :see_other`) après create/update/destroy ; pagination `pagy` sur l'index ; logique métier → model/service, effets de bord → job (cf. §1-⑧).

**Routes & vues**
- [ ] `resources ..., only: [...]` : n'exposer que les actions qui existent vraiment ; si la ressource naît d'une autre (commande ← cotation), **supprimer** `new`/`create` au lieu de les laisser accessibles.
- [ ] Vues : libellés **en français**, `<label for=...>` reliés aux champs, `button_to` pour toute mutation.

**Tests (le scaffold en génère, ils sont faux)**
- [ ] **Réécrire ou supprimer** les tests générés : login réel, assertions sur l'état métier en base, fixtures valides. Un test scaffold laissé brut est pire que pas de test : il rouille et casse la suite plus tard.
- [ ] Couvrir : validations model, **policy pour chaque rôle** (y compris les rôles interdits), contrôleur — dont **le test d'isolation : un utilisateur d'une autre organisation reçoit un refus**, et « élément introuvable → redirection ».
- [ ] Fixtures : associations par nom (`adherent: weil`, pas `adherent_id: weil`), jamais d'heure réelle.

---

*Registre détaillé des bugs ouverts (B1–B10, avec parcours de reproduction) :
`suivi/bugs-signales.md`. Décisions en attente : `suivi/points-a-trancher.md`.*
