# Journal des décisions — CoopComm

> **Index des notes de session** (ex-section « Décisions (et pourquoi) » de `CLAUDE.md`, déplacée ici le 2026-09-11 pour sortir ~110 000 tokens du contexte chargé à chaque conversation ; entrées découpées par mois dans `journal/` le 2026-09-22).
>
> **Ce fichier n'est PAS chargé automatiquement** — il se consulte à la demande : `grep` sur l'index ci-dessous, puis lecture de l'entrée dans le fichier du mois, `journal/AAAA-MM.md`. L'ouvrir quand la question est « **pourquoi** avait-on décidé ça ? », avant de revenir sur un choix ancien, ou avant de toucher à une zone qui a déjà coûté cher (pointage, tests système, cache de fragments, validations d'intervention, filtres d'index, audit).
>
> **Règle de tenue** : on ajoute, on ne réécrit pas l'historique. Une note de fin de session s'écrit **dans le fichier du mois** (à créer s'il n'existe pas) et sa ligne **dans l'index ci-dessous** ; jamais dans `CLAUDE.md`, où seule une leçon durable remonte, en une ligne dans « Pièges & leçons apprises ».
>
> Registres voisins : `bugs-ouverts.md` / `bugs-corriges.md`, `risques-surveilles.md` / `risques-clos.md`, `points-a-trancher.md` / `points-tranches.md`, `actions-a-faire.md` / `actions-faites.md`, `dettes-ouvertes.md` / `dettes-reglees.md`. Jusqu'au 2026-09-22, bugs et risques vivaient dans `bugs-signales.md`, actions et dette dans `points-a-trancher.md` : les entrées antérieures les nomment ainsi.

---

## Index

### 2026-06 — `journal/2026-06.md`

- `2026-06-05` — Config Claude (CLAUDE.md, .claude/, fiches/, golden-set/…) gitignorée
- `2026-06-08` — Auto-approbation large des commandes
- `2026-06-08` — Renforcement de la couverture de tests cotations/prestations/conventions/cotation_lignes selon les règles stan
- `2026-06-12` — Audit sécurité + remise à niveau des tests système
- `2026-06-17` — Réparation et dé-flakage de la suite système
- `2026-06-18` — Dashboard rapide via vues matérialisées Scenic + rafraîchissement immédiat
- `2026-06-22` — Correctif du pré-filtre admin des index
- `2026-06-23` — Correctif du filtre Statut de l'index interventions (branche staging)
- `2026-06-23 (suite)` — Filtre services révisé : « présélection vidable » remplace le repli
- `2026-06-23 (révision finale)` — Le fix Statut a été committé par le client
- `2026-06-23 (matrice filtre services finale)` — Le client affine le comportement par défaut (remplace « présélection vidable ») : Interventions

### 2026-07 — `journal/2026-07.md`

