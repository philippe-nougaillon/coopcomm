# Points à trancher / actions en attente — CoopComm

> **Liste unique de ce qui attend une décision ou une action humaine** (client / PE). Distinct du registre des bugs (`bugs-signales.md`) : ici on ne liste pas des défauts, mais des **choix à faire** et des **actions que l'agent n'a pas le droit de faire seul**. Tenir à jour : quand un point est tranché, noter la décision + la date puis le déplacer dans « Tranchés » (l'agent reporte ensuite la décision dans CLAUDE.md).

---

## 🟠 Décisions métier à prendre

### D1 — Prix du devis vs tarif courant (= bug **B2** du registre)
- **Question** : quand une commande est créée depuis une cotation signée (puis une facture depuis la commande), quel prix fait foi — celui **signé sur le devis** ou le **tarif courant** de la prestation ?
- **Contexte** : aujourd'hui le tarif courant écrase silencieusement le prix du devis (confirmé : commande à 120 € pour un devis signé à 76,50 €). Correctif technique trivial une fois tranché.
- **Statut** : **en réflexion** (2026-07-10 : « je ne sais pas encore »). **Éclairage 2026-07-28** (fiche contexte) : PE décrit le cycle voulu par « **le tarif est stocké dans la commande** » et « on ne peut pas modifier le prix d'une facture » — ce qui suggère la sémantique *prix figé au moment du devis signé* ; le CCTP (§5.5.7) va dans le même sens : facturation « aux temps réels » mais **comparée au devis initial avec explication des écarts** (donc le devis reste la référence). Confirmation explicite demandée à PE ; si oui, correctif = ne pas appliquer `set_prix_from_prestation` quand la ligne porte déjà un prix hérité d'une cotation/commande.

### D3 — Activation future des notifications `EmailSubscription` (= bug **B8**)
- **Question** : quand (si) on active la notif « intervention mise à jour », valider le correctif préalable (`User.find_by` + garde nil) — 166 interventions crasheraient sinon.
- **Contexte** : fonctionnalité dormante, décision client du 2026-06-23 de ne pas y toucher d'ici là.
- ⚠️ **Requalifié le 2026-07-31** : `on_intervention_updated` n'existe plus, mais la même ligne non gardée subsiste dans `on_intervention_workflow_changed` ([email_subscription.rb:7](app/subscriptions/email_subscription.rb#L7)), qui lui est **bien actif** (publié par valider/refuser/archiver et par `Intervention#apres_terminaison`). Ce n'est donc plus un risque conditionné à une activation future : voir B8 au registre. Le handler voisin `on_intervention_done` a déjà reçu le garde le 2026-07-29-h.

### D5 — Workflow de validation des documents d'outil : supprimé ou en pause ? (constat du 2026-07-10)
- **Question** : la refonte UX (Dani Isaza, commits `3ae4f02e` du 2026-07-02 « UX - corriger github actions » et `42085022` du 2026-07-03 « UX - solution github ») a **désactivé toute la fonctionnalité** valider/refuser des documents d'outil : actions commentées dans `documents_controller.rb`, routes commentées (`resources :documents, only: %i[]`), workflow commenté dans `document.rb`, boutons retirés du partial `_document.html.erb` (colonne État vide). Le formulaire outil est passé des nested attributes (fichier + état par document) à une **dropzone unique** `form.file_field :documents`. Est-ce une suppression **assumée** de la fonctionnalité, ou un débranchement **temporaire** pour faire passer la CI (les noms de commits le suggèrent) ?
- **Conséquence immédiate** : les 3 system tests de `test/system/documents_test.rb` échouaient (ils testent l'UI disparue) → **commentés le 2026-07-13** (décision client : « pour l'instant on ne l'utilise pas ») avec renvoi vers ce point. À trancher avec Dani : si suppression assumée → supprimer le fichier de test ; si temporaire → réactiver la fonctionnalité et décommenter/adapter les tests.
- **Incohérence à signaler au passage** : `tools_controller#tool_params` permet toujours `documents_attributes` alors que le formulaire n'envoie plus que `documents` (fichier simple) — l'upload de documents depuis le formulaire est probablement cassé aussi côté serveur (non vérifié).

### D6 — Refaire la fiche outil (`tools#show`) sur le même système de cases que l'index (PE, 2026-07-29 — « plus tard »)
- **Quoi** : la fiche outil affiche encore son calendrier via `Tool#dernier_mouvement_a` + le partial `mouvements/_mouvement_slot` (une case par créneau horaire, un objet `Mouvement` par case), alors que l'index `/tools` est passé au système de lettres `L/R/I/P` de `Tool#get_etats_from_mouvements` + `tools/_mouvement` (#411). PE : « le show de l'outil n'a pas encore été refait, tu peux faire le même système de case que dans l'index » → **à faire plus tard**, hors du lot de tests du 2026-07-29.
- **Ce que ça résout au passage** : `dernier_mouvement_a` porte **B37** (500 latent dès que l'association est chargée) et est explicitement marqué « devrait disparaître quand tools/show sera refait comme l'index » par un TODO dans le code ([tool.rb:79](app/models/tool.rb#L79)). `_mouvement_slot` est aussi le seul chemin qui propose « déclarer la fin de panne » d'un clic — à ne pas perdre dans la bascule.
- **Attention** : zone « très sensible » des Pièges connus (réservation / panne). Corriger **B36** (lettre `P` le jour de la panne) **avant** la bascule, sinon le défaut se propage de l'index au show.
- **Couverture existante** : `tool_test.rb` verrouille déjà la sémantique des 4 lettres, y compris les cycles panne/réparation — la bascule pourra s'appuyer dessus.

### D7 — Absences : les 3 écarts restants après le lot du 2026-07-30 (`#419`, `eaa5ac86`, `967781b7`)
- **Contexte** : le CCTP ne contient **aucune exigence** sur les absences (vérifié dans le digest anonymisé de `fiches/contexte-projet.md` ; PE n'a pas transmis le PDF complet, à recouper si un doute contractuel apparaît). La fonctionnalité est un *moyen* du planning, pas un livrable exigé → rien de bloquant pour septembre. Les 5 demandes de PE du 2026-07-30 sont livrées ; ce qui suit ne l'est pas.
- **① Motifs incomplets** — l'enum ne connaît que `congés_payés`, `congé_parental`, `formation`, `congé_sans_solde` ([absence.rb:10](app/models/absence.rb#L10)). Il manque **maladie / arrêt de travail**, statistiquement le premier motif d'absence sur ~115 agents, et probablement RTT et autorisation exceptionnelle. **Aucune migration nécessaire** (ajout de valeurs d'enum + `MOTIF_LABELS`) ; ~5 min. *Décision attendue : la liste exacte des motifs voulus par le client.*
- **② Export XLS « Jours d'absence » non fiable** ([export_to_xls/agents.rb:31](app/services/export_to_xls/agents.rb#L31)) — `agent.absences.sum(&:nb_jours)` somme **tout l'historique** (jamais borné à une année), en **jours calendaires** (week-ends et fériés comptés), et une **demi-journée vaut 1 jour** (`(au - du) + 1`). Deux agents d'ancienneté différente sont incomparables. *Décisions attendues : période de référence (année civile ? 12 mois glissants ?), jours ouvrés ou calendaires, demi-journée = 0,5.* Ne pas publier ce chiffre en l'état s'il sert au pilotage RH ou à la refacturation.
- **③ Calendrier des agents illisible sur les absences** ([users/_agent.html.erb:62-71](app/views/users/_agent.html.erb#L62)) — même carré `bg-[#db2767]` pour « occupé » et « absent », l'information ne vit que dans le `title` au survol, donc invisible sur le Samsung S8 des agents. Le filtre « absent » est commenté dans le contrôleur ([users_controller.rb:179-186](app/controllers/users_controller.rb#L179)) avec un TODO proposant le bon remède (cases grisées). *À traiter seulement si `agent_calendrier` est réellement utilisé — la fiche contexte le donne comme « la seule fonctionnalité qui risquerait d'être ignorée ».*
- **Plus mineur, non chiffré** : aucune vue d'ensemble des absences (routes `only: [:destroy]`, il faut ouvrir chaque fiche agent) ; suppression via `link_to … turbo_method: :delete` ([_absence_form.html.erb:64](app/views/users/_absence_form.html.erb#L64)) au lieu de `button_to`, contraire à la doctrine « plus jamais de GET mutant » de l'audit 2026-06-12 §3.
- **Asymétrie restante, assumée** : `Absence#no_overlapping_interventions` et `Intervention#check_absence` sont désormais alignés (demi-journées + dates réelles des deux côtés). Le seul écart conservé est volontaire : la **clôture d'un pointage déjà ouvert** échappe au contrôle (`Intervention#clôture_de_pointage?`), sans quoi une absence posée en cours de journée figerait le pointage ouvert et ferait échouer la clôture nocturne.

### D8 — Import XLS : comment **changer** le service d'un agent, maintenant qu'il n'en a droit qu'à un seul ? (agent, 2026-08-02)
- **Contexte** : la règle « un agent a exactement un service » (demande PE du 2026-08-02) a une conséquence non demandée sur l'import XLS des agents. `users#import_do` **cumule** les services (`user.user_services.build(service:)` si le rattachement n'existe pas encore) et force `rôle = 'agent'`. Donc : réimporter le **même** service est sans effet (idempotent, inchangé) ; importer un service **différent** produit un agent à 2 services → la validation refuse → la ligne part **en erreur** avec « Services ne doit comporter qu'un seul service pour un agent ». **Changer le service d'un agent par import est donc devenu impossible.**
- **Effet de bord positif, non recherché** : cette même validation bloque désormais la plupart des rétrogradations silencieuses de **B21** (un manager cité par mégarde dans le fichier n'est plus transformé en agent, sauf s'il est mono-service et que la ligne reprend justement ce service — cas épinglé par un test).
- **Options** : (a) laisser tel quel, le changement de service se fait à la main dans la fiche — le plus simple, l'import reste un outil de **création** ; (b) faire **remplacer** le service au lieu de cumuler quand la cible est un agent ; (c) rendre le message d'erreur explicite (« cet agent est déjà rattaché à X, retirez-le d'abord »). *Rien n'a été changé dans l'import : seuls ses tests ont été mis à jour.*

## 🔧 Actions à faire (infra / prod)

### A1 — Planifier la relance des cotations sur Hatchbox
- **Quoi** : déclarer `bin/rails cotations:relancer_adherents` dans le planificateur Hatchbox, 1×/jour (la garde 48h est dans la tâche).
- ⚠ **Piège** : syntaxe cron Hatchbox limitée (`0/10` non supporté ; une expression invalide bloque TOUTES les tâches planifiées — incident déjà vécu).

### A4 — ❗ Sauvegardes de la base de production (à traiter AVANT la mise en prod de septembre)
- **Constat (PE, 2026-07-28, fiche contexte)** : « on ne fait pas de backup de la base de données ».
- **Exigence CCTP §6.2** : sauvegarde automatique **quotidienne**, rétention **≥ 365 jours**, restauration possible ; §7.5 : réversibilité (restitution SQL/CSV/JSON sous 30 j, suppression attestée).
- **Risque** : ~200 interventions/jour refacturées aux communes = données d'argent ; une perte = incident métier ET contractuel.
- **Piste** : `pg_dump` quotidien planifié (Hatchbox — ⚠ syntaxe cron, cf. A1) vers un stockage séparé (S3 déjà dans la stack), chiffré, avec test de restauration documenté. L'agent peut préparer la tâche + la procédure sur demande.

### A2 — Confirmations prod restantes de l'audit sécurité (2026-06-12)
- Purge des exports **XLS dans `public/`** ; **rotation des comptes seedés** ; `APP_HOSTS` renseigné ; **signature du webhook entrant** vérifiée.

### A3 — CI : job `test:system` séparé
- **Quoi** : exécuter les tests système dans un job CI distinct des tests unitaires/intégration.
- **Pourquoi** : les tests système non transactionnels laissent des résidus qui, depuis #357 (dispos sur dates réelles), font échouer les tests de pointage lancés dans le même run.

## 🧹 Dette / divers (basse priorité, actée mais non planifiée)

- **Dette audit 2026-06-12** (différée par décision client) : migrations `lockable` et `WikiPage.organisation_id` ; `remember_me` forcé ; pas de `current_password` exigé au changement de mot de passe.
- **Donnée en base** : un `temps_total` **négatif** pré-existant (repéré le 2026-06-18) — nettoyer à l'occasion (lié à B1).
- **Doublon Solid Queue potentiel** : plugin Puma `solid_queue` **et** ligne `worker:` du `Procfile.dev` — vérifier qu'on ne fait pas tourner deux workers.
- **Quirk local** : `bundle exec` obligatoire (conflit gem `date` 3.5.1 vs lock 3.5.0).
- **Test optionnel** : réactiver le system test logout *manager* (commenté « missing assertions ») — la recette de logout fiable existe depuis le 2026-06-17.
- **Code mort de l'import XLS** (constat 2026-07-27, session `/tests`) : la vue `users/import_do.html.erb` n'affiche **que** `@stream` (le stdout capturé) — `@success_logs`, `@error_logs` ([users_controller.rb:202-203](app/controllers/users_controller.rb#L202-L203)) et `@mdp` (accumulation des mots de passe générés en clair, [l.201/254](app/controllers/users_controller.rb#L201)) ne sont jamais lus. Idem `WelcomeImportNotificationJob`, écrit pour ce parcours (mot de passe chiffré + mail de bienvenue) mais **appelé par personne** — l'import envoie en fait une invitation Devise. À trancher : brancher l'affichage riche prévu, ou retirer les trois variables et le job (le job porte déjà le bug **B5**).
- **Fixture d'API mal formée** (constat 2026-07-29, session `/tests` lot D) : `test/fixtures/files/responseRoutesInfos.json`, utilisée par le stub WebMock global du `test_helper`, contient la **sortie du service `FetchRoutesInfos`** (`{"data_response":…, "routes_info":…, "localisation_depart":…}`) et non la **réponse brute de Google** (`{"routes":[…]}`). Conséquence : dans toute la suite, `get_trajet_from_response` reçoit un objet sans clé `routes` → renvoie `''`, et `Intervention#calculate_co2` calcule toujours **co2 = 0**. Le chemin nominal du connecteur n'était donc exercé nulle part. Les nouveaux tests de `fetch_routes_infos_service_test.rb` posent leurs propres stubs au bon format ; **la fixture globale n'a pas été corrigée** (elle est utilisée implicitement par toute la suite, un changement de forme y modifierait le `trajet`/`co2` de nombreux tests d'intervention — à faire dans un lot dédié).
- **Onglets CRM figés sur les états de `Commande`** (= bug **B33**) : au-delà du « Signé » manquant, le menu Statut de `adherent_crm` n'est pas dérivé de l'onglet courant. À traiter avec B33.
- **Template de PR GitHub** (mis de côté le 2026-07-10) : créer `.github/pull_request_template.md` avec 5-6 cases à cocher (une par famille d'erreur de `CONTRIBUTING.md` §2) — GitHub pré-remplit alors la description de chaque PR, cases cliquables. Décision client : **pour l'instant on utilise `CONTRIBUTING.md` seul** ; à réévaluer si la checklist n'est pas suivie en revue. Doc : <https://docs.github.com/fr/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository>.

---

## ✅ Tranchés (historique)

| Point | Décision | Date |
|---|---|---|
| D2 — Fusionner la branche `dashboard-scenic` (vues matérialisées Scenic) dans `staging` ? | **Fusionnée** — constaté le 2026-07-31 : `origin/dashboard-scenic` (`11ddebfe`) est un ancêtre de `staging`, `db/views/` et les modèles `DashboardAgentStat`/`DashboardInterventionStat` y sont, `dashboard_data.rb` a disparu (commit `0fb76419 #297`). Conséquences : **B12 corrigé** sur staging, et **B13 n'est plus un bug de branche mais un bug de staging** (le filtre `temps_total >= 0` opère sur les cellules pré-agrégées). | ≤ 2026-07-31 |
| D4 — Notifier quelqu'un quand un adhérent refuse une cotation ? | **Non, personne pour l'instant** (décision équipe rapportée par PE) ; à revoir plus tard. Le correctif reste noté si ça change : job `NotifCotationRefuseeJob` miroir de `NotifCotationSigneeJob` (créateur via l'audit `create`), branché sur le bloc de `transition!` de `cotations_controller#refuser`. | 2026-07-13 |
