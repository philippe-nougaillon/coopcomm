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

### D7 — Absences : les 3 écarts restants après le lot du 2026-07-30 (`#419`, `eaa5ac86`, `967781b7`)
- **Contexte** : le CCTP ne contient **aucune exigence** sur les absences (vérifié dans le digest anonymisé de `fiches/contexte-projet.md` ; PE n'a pas transmis le PDF complet, à recouper si un doute contractuel apparaît). La fonctionnalité est un *moyen* du planning, pas un livrable exigé → rien de bloquant pour septembre. Les 5 demandes de PE du 2026-07-30 sont livrées ; ce qui suit ne l'est pas.
- **① Motifs incomplets** — l'enum ne connaît que `congés_payés`, `congé_parental`, `formation`, `congé_sans_solde` ([absence.rb:10](app/models/absence.rb#L10)). Il manque **maladie / arrêt de travail**, statistiquement le premier motif d'absence sur ~115 agents, et probablement RTT et autorisation exceptionnelle. **Aucune migration nécessaire** (ajout de valeurs d'enum + `MOTIF_LABELS`) ; ~5 min. *Décision attendue : la liste exacte des motifs voulus par le client.*
- **② Export XLS « Jours d'absence » non fiable** ([export_to_xls/agents.rb:31](app/services/export_to_xls/agents.rb#L31)) — `agent.absences.sum(&:nb_jours)` somme **tout l'historique** (jamais borné à une année), en **jours calendaires** (week-ends et fériés comptés), et une **demi-journée vaut 1 jour** (`(au - du) + 1`). Deux agents d'ancienneté différente sont incomparables. *Décisions attendues : période de référence (année civile ? 12 mois glissants ?), jours ouvrés ou calendaires, demi-journée = 0,5.* Ne pas publier ce chiffre en l'état s'il sert au pilotage RH ou à la refacturation.
- **③ Calendrier des agents illisible sur les absences** ([users/_agent.html.erb:62-71](app/views/users/_agent.html.erb#L62)) — même carré `bg-[#db2767]` pour « occupé » et « absent », l'information ne vit que dans le `title` au survol, donc invisible sur le Samsung S8 des agents. Le filtre « absent » est commenté dans le contrôleur ([users_controller.rb:179-186](app/controllers/users_controller.rb#L179)) avec un TODO proposant le bon remède (cases grisées). *À traiter seulement si `agent_calendrier` est réellement utilisé — la fiche contexte le donne comme « la seule fonctionnalité qui risquerait d'être ignorée ».*
- **Plus mineur, non chiffré** : aucune vue d'ensemble des absences (routes `only: [:destroy]`, il faut ouvrir chaque fiche agent) ; suppression via `link_to … turbo_method: :delete` ([_absence_form.html.erb:64](app/views/users/_absence_form.html.erb#L64)) au lieu de `button_to`, contraire à la doctrine « plus jamais de GET mutant » de l'audit 2026-06-12 §3.
- **Asymétrie restante, assumée** : `Absence#no_overlapping_interventions` et `Intervention#check_absence` sont désormais alignés (demi-journées + dates réelles des deux côtés). Le seul écart conservé est volontaire : la **clôture d'un pointage déjà ouvert** échappe au contrôle (`Intervention#clôture_de_pointage?`), sans quoi une absence posée en cours de journée figerait le pointage ouvert et ferait échouer la clôture nocturne.

### D13 — Verrouiller `interventions.service_id` en base (`null: false`) ? (2026-08-07)
- **Contexte** : le service et l'adhérent sont obligatoires au niveau du modèle, mais les **colonnes restent nullables** ([db/schema.rb:252 et 265](db/schema.rb#L252)) — seule une écriture qui contourne les validations (webhook WhatsApp, console, SQL direct) peut y mettre `NULL`. La clé étrangère vers `services` existe déjà, celle vers `users` non (`adherent_id` est un `integer` sans contrainte).
- **Ce qui est décidé** : `adherent_id` **reste nullable**, c'est la condition pour que le brouillon WhatsApp continue d'exister (décision PE du 2026-08-07 : on laisse le webhook tel quel).
- **Ce qui reste à trancher** : `service_id` en `null: false`. PE indique qu'il n'y a **aucune intervention en production** — la migration y est donc gratuite ; c'est la **démo** qu'il faut mesurer d'abord (requête ci-dessous).
- ✅ **Condition préalable levée le 2026-08-07** : le webhook garde désormais le cas « agent sans service » (réponse explicite, aucune écriture) et choisit son service par `services.ordered.first`. PE : « il n'y a pas de compte agent sans service, ils seraient inutilisables — mais dans le doute, au cas où un jour un agent puisse avoir 0 ou plusieurs services, fais la correction. » Sans cette garde, poser `null: false` aurait exposé le webhook à une `PG::NotNullViolation` (500 rejoué par Twilio).
- **Requête de mesure (lecture seule, à passer sur la démo)** :
  ```sql
  SELECT COUNT(*) AS total,
         COUNT(*) FILTER (WHERE service_id  IS NULL) AS sans_service,
         COUNT(*) FILTER (WHERE adherent_id IS NULL) AS sans_adherent
  FROM interventions;

  SELECT id, description, workflow_state, created_at
  FROM interventions
  WHERE service_id IS NULL OR adherent_id IS NULL
  ORDER BY created_at DESC;
  ```

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
- ~~**Code mort de l'import XLS**~~ — **résolu le 2026-08-07, sauf le job** : le bilan riche prévu a été branché (décision PE), donc `@stream`/`capture_stdout`, `@success_logs`, `@error_logs` et `@mdp` (accumulation de mots de passe en clair) ont disparu avec la réécriture de `import_do` en service. **Reste** : `WelcomeImportNotificationJob` et son test, toujours **appelés par personne** (l'import envoie une invitation Devise), et porteurs du bug **B5** ; `lib/capture_stdout.rb` n'a plus non plus d'appelant. À supprimer quand PE le voudra.
- **Fixture d'API mal formée** (constat 2026-07-29, session `/tests` lot D) : `test/fixtures/files/responseRoutesInfos.json`, utilisée par le stub WebMock global du `test_helper`, contient la **sortie du service `FetchRoutesInfos`** (`{"data_response":…, "routes_info":…, "localisation_depart":…}`) et non la **réponse brute de Google** (`{"routes":[…]}`). Conséquence : dans toute la suite, `get_trajet_from_response` reçoit un objet sans clé `routes` → renvoie `''`, et `Intervention#calculate_co2` calcule toujours **co2 = 0**. Le chemin nominal du connecteur n'était donc exercé nulle part. Les nouveaux tests de `fetch_routes_infos_service_test.rb` posent leurs propres stubs au bon format ; **la fixture globale n'a pas été corrigée** (elle est utilisée implicitement par toute la suite, un changement de forme y modifierait le `trajet`/`co2` de nombreux tests d'intervention — à faire dans un lot dédié).
- **Selects d'identité sans invite** (constat 2026-08-31, lot B99) : sur un formulaire d'intervention neuf, les widgets **Adhérent** et **Service** s'affichent complètement vides, sans aucune invite — le placeholder d'un select requis est vide par construction. Comportement antérieur au lot B99, mais plus visible depuis que la ligne vide a disparu du menu. Le remède est déjà pratiqué dans le dépôt : `prompt: "Choisir un adhérent"` (`commandes/_form`), là où les trois `_prestation_form` ont au contraire `prompt: ""`. Décision d'ergonomie à prendre en une fois pour les ~8 selects concernés.
- **`include_blank: true` redondant** (mesuré 2026-08-31) : à côté de `required: true`, il produit **exactement le même** `<option value="" label=" ">` — Rails l'impose de toute façon. Les cinq endroits qui écrivent les deux (interventions adhérent/service ×2 formulaires, mouvements matériel/état) peuvent le perdre. Ménage, sans effet fonctionnel.
- **Onglets CRM figés sur les états de `Commande`** (= bug **B33**) : au-delà du « Signé » manquant, le menu Statut de `adherent_crm` n'est pas dérivé de l'onglet courant. À traiter avec B33.
### D14 — Angles morts assumés de la convention de tests de contrôleurs (2026-08-13)

> Convention posée par Alex le 2026-08-13 (« ce que teste, et ne teste pas, un test de contrôleur »). Chaque règle a un angle mort ; ils sont listés ici pour être re-examinés plus tard, **pas** pour être corrigés maintenant. Aucun n'est bloquant.

1. **Transitions : plus de balayage « chaque acteur × chaque état »** (règle : on teste chaque transition, pas que chaque état ne plante pas). C'est précisément ce balayage qui a trouvé **B3** — `valider!`/`refuser!` sans garde `can_…?` renvoyaient un **500 sur 20 des 24 combinaisons**, atteignable par un double-clic ou un retour arrière. Le jour où une action de transition est ajoutée sans sa garde, rien ne le dira. *Filet minimal possible si on veut en garder un : un test « hors état → redirection + flash, jamais d'exception » par action de transition (5 tests), au lieu de la matrice (24 combinaisons).*
2. **Tous les tests en administrateur** : les tests de policy répondent « a-t-il le droit », jamais « qu'est-ce que le contrôleur écrit ». Restent donc à découvert les branches du contrôleur qui dépendent du rôle — `@user.rôle = 'agent' if current_user.manager?`, `scoped_services(admin_sees_all:)`, `services_assignables_par`, les `permitted.delete(...)`. *Couverts si on lit la règle ainsi : on change d'acteur uniquement quand c'est la branche testée qui l'exige.*
3. ~~**`*_params` hors périmètre**~~ — **réduit le 2026-08-13** : Alex a tranché que les permits sont testés **là où ils divergent selon le rôle** (agent sans photos de demande, `:rôle` réservé à l'administrateur…). Reste sans filet : les permits identiques pour tous, où vivent malgré tout `:workflow_state`/`:note`/`:avis` exclus du mass assignment (audit 2026-06-12) et le champ de **B91** (`tag_list` forgeable par un adhérent).
4. **`set_[record]` testé sur un seul point** (id inconnu → redirection). Quand le cloisonnement multi-organisations est porté par le `find_by` du `set_` et non par la policy, il n'est plus couvert.
5. **Vues hors périmètre** — atténué le 2026-08-13 : `menus_deroulants_test` et `tris_test` **passent en tests système** (`tableaux_encadres_test` a été supprimé le 2026-08-20 avec le turbo-frame qu'il gardait, cf. B96) et `securite_regressions_test` est **dispatché** dans les fichiers de contrôleur, donc rien n'est perdu. Restent portées par des fichiers hors convention : les **fuites de cache de fragment** (**B55**) dans `test/integration/cache_fragments_test.rb`, et les sondes de visibilité par rôle dans les 4 matrices — conservées sur décision Alex.
6. **Temps négatifs : tests retirés (décision Alex, 2026-08-13)**, la validation `pas_de_temps_total_negatif` (#462) empêchant désormais d'en créer. `dashboard_temps_negatif_test.rb` est remplacé par `dashboard_donnees_test.rb`, qui asserte les **mêmes séries** (kpi, par service, par agent, par adhérent, par mois, proportion consommé/restant) **sans** l'angle du temps négatif : aucune couverture des données renvoyées n'est perdue — `pages_controller_test` ne couvre que l'accès au dashboard, jamais ses données.
   ⚠ **Les 7 `where("temps_total >= 0")` de [dashboard_data.rb](app/controllers/concerns/dashboard_data.rb) n'ont PAS été retirés** : la condition posée (« si cela n'a pas d'incidence ») n'est **pas remplie**, mesuré le 2026-08-13 — **2 interventions à `temps_total` négatif subsistent en base de dev sur 331**, et elles remontent dans la vue matérialisée `DashboardInterventionStat`. Les retirer ferait entrer ces temps négatifs dans les totaux affichés. *Reste à trancher : nettoie-t-on ces 2 lignes (et le volume équivalent en prod, jamais mesuré) pour pouvoir enlever les filtres ?*
   ⚠ **B13** — le filtre opère au grain des cellules pré-agrégées, un −3 h pouvant être « netté » par un +8 h de la même cellule — **perd ses 2 seuls tests d'épinglage** avec ce lot : le comportement n'est plus figé nulle part.
7. **Twilio hors périmètre** : si le webhook WhatsApp est réactivé, il repart de zéro. C'est aussi le seul endroit du dépôt autorisé à écrire en `save!(validate: false)` — la sentinelle structurelle qui l'impose vit dans `test/integration/intervention_sans_adherent_test.rb` et n'est, elle, pas concernée par cette convention.
8. **Fonctions « primaires » (retour d'une couleur, d'un libellé) hors périmètre** : deux bugs de cette famille sont déjà passés — **B80** (libellés de motif d'absence et d'état de mouvement écrits en dur, ne correspondant à aucun enum) et **B36**. Le risque n'y est jamais la logique, c'est la table de correspondance qui diverge de sa source.

- **Template de PR GitHub** (mis de côté le 2026-07-10) : créer `.github/pull_request_template.md` avec 5-6 cases à cocher (une par famille d'erreur de `CONTRIBUTING.md` §2) — GitHub pré-remplit alors la description de chaque PR, cases cliquables. Décision client : **pour l'instant on utilise `CONTRIBUTING.md` seul** ; à réévaluer si la checklist n'est pas suivie en revue. Doc : <https://docs.github.com/fr/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository>.

---

## ✅ Tranchés (historique)

### D6 — ✅ TRANCHÉ (2026-08-03) — Refaire la fiche outil (`tools#show`) sur le même système de cases que l'index
- **Décision PE (2026-08-03)** : bascule faite. La fiche outil **garde sa grille mensuelle** (et le choix Calendrier / Liste des interventions) mais rend ses cases avec `Tool#get_etats_from_mouvements` + `tools/_mouvement`, exactement comme l'index. Légende alignée (carrés au lieu de pastilles).
- **Fin de panne d'un clic sur la case rouge : abandonnée** (décision PE). Elle n'existait que dans le show via `_mouvement_slot` ; la fin de panne passe désormais par le bouton « Gestion panne », présent sur les deux pages. Une case rouge est inerte partout. L'index n'a pas été touché.
- **Ferme au passage** : **B36** (corrigé, prérequis à la bascule) et **B37** (`Tool#dernier_mouvement_a` supprimée avec `mouvements/_mouvement_slot.html.erb`, son unique appelant).
- **Défaut corrigé en chemin** : `tools#show` calculait sa fenêtre sur `params[:date]` alors que `month_calendar` navigue avec `params[:start_date]` — les couleurs se seraient décalées d'un mois dès la première flèche. Le contrôleur lit maintenant `start_date` en priorité et le passe explicitement au calendrier.


| Point | Décision | Date |
|---|---|---|
| D2 — Fusionner la branche `dashboard-scenic` (vues matérialisées Scenic) dans `staging` ? | **Fusionnée** — constaté le 2026-07-31 : `origin/dashboard-scenic` (`11ddebfe`) est un ancêtre de `staging`, `db/views/` et les modèles `DashboardAgentStat`/`DashboardInterventionStat` y sont, `dashboard_data.rb` a disparu (commit `0fb76419 #297`). Conséquences : **B12 corrigé** sur staging, et **B13 n'est plus un bug de branche mais un bug de staging** (le filtre `temps_total >= 0` opère sur les cellules pré-agrégées). | ≤ 2026-07-31 |
| D4 — Notifier quelqu'un quand un adhérent refuse une cotation ? | **Non, personne pour l'instant** (décision équipe rapportée par PE) ; à revoir plus tard. Le correctif reste noté si ça change : job `NotifCotationRefuseeJob` miroir de `NotifCotationSigneeJob` (créateur via l'audit `create`), branché sur le bloc de `transition!` de `cotations_controller#refuser`. | 2026-07-13 |

### D9 — Incohérences de visibilité entre la liste et la page d'une intervention (signalées le 2026-08-05, aucune corrigée)
Toutes sont **figées par les matrices de caractérisation** : elles ne peuvent plus bouger par accident, mais elles ne sont pas résolues.

1. **L'adhérent voit dans la liste des données que la page détaillée lui cache.** À l'origine 9 : agents, matériel, mots clés, début/fin réels, temps passé, temps total, pause, commentaires, photos. **Partiellement résolu le 2026-08-06 par PE**, dans les deux sens : la page lui donne désormais une section « Intervention » (dates + temps passé, total, pause), et la liste ne lui montre plus les commentaires. **Restent divergents** : agents, matériel, mots clés et photos, visibles dans la liste et absents de la page. À trancher.
2. ~~**Boutons désactivés contre boutons masqués**~~ — **TRANCHÉ le 2026-08-06 par PE** : la liste masque désormais les boutons non déclenchables, comme la page détaillée et l'accueil. Le paramètre `valider_toujours_visible` du partial, qui n'existait que pour reproduire cet écart, a été retiré.
3. **Aucun bouton « Archiver » nulle part** dans l'application, alors que l'action, la route, la policy et les tests existent. L'archivage n'est atteignable qu'en forgeant une requête. Fonctionnalité oubliée, ou à retirer ?
4. **Aucun verrou d'édition par état** : une intervention `archivé` reste modifiable par le manager, l'administrateur, l'agent affecté et l'adhérent, et supprimable par le manager et l'administrateur. Est-ce voulu ?
5. **`InterventionPolicy` ignore le service du manager** : un manager a exactement les mêmes droits sur une intervention d'un service dont il n'est **pas** membre que sur les siennes — alors qu'`ApplicationPolicy#manage?` fait la distinction et que `UserPolicy` l'a explicitement introduite (B61). Volontaire pour les interventions ?
6. **L'adhérent peut télécharger le PDF de l'affiche QR code de pointage** (`can_see_qrcode_pointage_pdf?` = `show? && !agent?`), et le bouton lui est proposé sur un modèle de pointage. Utile, ou fuite d'un outil interne ?
7. ~~**L'adhérent ne voyait plus les dates prévues sur sa page**~~ — **TRANCHÉ et corrigé le 2026-08-06 par PE** : nouveau prédicat `voir_dates_prevues?`, l'adhérent les voit sauf à l'état « pointage activé ». Figé par la sonde `donnee:debut_prevue` de la matrice de visibilité.
8. ~~**La section « Intervention » de l'adhérent était rendue sur un modèle de pointage**~~ (encadré « Non renseigné / 0 h / 0 h / 0 h ») — **TRANCHÉ et corrigé le 2026-08-06 par PE** : sur un modèle, l'adhérent reçoit le **tableau des pointages** comme les autres rôles, colonne « Agent » comprise (`voir_pointages?` n'exclut plus l'adhérent). Figé par les sondes `bloc:pointages` et `donnee:agent_pointage`.

### D11 — ~~Visibilité de l'adhérent repassée en dur dans la vue~~ — **TRANCHÉ et appliqué le 2026-08-06**
`#444` avait rouvert une exception au principe posé le 2026-08-05 (toute la visibilité de la page dans `InterventionPolicy`). Rétabli sur décision de PE :
- `show.html.erb` ne teste plus aucun rôle : trois branches de policy, `voir_pointages?` / `voir_realisation?` / `voir_temps?`.
- Nouveau prédicat `voir_temps?` (= `show? && adhérent? && !record.repeter?`) pour la section « Intervention » de l'adhérent, extraite en partial `show/_temps_adherent.html.erb` — le `<h2>` et les deux sous-partials n'y sont plus dupliqués.
- `voir_agent_des_pointages?`, défini le 2026-08-05 mais **jamais appelé**, pilote enfin la colonne « Agent » du tableau des pointages, qui testait `current_user.agent?` en dur à trois endroits (en-tête, cellule, `colspan`).
- Le `unless current_user.adhérent?` devenu mort dans `show/_assignation.html.erb` a été retiré par PE.

### D10 — Fusion des deux formulaires d'intervention
Le découpage du 2026-08-05 a ramené `_form` à 83 lignes d'ossature et `_form_for_agents` à 172, tous deux consommant les mêmes blocs. Il ne reste que **trois** différences réelles, toutes visibles en tête de `_form_for_agents` :
- pas de champ description, et le service est figé sur `current_user.services.first` ;
- l'adhérent n'est modifiable que sur un bon saisi par un agent (`bon?` et hors pointage) ;
- les dates réelles sont **toujours** obligatoires et disposées côte à côte, là où l'autre formulaire ne les exige qu'à la terminaison.
Les deux premières s'expriment déjà par des prédicats de policy (`saisir_description?`, `choisir_service?`, `choisir_adherent?`). **À trancher : fusionne-t-on ?** Le gain serait un seul formulaire ; le coût, une troisième condition sur la disposition et l'obligation des dates.

### D8 — ✅ TRANCHÉ (2026-08-07) — Import XLS : comment **changer** le service d'un agent, maintenant qu'il n'en a droit qu'à un seul ? (agent, 2026-08-02)
- **Contexte** : la règle « un agent a exactement un service » (demande PE du 2026-08-02) a une conséquence non demandée sur l'import XLS des agents. `users#import_do` **cumule** les services (`user.user_services.build(service:)` si le rattachement n'existe pas encore) et force `rôle = 'agent'`. Donc : réimporter le **même** service est sans effet (idempotent, inchangé) ; importer un service **différent** produit un agent à 2 services → la validation refuse → la ligne part **en erreur** avec « Services ne doit comporter qu'un seul service pour un agent ». **Changer le service d'un agent par import est donc devenu impossible.**
- **Effet de bord positif, non recherché** : cette même validation bloque désormais la plupart des rétrogradations silencieuses de **B21** (un manager cité par mégarde dans le fichier n'est plus transformé en agent, sauf s'il est mono-service et que la ligne reprend justement ce service — cas épinglé par un test).
- **Options** : (a) laisser tel quel, le changement de service se fait à la main dans la fiche — le plus simple, l'import reste un outil de **création** ; (b) faire **remplacer** le service au lieu de cumuler quand la cible est un agent ; (c) rendre le message d'erreur explicite (« cet agent est déjà rattaché à X, retirez-le d'abord »). *Rien n'a été changé dans l'import : seuls ses tests ont été mis à jour.*
- ✅ **TRANCHÉ le 2026-08-07 — option (b), le service du fichier REMPLACE celui de l'agent** (décision PE) : l'import sert aussi aux réaffectations, et c'est ce qu'un utilisateur attend d'un fichier de référence. Implémenté dans `ImportUtilisateursXls#rattacher_service` : les rattachements qui ne sont pas celui de la ligne sont marqués pour destruction, puis réellement détruits dans la **même transaction** que l'enregistrement. ⚠️ Point non trivial mesuré par sonde : `mark_for_destruction` **n'est pas honoré par `save`** (l'association `user_services` n'est pas en autosave) — s'en remettre à lui aurait produit un agent à 2 services en base alors que la validation, elle, passe. En mode simulation rien n'est détruit (test dédié). Le bilan affiche « Service : Technique → Informatique ».
- **L'effet de bord positif sur B21 est désormais sans objet** : B21 est corrigé à la source (aucun compte existant non-agent n'est modifiable par l'import), la protection ne repose plus sur la validation « un seul service ».

### D12 — ✅ TRANCHÉ (2026-08-06) — Les 7 interventions de dev dont l'agent est hors du service (= **B78**)
**Décision PE : purge.** Les 136 interventions invalides de la base de dev (dont ces 7) ont été supprimées, après réparation des filles de pointage sans adhérent — celui du modèle est repris, et la fille n'est supprimée que si le modèle est introuvable ou qu'elle reste invalide (1 seul cas concerné, `#171`, réparée et conservée). Reste 226 interventions, **toutes valides**, 0 fille orpheline, 0 convention à heures négatives. Sauvegarde `pg_dump` prise avant la purge. **La question reste entière côté prod** : la validation est permanente, le volume n'y a pas été mesuré, et une purge n'y est évidemment pas envisageable. Détail des motifs ci-dessous.


La validation `service_partagé_par_adherent_et_agents` fige 7 interventions de la base de dev. Le pendant adhérent (29 lignes) a été réglé en rattachant l'adhérent au service ; pour un **agent**, `agent_must_have_exactly_one_service` interdit ce recours. Quatre issues, toutes avec un coût :
1. **Retirer l'agent** de l'intervention — on perd la trace de qui a réalisé le travail, et `#383` est `terminé` donc exige au moins un agent (il faudrait lui en réassigner un du bon service).
2. **Ajouter le service manquant à l'agent** — viole l'invariant « un agent, un service ». À noter : BERNARD André l'enfreint **déjà** (Technique + Prévention), donc la base n'est pas homogène sur ce point non plus.
3. **Changer le service de l'agent** — casse ses autres interventions, qui deviendraient à leur tour hors règle.
4. **Changer le service de l'intervention** — écarté par PE le 2026-08-06.
La même question se posera en **prod** au déploiement : il faut mesurer le volume avant, la validation étant permanente. Voir aussi D8 (même invariant, autre symptôme).