- `2026-07-01` — Couverture complète des jobs + correctifs organisation_id
- `2026-07-08` — Relance automatique des cotations à signer
- `2026-07-08-b` — Session /tests : « angle 2 »
- `2026-07-08-c` — Session /tests : « moteur de pointage » incassable
- `2026-07-09` — Réparation d'un lot de tests cassés
- `2026-07-10` — Réconciliation de ce fichier avec git + fiche contexte locale.
- `2026-07-10-b` — Session /tests : symétrie Commande ↔ Facture
- `2026-07-10-c` — Visibilité des cotations côté adhérent restreinte aux cotations envoyées
- `2026-07-10-d` — CONTRIBUTING.md créé à la racine
- `2026-07-13` — Triage des 4 échecs système signalés par le client + tests Documents commentés
- `2026-07-13-b` — D4 tranché : pas de notification au refus d'une cotation (décision équipe rapportée par PE)
- `2026-07-13-c` — Session /tests : couverture du filtre temps_total >= 0
- `2026-07-13-d` — Base de test dédiée aux tests système (coopcom_test_system)
- `2026-07-15` — Refresh du dashboard simplifié : appel Scenic direct, job coalescé mis en sommeil
- `2026-07-15-b` — Session /tests : 4 tests système du refresh des vues dashboard
- `2026-07-15-c` — Réparation des 3 tests signalés par PE
- `2026-07-15-d` — B10 corrigé : les 2 tests « création à postériori » ne dépendent plus de l'heure
- `2026-07-15-e` — B15 corrigé : photos d'intervention via le formulaire manager/admin
- `2026-07-15-f` — Session /tests : action purge des photos d'intervention
- `2026-07-16` — Triage + réparation des 5 échecs signalés par PE
- `2026-07-16-b` — bin/rails test:all devient la commande de test standard en local ; durcissement audits.yml abandonné
- `2026-07-16-c` — rack-attack installé + adapté + testé (branche staging, demande PE). PE avait collé l'exemple officiel GitHub
- `2026-07-16-d` — Consolidation du rate limiting sur rack-attack
- `2026-07-16-e` — Fail2Ban : bannissement automatique des scanners
- `2026-07-16-f` — Triage du flake SecuriteRegressionsTest → nouveau risque R3
- `2026-07-17` — Triage des 2 échecs signalés par PE + purge du warning unprocessable_entity
- `2026-07-17-g` — Tests système rendus robustes à la parallélisation : 8 tests réécrits + 2 helpers + budget d'attente
- `2026-07-17-f` — R3 corrigé : le sign_in d'un test d'intégration ne peut plus être volé par le navigateur
- `2026-07-21` — B18 corrigé : le filtre Services de l'index interventions était mort pour l'adhérent
- `2026-07-17-e` — Retrait des 15 sleep(1) des tests système (demande PE, avant retour au test:all séquentiel
- `2026-07-17-d` — Parallélisation des tests instruite : opt-in PARALLEL_WORKERS=4
- `2026-07-17-b` — Fail2Ban durci : ban dès la 1re sonde + liste de motifs élargie
- `2026-07-17-c` — Triage des 3 runs test:all de validation
- `2026-07-22` — Réparation des 8 tests cassés par le lot #326
- `2026-07-24` — Revue de robustesse des tests système : découplage des assertions insignifiantes + B19 découvert
- `2026-07-27` — Session /tests : import XLS des agents (branche staging)
- `2026-07-28` — Fiche contexte projet remplie
- `2026-07-28-b` — Session /tests « tests critiques » + 2 corrections autorisées
- `2026-07-28-c` — Audit des pièces jointes généralisé : concern PieceJointeAuditable
- `2026-07-28-d` — Réparation des 3 tests rouges du test:all de PE
- `2026-07-28-e` — Le prompt « make this edit to bugs-signales.md? » supprimé pour de bon
- `2026-07-28-f` — Bouton « Terminer » : une seule logique partagée par la home, l'index et le show
- `2026-07-28-g` — B28 : plus d'erreur 500 quand une transition de workflow porte sur une intervention invalide
- `2026-07-29-b` — Commentaires simplifiés dans tout le code
- `2026-07-29` — Relecture du commit #400
- `2026-07-29-c` — Réparation des 2 tests rouges du test:all de PE
- `2026-07-29-d` — Session /tests pilotée par SimpleCov : 141 tests sur les 3 plus gros trous de couverture
- `2026-07-29-e` — Prompt de confirmation sur les fichiers de suivi
- `2026-07-29-f` — Session /tests : le domaine matériel (réservation, pannes, grille de disponibilités)
- `2026-07-29-g` — Session /tests pilotée par SimpleCov : la couche helpers
- `2026-07-29-h` — Terminaison d'une intervention : dates obligatoires, bouton « Terminer » adaptatif, effets de bord centralisés
- `2026-07-30` — Couverture portée de 77,6 % à 96,5 % : d'abord une correction de MESURE, ensuite ~190 tests
- `2026-07-30-b` — Demi-journées d'absence prises en compte côté intervention
- `2026-07-30-c` — Absences : gestion réservée aux managers, notification de la personne concernée, message de conflit détaillé
- `2026-07-30-d` — Fuite de rôle par le cache de fragment des absences
- `2026-07-31` — Contre-balayage des deux fichiers de suivi
- `2026-07-31` — L'adhérent d'une fille de pointage est figé pour l'agent

### 2026-08 — `journal/2026-08.md`

- `2026-08-02` — Formulaire de création d'utilisateur : compte fantôme supprimé, règles de service posées, action morte retirée
- `2026-08-02-b` — Pourquoi le pourcentage SimpleCov bouge : mécanisme établi, mesure re-validée
- `2026-08-03-c` — Fiche outil : la grille de disponibilités passe au système de cases de l'index
- `2026-08-03-d` — B1 corrigé : temps_total est enfin calculé et persisté à chaque sauvegarde, et la pause ne peut plus manquer
- `2026-08-04` — B65 : les champs Service et Rôle disparaissaient après un refus de validation du formulaire utilisateur
- `2026-08-04-b` — Une intervention terminée doit avoir au moins un agent
- `2026-08-04-c` — Une fille de pointage n'a qu'un seul agent
- `2026-08-04-d` — Pièces jointes : une seule source de vérité pour les formats, et plus un seul file_field hors de la zone de dé
- `2026-08-05` — La pause n'est plus inventée à la création
- `2026-08-05` — Les deux registres de suivi quittent .claude/ pour suivi/ à la racine
- `2026-08-05-b` — Les 4 tests rouges réparés, suite complète au vert
- `2026-08-05-c` — Interventions : découpage des vues, policy d'affichage, et matrices de caractérisation
- `2026-08-06` — Trois ajustements demandés par PE : visibilité adhérent, nom du service dans l'audit, destinataires de la noti
- `2026-08-06-b` — Échecs de tests périmés, un <div> non fermé
- `2026-08-06-c` — Le service d'une intervention doit être partagé par l'adhérent et par chacun de ses agents
- `2026-08-06-d` — 5 des 7 skip de la suite levés : B3, B30, B31, B42, B44 corrigés
- `2026-08-06-e` — B5 re-vérifié
- `2026-08-06-f` — Historique d'audit rendu lisible : phrases pour les tables de liaison, regroupement par requête, identifiants
- `2026-08-06-g` — Audit : cas particuliers, pièces jointes rendues comme le reste, historique sur la fiche outil, enums non repr
- `2026-08-06-h` — Deux trous de l'audit trail signalés par PE
- `2026-08-06-i` — Tri de tous les tableaux : un point commun, 23 tableaux câblés, ~130 colonnes triables
- `2026-08-07` — Un test vert en local et rouge sur GitHub Actions : la suite dépendait du .env du développeur
- `2026-08-07` — Associations d'une intervention : service et adhérent
- `2026-08-07-b` — Import XLS des agents : les 5 bugs corrigés, D8 tranché, l'import extrait en service
- `2026-08-10` — B87 corrigé : un pointage resté ouvert un jour précédent ne pouvait plus être terminé
- `2026-08-10-b` — Session /tests : le contenu des PDF, angle mort total de la couverture
- `2026-08-10-c` — B89 corrigé : code mort supprimé, code « parké » distingué et conservé
- `2026-08-10-d` — calc_temps_total remonte en before_validation : #462 fonctionne enfin, et 3 tests repassent
- `2026-08-10-e` — B88 corrigé : le bouton « Terminer » d'une fille ne ferme plus le pointage de celui qui regarde
- `2026-08-11` — Les 2 tests rouges de Service#destroy étaient périmés, pas cassés
- `2026-08-11-b` — Les mots clés apparaissent enfin dans l'historique d'audit
- `2026-08-11-c` — Session /tests : les mots clés (tag_list) de bout en bout
- `2026-08-11-d` — B93 corrigé : les formulaires ne perdent plus la saisie quand une validation refuse
- `2026-08-11-e` — B95 corrigé : une pièce jointe refusée ne se perd plus en silence, et le compteur s'affiche dès un fichier
- `2026-08-26` — « Heure(s) » par défaut à la création d'une prestation
- `2026-08-27` — B99 corrigé : l'attribut required d'un select slim-select était inerte
- `2026-08-31` — Heures conventionnées vides à la création d'une convention

### 2026-09 — `journal/2026-09.md`

- `2026-09-14` — Montée Ruby 4.0.6 / Rails 8.1.3.1 / Bundler 4.0.16, retrait de Bundler 4.1.0.beta1
- `2026-09-14-b` — Warnings rdoc en double et dépréciations Rails 8.2 supprimés (view_component retiré, omniauth-rails_csrf_protection 2.0)
- `2026-09-15` — Veille des signalements sur la montée de version : passage à Ruby 4.0.7 (SEGV de la 4.0.6)
- `2026-09-22` — Registres de suivi découpés en dix fichiers ouvert/clos, journal par mois
