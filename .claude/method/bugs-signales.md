# Registre des bugs signalés — CoopComm

> **Source de vérité unique** des bugs détectés par l'agent (sessions de tests/audit), signalés mais **non corrigés** sans décision explicite. Chaque bug a un **parcours de reproduction** (point de vue utilisateur quand c'est possible). Tenir à jour : quand un bug est corrigé, le déplacer dans la section « Corrigés » avec le commit. Dernière re-vérification dans le code : **2026-07-10**.

---

## 🔴 Bugs ouverts

### B1 — `temps_total` jamais recalculé à la sauvegarde (`calc_temps_total` inopérant)
- **Où** : [intervention.rb:363-373](app/models/intervention.rb#L363-L373) (+ `before_save :calc_temps_total` à la ligne 52)
- **Cause** : la méthode assigne une variable **locale** `temps_total` au lieu de `self.temps_total = …` → le callback `before_save` ne persiste rien. Le pointage QRCode fonctionne par accident (le contrôleur assigne la valeur à la main).
- **Parcours de reproduction** :
  1. En tant qu'**agent**, j'ouvre une intervention et je fais une **saisie de temps a posteriori** (formulaire : date/heure de début, de fin, pause).
  2. J'enregistre → le champ `temps_total` en base reste `nil` (ou garde son ancienne valeur), alors que début/fin sont bien remplis.
  3. Ensuite, en tant que **manager/admin**, sur le **dashboard**, la répartition du temps par agent et les totaux d'heures sont faux (cette intervention compte pour 0).
- **Impact** : statistiques de temps fausses pour toute intervention saisie a posteriori.
- **Trace test** : test `skip` documenté dans `test/models/intervention_pointage_test.rb` (session 2026-07-08-c) — passera au vert à la correction.
- **Correctif proposé** : `self.temps_total = …` (et retirer le calcul manuel du contrôleur, ou le garder comme redondance inoffensive).

### B2 — Prix du devis écrasé par le tarif courant à la création de la commande (décision métier à prendre)
- **Où** : [create_commande_from_cotation.rb:19](app/services/create_commande_from_cotation.rb#L19) + `CommandeLigne#set_prix_from_prestation` ; symétrique dans `create_facture_from_commande.rb:19`
- **Cause** : le service copie bien `prix_ht`/`total_ht` du devis, mais le callback de `CommandeLigne` les **écrase avec le tarif actuel** de la prestation (`total_ht` est de toute façon une colonne générée).
- **Parcours de reproduction** (confirmé empiriquement le 2026-07-08) :
  1. En tant que **manager**, je crée une cotation avec une prestation à **25,50 € HT** (3 unités → devis à 76,50 €). Je l'envoie, l'**adhérent la signe**.
  2. Entre-temps, le **tarif de la prestation** est modifié à **40 € HT** (admin, écran Prestations).
  3. Je crée la **commande depuis la cotation signée** → les lignes de commande affichent **40 €** : commande à **120 €** pour un devis signé à **76,50 €**.
  4. Même mécanique de la commande vers la **facture**.
- **Impact** : l'adhérent est facturé à un prix différent de celui qu'il a signé.
- **À trancher (client)** : le prix contractuel est-il celui du devis signé (probable) ou le tarif courant ? Correctif technique trivial une fois tranché (ne pas écraser si `prix_ht` déjà renseigné). **Statut 2026-07-10 : en réflexion** — suivi comme **D1** dans `points-a-trancher.md`.

### B3 — `valider`/`refuser` une intervention hors état → erreur 500
- **Où** : [interventions_controller.rb:312-326](app/controllers/interventions_controller.rb#L312-L326)
- **Cause** : `valider!` et `refuser!` sont appelés **sans garde `can_valider?`/`can_refuser?`** ni `rescue Workflow::NoTransitionAllowed` (contrairement à `terminer` et `archiver` qui sont protégés).
- **Parcours de reproduction** (déduit, non exécuté) :
  1. En tant qu'**adhérent** (ou manager), j'ouvre une intervention à l'état **terminé** et je clique **« Valider »** → OK, elle passe à `validé`.
  2. Je fais **retour arrière** navigateur (ou j'avais l'onglet ouvert en double) et je re-clique **« Valider »** ou **« Refuser »** alors qu'elle n'est plus `terminé`.
  3. → `Workflow::NoTransitionAllowed` non rescué → **page d'erreur 500**.
- **Impact** : erreur brute au lieu d'un message « action impossible » ; du bruit dans les logs.
- **Correctif proposé** : même motif que `terminer`/`archiver` (`if @intervention.can_valider? … else redirect_to … notice: "Impossible…"`).
- **Trace test (2026-07-28)** : test `skip` documenté dans les TESTS CRITIQUES en tête de `interventions_controller_test.rb` (« re-valider une intervention déjà validée… ») — passera au vert à la correction.

### B4 — Sujet du mail de panne malformé : `{title: "…"}`
- **Où** : [notif_panne_job.rb:12-18](app/jobs/notif_panne_job.rb#L12-L18) vs `NotificationMailer#avertissement_reservation`
- **Cause** : le job passe `title:` en **argument nommé**, mais le mailer attend `title` en **positionnel** → le hash devient le dernier paramètre positionnel et l'objet du mail rend littéralement `{title: "[COOPCOMM] L'outil X a été déclaré en panne"}`.
- **Parcours de reproduction** :
  1. En tant qu'**adhérent A**, je **réserve un outil** dans le magasin (clic sur une case du planning matériel) pour une date à venir.
  2. En tant qu'**agent/manager**, je **déclare ce même outil en panne** (clic sur la case panne) — zone sensible `Mouvement`.
  3. → `NotifPanneJob` envoie le mail d'avertissement au réserviste A : le corps est correct, mais l'**objet** du mail est le hash brut au lieu du texte.
- **Impact** : cosmétique mais très visible (mail réel envoyé au client avec un sujet cassé).
- **Correctif proposé** : aligner l'appel sur la signature (passer `title` en positionnel, ou convertir la signature en kwargs partout).

### B5 — Mails de bienvenue d'import jamais tracés dans MailLog
- **Où** : [welcome_import_notification_job.rb:15-16](app/jobs/welcome_import_notification_job.rb#L15-L16)
- **Cause** : `MailLog.create` sans `organisation_id` (colonne **NOT NULL**) → le `create` (non-bang) échoue **en silence** ; le mail part, le log n'est jamais persisté.
- **Parcours de reproduction** :
  1. En tant qu'**admin**, j'**importe des utilisateurs** (import fichier) → chaque nouvel utilisateur reçoit bien son mail de bienvenue avec mot de passe.
  2. Je vais sur l'écran **MailLog** (affichage livré en #354) → **aucune trace** de ces envois.
- **Impact** : trou dans l'audit des envois ; impossible de prouver/déboguer qu'un utilisateur importé a reçu son accès.
- **Correctif proposé** : dériver `organisation_id` (via l'organisation du user importé) + envisager `create!` pour ne plus échouer en silence.

### B6 — `user.organisation =` → NoMethodError (code mort, piège à la réactivation)
- **Où** : [user.rb:188](app/models/user.rb#L188) (`User.from_omniauth`) et [registrations_controller.rb:16](app/controllers/users/registrations_controller.rb#L16)
- **Cause** : `organisation` est dérivé (`has_many :organisations, through: :services`) → **pas de writer** `organisation=` (vérifié : `respond_to?(:organisation=)` → false).
- **Parcours de reproduction** (conditionnel — code mort aujourd'hui : `:registerable` et `:omniauthable` sont commentés dans Devise) :
  1. Un développeur **réactive** l'inscription publique ou la connexion **Google OAuth**.
  2. Un nouvel utilisateur s'inscrit / se connecte via Google → **crash 500 NoMethodError** à la création du compte.
- **Impact** : nul aujourd'hui ; bloquant le jour où on réactive ces flux.
- **Correctif proposé** : supprimer ces lignes ou affecter via un service (`user.services << …`).

### B7 — Fixture `intervention_validé` invalide (test uniquement)
- **Où** : [interventions.yml:43](test/fixtures/interventions.yml#L43)
- **Cause** : écrite `adherent_id: weil` (raccourci non résolu par les fixtures — il faut `adherent: weil`) → `adherent_id` reste nil → enregistrement invalide.
- **Reproduction** (pas de parcours utilisateur — donnée de test) : tout nouveau test qui tente une **transition workflow** sur cette fixture lève `ActiveRecord::RecordInvalid`.
- **Impact** : piège pour les prochains tests ; aucune conséquence en prod.
- **Correctif proposé** : `adherent: weil`.

### B8 — Risque différé : notif `EmailSubscription` crashe sur les audits sans user (dormant, décision client 2026-06-23)
- **Où** : `EmailSubscription#on_intervention_updated` (`intervention.audits.last.user_id` sans garde)
- **Cause** : mesuré en dev, **599/902 audits** d'intervention ont `user_id` nil (jobs/imports sans `current_user`) et **166 interventions** ont leur *dernier* audit à `user_id` nil → `User.find(nil)` → `RecordNotFound`.
- **Parcours de reproduction** (conditionnel — la souscription est **dormante**, décision client de ne pas y toucher) :
  1. Un développeur **active** la notification « intervention mise à jour ».
  2. N'importe quel utilisateur **modifie** une des 166 interventions dont le dernier audit n'a pas de user → **crash** de la mise à jour.
- **Correctif à l'activation** : `User.find_by(id:)` + `return if user.nil?`.

### B11 — Un pointage peut porter des dates prévues (héritées de la mère ou saisies au formulaire) — l'invariant « pointage = dates réelles uniquement » n'est pas garanti
- **Signalé par** : PE, 2026-07-13 (« il ne faut pas que l'on puisse mettre des dates prévues sur une intervention de pointage ») ; instruit et confirmé par l'agent. Généralise la condition 4 de **R1**.
- **Où** : [intervention.rb:342-357](app/models/intervention.rb#L342-L357) (`create_next_intervention` : `dup` de la mère sans remise à nil de `début_prévue`/`fin_prévue`) ; [_form.html.erb:63](app/views/interventions/_form.html.erb#L63) (les champs prévus s'affichent si `!repeter` — or une fille a `repeter: false`) ; [interventions_controller.rb:569-570](app/controllers/interventions_controller.rb#L569-L570) (`intervention_params` permet `début_prévue`/`fin_prévue` pour tous les rôles).
- **Cause** : deux chemins indépendants. (1) **Héritage** : le `dup` copie les dates prévues de la mère — **vérifié empiriquement le 2026-07-13** (`m.dup.fin_prévue` non nil) ; 4 mères en base de dev en portent (dont la #311 « test pointage avec dates prévues » — aucune n'a encore de fille, d'où l'absence du cas en base). (2) **Édition** : le formulaire d'édition d'une fille affiche les champs prévus et le contrôleur les accepte.
- **Précision 2026-07-13 (PE)** : la création d'une mère passe aujourd'hui par le **flux dédié** `new_intervention_modele_pointage` ([interventions_controller.rb:477-480](app/controllers/interventions_controller.rb#L477-L480)) qui force `repeter = true` avant le rendu → champs prévus masqués, et **aucune case « répéter »** ne subsiste dans les vues (vérifié). Donc **plus aucune mère neuve ne peut recevoir de dates prévues via l'UI**. Les vecteurs restants : (a) **mères historiques** créées avant ce flux — elles gardent leurs dates prévues et l'UI ne permet plus de les retirer (champs masqués à l'édition d'une mère) → à nettoyer en données (prod) ; (b) **édition d'une fille** (chemin formulaire ci-dessus) ; (c) requête forgée — `intervention_params` permet toujours `début_prévue`/`fin_prévue`/`repeter` sur tous les flux, y compris `create_intervention_modele_pointage`.
- **Parcours de reproduction** (via une mère historique ou une fille éditée) :
  1. Une **mère antérieure au flux dédié** porte encore des dates prévues (l'UI ne permet plus de les voir ni de les retirer).
  2. En tant qu'**agent**, je **scanne le QR** de cette mère → la fille naît avec `fin_prévue` héritée.
  3. Conséquences : (a) `pointage_ouvert?` (= `effective_fin.blank?`, [intervention.rb:99-101](app/models/intervention.rb#L99-L101)) est **faux** → la garde `agents_must_not_have_open_pointage` est **contournée** (à la fois comme déclencheur et comme conflit détectable — cf. R1.4) ; (b) `agents_must_be_available` (via `OVERLAP_SQL` sur les plages **effectives**) considère l'agent occupé de son **début réel** jusqu'à la **fin_prévue de la mère** — potentiellement des semaines (ex. mère #278 : 21/05 → 18/06) → toute autre intervention de l'agent sur la fenêtre est refusée.
- **Impact** : garde anti-double-pointage neutralisée + faux conflits de disponibilité massifs, dès qu'une mère à dates prévues est scannée.
- **Correctif proposé** : imposer l'invariant à la source — `début_prévue = nil` / `fin_prévue = nil` dans `create_next_intervention` ; en ceinture-bretelles, validation interdisant les dates prévues quand `template_slug` est présent (couvre aussi le chemin formulaire). **Une fois l'invariant garanti**, le `.where(fin_prévue: nil)` de `agents_must_not_have_open_pointage` ([intervention.rb:271](app/models/intervention.rb#L271)) devient effectivement redondant (le conserver reste inoffensif et cohérent avec `pointage_ouvert?`).
- **Statut 2026-07-13 (mis à jour) : périmètre tranché par PE.**
  - **Données prod nettoyées** (confirmé PE) : plus aucune mère historique avec dates prévues → le vecteur « héritage via `dup` » est neutralisé (flux dédié `new_intervention_modele_pointage` pour les mères neuves + données propres). Le reset dans `create_next_intervention` est jugé inutile.
  - **Inventaire complet des écritures vérifié par l'agent** : aucune assignation programmatique de `début_prévue`/`fin_prévue` dans le code — seule voie = mass assignment `intervention_params`. Le **seul chemin restant** est donc le formulaire d'édition d'une fille.
  - **Décision équipe (probable)** : retirer les champs prévus du formulaire d'édition d'une **fille** (`template_slug` présent — ⚠ la condition [_form.html.erb:63](app/views/interventions/_form.html.erb#L63) est `!repeter`, vraie pour une fille → ajouter `template_slug.blank?`). Les **params ne seront probablement pas filtrés** — risque « requête forgée » **accepté explicitement par PE** (utilisateurs internes non malveillants).
  - **Conséquence sur `.where(fin_prévue: nil)`** ([intervention.rb:271](app/models/intervention.rb#L271)) : une fois les champs retirés du formulaire, la condition devient **morte en pratique** et pourra être retirée sans changement de comportement (`pointage_ouvert?` n'a pas besoin de bouger : `effective_fin` ≡ `fin` pour une fille sans dates prévues). Rappel : cette condition ne protégeait de rien — elle **excluait** au contraire des conflits une fille porteuse de `fin_prévue` (cohérence avec `pointage_ouvert?`, pas une garde).
  - **Reste à faire** : le retrait effectif des champs (équipe) ; ce bug passera en « corrigé » à ce moment-là.

### B13 — Branche `dashboard-scenic` : le filtre #292 opère sur les cellules pré-agrégées, pas par intervention (un négatif peut être « netté » au lieu d'exclu)
- **Signalé le** : 2026-07-13 (même session). **Spécifique à `dashboard-scenic`** — staging filtre au grain intervention.
- **Où** : tous les `where("temps_total >= 0")` de [dashboard_data.rb](app/controllers/concerns/dashboard_data.rb) — ils s'appliquent aux lignes des vues matérialisées : grain **(org, service, adhérent, mois, statut)** pour les stats interventions, grain **(org, agent)** pour le temps par agent.
- **Cause** : une vue matérialisée ne stocke que des sommes par cellule. Si une cellule mélange +8 h et −3 h, elle vaut 5 ≥ 0 → elle **passe** le filtre et le −3 est compté (staging strict : 8). Si le net d'une cellule/d'un agent est négatif, **tout** est exclu, y compris la part positive (staging : la part positive reste).
- **Statut de la décision** : le volet **grain agent** a été **acté par PE le 2026-07-13** (résolution du conflit de merge, « approximation au grain agent »). Le volet **grain cellule** (stats interventions) n'a pas été discuté explicitement — même nature, porté à connaissance ici.
- **Parcours de reproduction** :
  1. Un adhérent a, le **même mois**, sur le **même service** et au **même statut**, une intervention à +8 h et une à −3 h.
  2. Dashboard manager → le KPI « temps total » compte **5 h** pour ce mois (au lieu de 8 h avec le #292 strict).
- **Impact** : faible tant que les temps négatifs restent rares (un seul connu en prod) ; l'écart ne se voit que si positif et négatif cohabitent dans la même cellule.
- **Trace test** : 2 tests « ÉPINGLAGE B13 » dans `test/controllers/dashboard_temps_negatif_test.rb` figent le comportement actuel (net agent 9−5=4 ; cellule 8−3=5) — **à inverser** si le grain intervention est finalement retenu.
- **Correctif proposé (si l'exactitude est voulue)** : ajouter aux deux vues une colonne `temps_total_positif` (`SUM(CASE WHEN temps_total >= 0 THEN temps_total ELSE 0 END)` — au grain intervention, donc exact) et faire pointer les calculs de temps du concern dessus ; les `where` disparaissent. Migration Scenic `update_view` (⚠ piège connu : ne pas ré-ajouter les index à la main).

### B14 — Éditer une intervention dont le service n'est plus proposé pour son adhérent **change le service silencieusement** (le formulaire ne sait pas conserver la valeur d'origine)
- **Signalé le** : 2026-07-15 (découvert en écrivant les tests système du refresh dashboard).
- **Où** : [interventions_controller.rb:455-461](app/controllers/interventions_controller.rb#L455-L461) (`services_for_adherent` : options = services de l'adhérent ∩ services du manager) + [dynamic_select_controller.js](app/javascript/controllers/dynamic_select_controller.js) (`updateServices` → `populateSelect` **remplace** les options au chargement de l'édition, la valeur d'origine est perdue si elle n'est pas dans la liste).
- **Parcours de reproduction** :
  1. En manager (hidalgo), ouvrir l'édition de `tonte_locaux` (service **Technique**, adhérent weil qui n'est rattaché qu'à **Informatique**).
  2. Le select Service est repeuplé avec la seule option « Informatique » — « Technique » n'est plus proposé ; le champ est `required`.
  3. Modifier n'importe quoi (la description) et enregistrer → obligé de choisir « Informatique » → **le service de l'intervention change** sans que l'utilisateur l'ait voulu (effets en cascade : périmètre des index filtrés par service, dashboard par service, agents proposés — la liste des agents est bornée au service choisi → les agents de l'ancien service disparaissent des options).
- **Aggravant** : les données existantes (fixtures ET prod potentiellement) contiennent des interventions dont le service ∉ services de l'adhérent — créées avant cette règle ; elles sont toutes concernées à la première édition.
- **Quirk lié (comportement, pas bug)** : quand la liste ne contient qu'une option, elle est auto-sélectionnée, et **re-cliquer dessus la désélectionne** (toggle slim-select) — un utilisateur peut se retrouver avec un champ vide sans comprendre.
- **Correctif proposé** (décision métier à prendre) : inclure le service ACTUEL de l'intervention dans les options renvoyées à l'édition (union avec la valeur d'origine), ou avertir explicitement du changement.
- **Trace test** : contrainte documentée dans l'en-tête de `test/system/manager/dashboard_refresh_manager_flow_test.rb` (les tests contournent en préparant des données cohérentes : agents ajoutés à Informatique ; ⚠ la fixture `bond_informatique` pointe en réalité vers **service_paris** — nom trompeur).

---

### B17 — `purge` : l'audit peut être silencieusement perdu si l'intervention est devenue invalide
- **Signalé** : 2026-07-15, même session.
- **Où** : [interventions_controller.rb:343](app/controllers/interventions_controller.rb#L343) — `@intervention.update(audit_comment: …)` sans bang ni branche d'échec.
- **Cause/scénario (déduction, non reproduit)** : la photo est purgée **avant** l'update ; si les validations échouent (ex. `agents_must_be_available` #357 devenue fausse depuis la création), l'audit « Photo n°X supprimée » n'est **pas** écrit, mais l'utilisateur voit quand même la notice « Photo supprimée ». Le cas nominal est couvert par un test (« la suppression est tracée dans l'audit trail », vert).
- **Impact** : trou ponctuel d'audit trail, faible.
- **Correctif proposé** : à instruire — écrire l'audit sans dépendre des validations de l'intervention (ou au minimum logguer/alerter en cas d'échec de l'update).

### B18 — ✅ CORRIGÉ (2026-07-21) — Le filtre Services de l'index interventions était sans effet pour l'adhérent
- **Signalé par** : PE, 2026-07-21 (« en tant qu'adhérent, je choisis un service et rien n'est restreint »).
- **Parcours de repro** : se connecter comme adhérent membre de ≥2 services → index interventions → choisir un service dans le filtre → la liste n'est pas restreinte.
- **Où** : [interventions_controller.rb:30](app/controllers/interventions_controller.rb#L30) — `Intervention.filter_by_service(selected_services).by_role_for(current_user)`.
- **Cause racine (prouvée empiriquement, SQL généré)** : `by_role_for` ([intervention.rb:187](app/models/intervention.rb#L187)) est une méthode de classe qui, pour l'**adhérent** (et l'agent), repart d'une association fraîche (`user.interventions_adherent` / `user.interventions`), **jetant** le `filter_by_service` chaîné avant → le SQL adhérent ne gardait que `WHERE adherent_id`, jamais `WHERE service_id`. Manager/admin non touchés (`by_role_for` y renvoie `ordered`, chaîné).
- **Piège du correctif naïf** : inverser simplement les deux appels masquerait par défaut toutes les interventions d'un adhérent situées dans des services dont il n'est pas membre (cf. fixture `weil` : membre `informatique`, interventions en `technique`).
- **Correctif appliqué (sensible au rôle)** : périmètre de rôle d'abord, puis `filter_by_service` **seulement si** `manager_or_admin?` (chez qui le filtre borne le périmètre, indispensable) **ou** si un service est explicitement choisi (`@selected_service_ids.present?`). L'agent n'a pas ce filtre dans l'UI → inchangé. 2 tests de régression adhérent dans `interventions_index_service_filter_test.rb`, prouvés rouges sur l'ordre bogué.
- **Reste ouvert (hors périmètre)** : le menu propose à l'adhérent ses services **membres** (`@services`), pas les services de ses interventions — s'ils divergent, un choix peut donner 0 résultat.
- **Statut 2026-07-21 : non-problème en pratique (décision PE).** Une intervention dont le service ∉ services de l'adhérent ne peut survenir par l'UI qu'avec un **agent à ≥2 services** (le `_form_for_agents.erb:34` fige `service_id` sur `current_user.services.first` tandis que la liste d'adhérents couvre tous ses services) — or **un agent n'a normalement qu'un seul service**. Le `_form` manager en **création** est sain (l'adhérent `include_blank` force `updateServices`). **Pas de validation model souhaitée** (« ils ne devraient pas le faire »). Aucune correction. La fixture `weil` (membre `informatique`, interventions en `technique`) est un artefact de test, pas un cas réel.

### B19 — Un outil rattaché à des interventions peut être supprimé (garde-fou UI perdu à la refonte `fc5330c4`)
- **Signalé par** : agent, 2026-07-24 (surfacé en fiabilisant `tools_test` : l'assertion « bouton masqué » visait un id disparu → faux positif qui masquait la régression).
- **Parcours de repro** : se connecter en manager/admin → fiche d'un outil **utilisé dans des interventions** (fixture `tondeuse`) → le bouton « Supprimer » est affiché → modale → « Oui, supprimer » → l'outil est **réellement supprimé** (les `tool_interventions` sont détruits en cascade `dependent: :destroy`, les interventions perdent leur lien outil).
- **Où** : [app/views/tools/show.html.erb:17](app/views/tools/show.html.erb#L17) (bouton affiché sous la seule garde `policy(@tool).destroy?`) + [app/controllers/tools_controller.rb:83](app/controllers/tools_controller.rb#L83) (`@tool.destroy!` sans garde) + [app/models/tool.rb:11](app/models/tool.rb#L11) (`has_many :tool_interventions, dependent: :destroy`).
- **Cause racine (prouvée par git)** : le commit `fc5330c4` (« UX -show tools ») a retiré la branche `<% if @tool.interventions.any? %>` qui, avant, remplaçait le bouton (`id="supprimer_outil"`) par un bloc inerte « Suppression impossible, l'outil est utilisé dans des interventions ». `ToolPolicy#destroy?` = `manager_or_admin? && organisation?` **n'a jamais** regardé les interventions ; la protection était uniquement dans la vue (donc déjà contournable par requête forgée — le contrôleur `destroy` n'a aucune garde).
- **Impact** : perte de données potentielle (rattachements outil↔interventions) déclenchable en 2 clics ; historique des interventions faussé.
- **Correctif proposé (décision métier à trancher)** : soit **restaurer la protection** — re-masquer/désactiver le bouton pour `@tool.interventions.any?` **ET** ajouter une garde dans `tools_controller#destroy` (redirection + message si l'outil est utilisé), la vue seule étant contournable ; soit **assumer** la suppression libre (et alors supprimer le test `Ne pas pouvoir supprimer un outil avec une intervention`). Test correspondant en `skip` documenté jusqu'à décision.
- **⚠️ MISE À JOUR 2026-07-29 — corrigé À MOITIÉ** : le commit `756dfdcd` (#412, Dani) a **restauré la garde côté vue** (bloc « Suppression impossible, l'outil est utilisé dans des interventions » à la place du bouton). Le `skip` du test système est donc **levé** (`test/system/tools_test.rb`, assertion réelle au vert). **La garde contrôleur manque toujours** : [tools_controller.rb:94](app/controllers/tools_controller.rb#L94) fait `@tool.destroy!` sans rien vérifier — vérifié empiriquement, un `DELETE /tools/:slug` direct supprime l'outil `tondeuse` et ses `tool_interventions`. Comportement épinglé par le test `un outil utilisé par une intervention est quand même supprimé` (`tools_controller_test.rb`), **à inverser à la correction**.

### B36 — Grille des disponibilités : le jour où une panne est déclarée s'affiche « réservé par vous » au lieu de « en panne »
- **Signalé par** : agent, 2026-07-29 (session `/tests` « matériel », reproduit par test).
- **Parcours de repro** : se connecter en manager → *Réservation de matériel* (`/tools`) → repérer un outil **libre toute la semaine** → cliquer sur *Gestion panne* (ou `/mouvements/new?tool_id=…`) → déclarer une panne à une date **de la semaine affichée**, par exemple le mercredi → revenir à `/tools`. **Observé** : la case du **mercredi** est **bleu foncé** avec l'infobulle « Réservé par vous (cliquez pour libérer) », alors que jeudi→dimanche sont bien en **rouge** « En panne ». Cliquer sur la case bleue déclenche `libere`, qui ne trouve aucune réservation et affiche l'alerte trompeuse « Il n'existe pas de réservation ce jour-là pour cet utilisateur ». *(Le décalage se voit mieux en déclarant la panne en milieu de semaine ; une panne déclarée avant le lundi affiché est correctement rouge sur toute la semaine.)*
- **Où** : [app/models/tool.rb:136](app/models/tool.rb#L136) — `current_state = "R"` dans la branche `if etats["panne"].present? && etats["fin_panne"].blank?`.
- **Cause racine (prouvée par test)** : `est_en_panne` est initialisé par `est_encore_en_panne_le(first_date)`, qui ne regarde que les mouvements **antérieurs ou égaux au premier jour** de l'intervalle. Une panne déclarée *dans* l'intervalle n'est donc pas encore connue le jour même : on tombe dans la branche `else`, qui pose `"R"` (la lettre de « réservé par moi ») avant de basculer `est_en_panne = true` pour les jours suivants. La lettre attendue est `"P"`.
- **Impact** : un outil hors service est présenté comme réservé par l'utilisateur courant le jour de la panne ; le clic propose une action impossible. Sur le mois affiché par `tools#show` le même calcul sera utilisé si la vue est refaite comme l'index (cf. `points-a-trancher.md`).
- **Correctif proposé** : `current_state = "P"` au lieu de `"R"` (une ligne). Tests correspondants : `tool_test.rb` → `le jour de déclaration dune panne est marqué en panne` (en `skip`, passera au vert à la correction) et `un cycle panne puis réparation puis nouvelle panne est retracé` (épingle le `R` actuel, à passer en `P`).

### B37 — `Tool#dernier_mouvement_a` lève `NoMethodError` dès que les mouvements sont déjà chargés
- **Signalé par** : agent, 2026-07-29 (session `/tests` « matériel », reproduit par test).
- **Parcours de repro** : fiche d'un outil (`tools#show`, vue calendrier) après que l'association `mouvements` a été chargée en mémoire dans la même requête (une itération `@tool.mouvements.each`, un `includes(:mouvements)`, un `render` de collection…). La branche « déjà chargés » du tri lève alors `NoMethodError: undefined method 'to_i' for an instance of Date` → **erreur 500**. Aujourd'hui la vue appelle la méthode sans avoir chargé l'association, donc c'est la branche SQL qui s'exécute et le bug reste dormant.
- **Où** : [app/models/tool.rb:84](app/models/tool.rb#L84) — `sort_by { |m| -m.date.to_i }`.
- **Cause racine (prouvée par test)** : `mouvements.date` est une colonne **`date`** (cf. `db/schema.rb`, `t.date "date"`), pas `datetime` → `m.date` est un `Date`, qui n'a pas de `#to_i` (contrairement à `Time`/`DateTime`). La branche SQL, elle, trie en base et ne rencontre jamais le problème — d'où l'asymétrie.
- **Impact** : 500 latent sur la fiche outil, qui se déclenchera au premier `includes(:mouvements)` ajouté pour corriger un N+1 (donc typiquement lors d'une optimisation).
- **Correctif proposé** : trier sur la date elle-même (`sort_by(&:date).reverse`, ou `min_by`/`max_by`) plutôt que sur `-date.to_i`. Test correspondant : `tool_test.rb` → `dernier_mouvement_a répond la même chose que les mouvements soient chargés ou non` (en `skip`).

### B38 — Créer un outil ne pose aucun mouvement : le `after_create` échoue en silence
- **Signalé par** : agent, 2026-07-29 (session `/tests` « matériel », reproduit par test).
- **Parcours de repro** : se connecter en manager → *Réservation de matériel* → *Ajouter un outil* → enregistrer. **Observé** : l'outil est créé mais aucun mouvement ne lui est associé (`SELECT count(*) FROM mouvements WHERE tool_id = …` → 0), alors que le code prétend en poser un.
- **Où** : [app/models/tool.rb:160](app/models/tool.rb#L160) — `mouvements.create(état: 0, date: DateTime.now)`.
- **Cause racine (prouvée par test)** : `Mouvement` déclare `belongs_to :user` et l'application charge `config.load_defaults 7.1` → l'appartenance est **obligatoire** ; la colonne `mouvements.user_id` est d'ailleurs `null: false`. L'appel ne fournit aucun utilisateur → la validation échoue, et comme il s'agit d'un `create` **sans bang** l'échec est avalé. Piège de lecture : `tool.mouvements` renvoie quand même l'objet non persisté (une association `has_many` ajoute au tableau en mémoire même quand la sauvegarde échoue) — d'où l'illusion que ça fonctionne.
- **Impact** : faible aujourd'hui (personne ne dépend de ce mouvement initial), mais le code ment sur ce qu'il fait. **Question métier ouverte** : un outil neuf doit-il vraiment naître « réservé » par personne ? Si oui il faut un utilisateur ; sinon la ligne est à supprimer.
- **Correctif proposé** : trancher l'intention, puis soit supprimer le `after_create`, soit lui passer un utilisateur explicite et passer en `create!` pour que l'échec ne soit plus silencieux. Test correspondant : `tool_test.rb` → `créer un outil ne pose aucun mouvement` (**épinglage** du comportement actuel, à inverser).

### B39 — `Tool.indisponibles_ids` interroge une colonne qui n'existe pas (code mort)
- **Signalé par** : agent, 2026-07-29 (session `/tests` « matériel »).
- **Parcours de repro** : aucun — la méthode n'a **aucun appelant** dans `app/`. Elle lèverait `ActiveRecord::StatementInvalid` au premier usage.
- **Où** : [app/models/tool.rb:60](app/models/tool.rb#L60) — `Intervention.joins(:tools).where(organisation_id:)`.
- **Cause racine** : la table `interventions` n'a pas de colonne `organisation_id` (l'organisation dérive du service) — même famille que les quatre bugs `organisation_id` des jobs corrigés le 2026-07-01.
- **Impact** : nul aujourd'hui, piège à la première réutilisation. `Tool#disponible?` (l.68) est également sans appelant, mais lui fonctionne.
- **Correctif proposé** : supprimer les deux méthodes mortes, ou corriger le filtre en passant par `services`. Non testé (code mort).

### B20 — Import XLS : un agent peut être rattaché au service d'une **autre organisation**
- **Signalé par** : agent, 2026-07-27 (session `/tests` « import des utilisateurs »).
- **Parcours de repro** : se connecter en manager/admin de la commune A → *Utilisateurs → Import agents* → fichier dont la colonne `Service` porte le nom d'un service qui n'existe que dans la commune B (ex. `Voirie`) → « Oui (Appliquer) » → l'agent est créé et rattaché au service de B ; comme l'organisation dérive des services, **le nouvel agent appartient à l'organisation B**.
- **Où** : [users_controller.rb:259](app/controllers/users_controller.rb#L259) — `Service.find_by(nom: service_name)`, sans filtre d'organisation.
- **Cause racine (prouvée par test)** : l'unicité de `Service#nom` est scopée à l'organisation ([service.rb:21](app/models/service.rb#L21)) — deux communes peuvent donc avoir un service homonyme, et `find_by` renvoie arbitrairement le premier. Le reste du contrôleur borne pourtant bien les services à `current_organisation` (cf. `service_ids` des `user_params`, l.416-420).
- **Impact** : fuite de périmètre multi-organisations (vision produit) ; agent invisible pour sa propre commune, visible chez l'autre.
- **Correctif proposé** : `current_organisation.services.find_by(nom: service_name)` (une ligne), et faire remonter « service introuvable dans votre organisation » dans le message d'erreur existant.
- **Test** : `users_import_test.rb` — « un service d'une autre organisation est accepté par l'import » (ÉPINGLAGE : fige le comportement actuel, **à inverser** à la correction).

### B21 — Import XLS : rétrogradation silencieuse d'un manager/administrateur en agent, y compris hors de son organisation
- **Signalé par** : agent, 2026-07-27 (même session).
- **Parcours de repro** : se connecter en manager/admin de la commune A → *Import agents* → fichier contenant l'email d'un **manager** (de A ou de B) → « Oui (Appliquer) » → ce manager devient `agent` et se retrouve rattaché à un service de A. Aucun avertissement, la ligne est comptée comme « importée ».
- **Où** : [users_controller.rb:242](app/controllers/users_controller.rb#L242) (`User.where('lower(email) = ?', …).first_or_initialize` — recherche **globale**, aucun `authorize` sur l'enregistrement retrouvé) + [l.256](app/controllers/users_controller.rb#L256) (`user.rôle = 'agent'` inconditionnel).
- **Cause racine (prouvée par test)** : l'import réutilise n'importe quel compte existant partageant l'email, sans vérifier ni l'organisation ni la hiérarchie — alors que `UserPolicy#update?` interdit précisément à un manager de modifier un manager/admin (`hierarchy_violation?`).
- **Impact** : perte de privilèges (le manager visé ne peut plus administrer), et modification d'un compte d'une autre commune — le pendant « écriture » de l'IDOR corrigé sur la messagerie.
- **Correctif proposé** : borner la recherche au périmètre (`current_organisation`), et **ne pas toucher au rôle** d'un enregistrement existant (ne poser `rôle = 'agent'` que sur `new_record`) ; idéalement passer l'enregistrement retrouvé par `authorize user, :update?` et compter un refus en erreur de ligne.
- **Test** : `users_import_test.rb` — 2 ÉPINGLAGES (autre organisation / propre organisation), **à inverser** à la correction.

### B22 — Import XLS : une colonne optionnelle absente **efface** la donnée existante
- **Signalé par** : agent, 2026-07-27 (même session).
- **Parcours de repro** : un agent a un téléphone et un mémo renseignés → importer un fichier **sans** les colonnes `Téléphone`/`Mémo` (elles sont facultatives : seules Nom/Prénom/Email/Service sont obligatoires) en mode « Oui (Appliquer) » → le téléphone et le mémo de cet agent passent à vide.
- **Où** : [users_controller.rb:248-249](app/controllers/users_controller.rb#L248-L249) — `user.téléphone = idx_telephone ? … : nil`.
- **Impact** : perte de données silencieuse (le bilan affiche « importée »).
- **Correctif proposé** : ne rien assigner quand la colonne est absente (`user.téléphone = row[idx_telephone]… if idx_telephone`).
- **Test** : `users_import_test.rb` — « un fichier sans colonne Téléphone conserve le téléphone existant », en `skip` documenté (passera au vert à la correction).

### B23 — Import XLS : un fichier qui n'est pas un XLS 97-2003 provoque une erreur 500
- **Signalé par** : agent, 2026-07-27 (même session).
- **Parcours de repro** : *Import agents* → téléverser un `.xlsx`, un PDF, une image renommée, ou un `.xls` corrompu (le `accept=".xls"` et le script de contrôle sont **côté client**, contournables) → page d'erreur serveur.
- **Où** : [users_controller.rb:216](app/controllers/users_controller.rb#L216) — `Spreadsheet.open` sans `rescue`.
- **Preuve empirique** : téléversement d'un PNG → `Ole::Storage::FormatError: OLE2 signature is invalid`, non rattrapée.
- **Impact** : faible techniquement, mauvais côté utilisateur (une erreur de format est un cas nominal, pas une panne) ; remonte en alerte via l'exception notifier.
- **Correctif proposé** : entourer la lecture d'un `rescue` (Ole/Spreadsheet + `StandardError`) → `flash.now[:alert]` « Fichier illisible : le format attendu est Excel 97-2003 (.xls) ».
- **Test** : `users_import_test.rb` — « un fichier qui n'est pas un XLS est refusé proprement », en `skip` documenté.

### B24 — Import XLS : le bilan de fin d'import n'est pas fiable
- **Signalé par** : agent, 2026-07-27 (même session). Trois défauts distincts, même conséquence : l'utilisateur croit son fichier intégralement traité.
- **(a) Lignes silencieusement ignorées** — [users_controller.rb:237](app/controllers/users_controller.rb#L237) et [l.240](app/controllers/users_controller.rb#L240) : une ligne sans `Nom` ou sans `Email` fait `next` **sans** incrémenter ni `@importes` ni `@errors` et sans trace. *Repro* : fichier de 10 lignes dont 3 sans email → bilan « Lignes importées: 7 | Lignes ignorées: 0 » + message vert « L'importation a bien été exécutée. ». *Correctif proposé* : compter ces lignes en erreur avec leur numéro.
- **(b) Retour de `save` ignoré** — [l.309](app/controllers/users_controller.rb#L309) : `user.save` sans `!` ni test ; un échec (course sur l'unicité, échec d'`invite!`) est compté « importée ». *Correctif proposé* : `if user.save … else` (ou `save!` + rescue par ligne). Même famille que **B17**.
- **(c) Utilisateur désactivé irrécupérable** — [l.242](app/controllers/users_controller.rb#L242) : la recherche subit le `default_scope :kept`, un compte soft-deleté n'est donc jamais retrouvé ; la création échoue sur l'unicité de l'email avec le message opaque « email est déjà utilisé(e) », alors que l'utilisateur ne voit ce compte nulle part dans l'interface (prouvé par test). *Correctif proposé* : chercher avec `User.unscoped` (ou `with_discarded`) et proposer une réactivation explicite, ou au minimum un message « compte désactivé, à réactiver depuis la liste des utilisateurs désactivés ».
- **Test** : `users_import_test.rb` — 3 ÉPINGLAGES (ligne sans nom, ligne sans email, utilisateur désactivé) figent le comportement actuel.

### B26 — ✅ CORRIGÉ (2026-07-28, commit `b850d33d` de Dani, #390) — Show intervention : toutes les actions étaient affichées **en double** (ancienne barre d'actions non retirée à la refonte `12da1055`)
- **Correction** : `show.html.erb` réécrit, l'ancienne barre d'en-tête a disparu (`Terminer'` compté 1× dans le fichier). **Vérifié** : suite système complète au vert dans le `test:all` du 2026-07-28 (1434 runs / 0 échec / 0 erreur), les 8 `Capybara::Ambiguous` ont disparu sans toucher aux tests.
- **Signalé par** : agent, 2026-07-28 (découvert en lançant la suite système après le concern `PieceJointeAuditable` — 8 tests système en `Capybara::Ambiguous`, aucun lien avec le concern).
- **Parcours de reproduction** : se connecter en manager → ouvrir une intervention (`/interventions/<slug>`) → la barre d'actions de l'ancien en-tête ([show.html.erb:23-40](app/views/interventions/show.html.erb#L23)) **et** la nouvelle barre issue de la refonte ([l.374-396](app/views/interventions/show.html.erb#L374), puis [l.650](app/views/interventions/show.html.erb#L650)) sont toutes deux rendues et visibles → « Modifier », « Supprimer », « Terminer », « Valider », « Refuser » et le QR Code apparaissent chacun **deux fois** sur la page.
- **Cause** : le commit `12da1055` (#390 « show interventions ») a ajouté la nouvelle barre sans supprimer l'ancienne (compté sur le fichier : `Terminer'` 1× avant, 2× après). Aucune classe responsive ne masque l'une des deux.
- **Portée** : purement visuelle/UX en prod (les deux boutons pointent vers la même action, rien n'est cassé fonctionnellement), mais **8 tests système échouent** : `intervention_manager_flow_test` (Modifier, Supprimer, Terminer, Valider, Refuser), `intervention_agent_flow_test` (Modifier), `intervention_adherent_flow_test` (Modifier), `dashboard_refresh_manager_flow_test` (transition d'état).
- **Correctif proposé** : retirer le bloc d'actions de l'ancien en-tête (l.23-40) — la refonte l'a manifestement déplacé plus bas. Les tests système repassent au vert sans modification (ils ciblent le libellé / le `data-testid`, qui redeviennent uniques).

### B27 — ✅ CORRIGÉ (2026-07-28, commit `cc20b344` « Changer ref en conventions & services en interventions ») — Show intervention cassé pour tout le monde : `undefined method 'pluck' for an instance of Service` (bloc inachevé commité par `afa572e2`)
- **Correction** : le bloc a été retiré/terminé en amont pendant la session ; les 3 tests (`should show intervention`, `… with location`, test critique évaluation agent) repassent au vert sans modification de test.
- **Signalé par** : agent, 2026-07-28 (découvert en lançant `interventions_controller_test` après l'alignement des boutons « Terminer »).
- **Parcours de reproduction** : se connecter (n'importe quel rôle) → ouvrir une intervention (`/interventions/<slug>`) → **erreur 500**, `ActionView::Template::Error: undefined method 'pluck' for an instance of Service` à [show.html.erb:67](app/views/interventions/show.html.erb#L67).
- **Cause** : le commit `afa572e2` (« Changement des long et lat pour sites ») a inséré dans le bloc « Service » un fragment manifestement en cours d'écriture : `@intervention.service.pluck(:nom)` (`service` est un **belongs_to**, pas une collection) puis trois usages d'une variable `service` **jamais définie** (`service.first(2)`, `service.size`, `service.drop(2)`) alors que le résultat est affecté à `services`. Le bloc est de plus mal imbriqué dans le `<div>` du service.
- **Portée** : **la page show est inaccessible en dev/prod** dès le déploiement de ce commit ; **3 tests en erreur** (`should show intervention`, `should show intervention with location`, le test critique « un agent ne voit pas son évaluation »). Vérifié : en retirant le bloc (l.66-99), les 3 tests repassent au vert (61 runs / 0 échec).
- **Correctif proposé** : côté auteur du commit — soit retirer le bloc (rien ne le rendait, le nom du service est déjà affiché l.64), soit le terminer sur la bonne source de données (les services de l'**adhérent** ou de l'**agent** ? l'intervention n'en a qu'un). **Non corrigé par l'agent** : travail en cours d'un collègue.

### B28 — ⚠️ PARTIELLEMENT CORRIGÉ (2026-07-28) — Terminer/valider/refuser une intervention en conflit de disponibilité → erreur 500, et intervention définitivement figée
- **Signalé par** : PE, 2026-07-28, **rencontré en usage réel** (agent voulant terminer une intervention ordinaire) : `ActiveRecord::RecordInvalid` — « Conflit(s) détecté(s) sur un agent : MARTIN déjà sur l'intervention « #217 » du 19/03/2026 15:15 au 24/03/2026 16:25 ».
- **Parcours de reproduction** : une intervention A dont un agent est aussi affecté à une intervention B qui recouvre sa plage effective (cas fréquent sur les données antérieures à #357) → se connecter en agent affecté (ou en manager) → ouvrir A → cliquer « Terminer » → **erreur 500** à [intervention.rb:164](app/models/intervention.rb#L164). Reproduit en base de dev sur l'intervention #191 (`début_prévue` 20/03/2026, **aucune `fin_prévue`**, agents MARTIN + LEFEBVRE) contre #217 (réel 19/03 15:15 → 24/03 16:25).
- **Cause** : une transition passe par `persist_workflow_state` ([intervention.rb:162](app/models/intervention.rb#L162)) qui fait un **`save!`** → toutes les validations sont rejouées, dont `agents_must_be_available` (#357), alors que la transition ne touche **ni les dates ni les agents**. Les actions `terminer`/`valider`/`refuser` ne gardaient que la transition (`can_terminer?`) ou rien du tout, contrairement à `archiver` qui testait `valid?` depuis toujours.
- **Correction (décision PE : filet contrôleur seul)** : `redirect_si_invalide(participe)` dans `interventions_controller`, appelé en tête de `terminer`, `valider` et `refuser` → redirection avec le **motif exact** au lieu d'une erreur 500. **4 tests critiques** dans `interventions_controller_test.rb` (les 3 transitions + garde anti-faux-positif « une intervention saine se termine toujours »), **prouvés rouges** sans le filet.
- **Ce qui reste ouvert (assumé par PE)** : l'intervention en conflit reste **impossible à faire avancer** tant que le conflit existe — il faut corriger la donnée (poser une `fin_prévue`, retirer l'agent, raccourcir l'intervention qui recouvre). Le correctif de fond écarté : ne rejouer les validations de disponibilité que si les dates ou les agents changent. **Constat métier de PE** : « une intervention ne dure qu'une journée » — or #217 s'étale sur 5 jours et #191 a un début prévu sans fin ; **aucune validation n'interdit ni l'un ni l'autre** aujourd'hui.

### B29 — Créer un site : l'adresse tapée au clavier n'est **pas envoyée** si l'utilisateur ne choisit pas de suggestion Google → message d'erreur trompeur
- **Signalé par** : agent, 2026-07-29 (découvert en réparant `warehouses_test`, **prouvé empiriquement** : à l'événement `submit`, `#warehouse_address` est `disabled: true` et absent du `FormData`).
- **Parcours de reproduction** : se connecter en administrateur → Paramètres → onglet Sites → « Ajouter » → remplir Nom + Équipe → **taper** une adresse dans « Localisation » **sans cliquer sur une suggestion Google** → Enregistrer → le formulaire revient avec « Address doit être rempli(e) » **et le champ Localisation vidé**, alors que l'adresse était bien saisie.
- **Cause** : le widget `google.maps.places.Autocomplete` (attaché par `places_controller.js` depuis `afa537e2`) **désactive l'input** au submit tant qu'aucune prédiction n'a été retenue ; un champ `disabled` n'est pas soumis. Le serveur ne voit donc ni adresse ni coordonnées.
- **Portée** : cosmétique/UX — la création aurait de toute façon été refusée (`latitude`/`longitude` vides, validation model). Le message ne dit pas ce qu'il faut faire (« choisissez une adresse dans la liste ») et la saisie est perdue.
- **Correctif proposé** : afficher un message explicite quand les coordonnées manquent, ou re-remplir le champ avec la valeur saisie. **Non corrigé** (front, non demandé).
- **Effet de bord constaté sur les tests** : les tests système du formulaire Sites font désormais de **vraies requêtes réseau à `maps.googleapis.com`** (clé d'API présente en test) — dépendance externe + quota consommé à chaque run. `warehouses_test` a été réécrit pour poser adresse et coordonnées comme le fait l'autocomplétion (chemin nominal réel), donc il passe avec ou sans réseau.

### B30 — Météo : `get_title` plante sur une date hors de la fenêtre de prévision
- **Signalé par** : agent, 2026-07-29 (session /tests lot D), **prouvé empiriquement** : `MeteoConceptConnexion.get_title(Date.today + 20, forecasts)` → `NoMethodError: undefined method '[]' for nil`.
- **Parcours de reproduction** : aucun aujourd'hui **depuis l'UI** — le seul appelant ([tools/_view_list.html.erb:18](app/views/tools/_view_list.html.erb#L18)) est gardé par `if @forecasts && icon_meteo = get_icon_meteo_by_date(date, …)`, qui renvoie nil hors plage et court-circuite l'appel. Le bug se déclenche dès qu'un futur appelant oublie cette garde, ou si la garde est déplacée.
- **Cause** : `get_title` ([meteo_concept_connexion.rb:68](app/services/meteo_concept_connexion.rb#L68)) interpole `forecast["weather"]` **sans la garde `return unless day_forecast`** que possède son jumeau `get_icon_meteo_by_date` (l.51).
- **Correctif proposé** : `return if forecast.nil?` en tête, symétrique de `get_icon_meteo_by_date`. **Non corrigé** (méthode /tests). Test `skip` documenté dans `meteo_concept_connexion_test.rb`, qui passera au vert à la correction.

### B31 — Météo : une réponse tronquée de l'API fait planter la recherche de prévision
- **Signalé par** : agent, 2026-07-29 (session /tests lot D), **prouvé empiriquement** : `get_forecast_for_date(Date.today + 5, forecasts.first(3))` → `NoMethodError: undefined method 'third' for nil`.
- **Parcours de reproduction** : l'API Météo Concept renvoie moins de 14 jours (dégradation partielle, changement d'offre, quota) → ouvrir la page d'accueil ou la réservation de matériel → **erreur 500** sur une page qui n'a pourtant besoin de la météo que pour décorer.
- **Cause** : `get_forecast_for_date` ([meteo_concept_connexion.rb:64](app/services/meteo_concept_connexion.rb#L64)) borne l'index sur la **constante 14** (`difference_of_day < 14`) au lieu de la taille réelle du tableau reçu, puis appelle `.third` sur `forecasts[index]` sans garde.
- **Portée** : contredit l'intention explicite du `rescue` de `fetch_response` (« une API météo en panne ne doit jamais faire tomber la page d'accueil ») — la garde protège l'appel HTTP mais pas l'exploitation d'une réponse partielle.
- **Correctif proposé** : `return unless difference_of_day >= 0 && difference_of_day < forecasts_for_14_days.size`, puis `forecasts_for_14_days[difference_of_day]&.third`. **Non corrigé** (méthode /tests). Test `skip` documenté.

### B32 — `Absence` : une absence sans dates est enregistrable et casse ensuite l'affichage
- **Signalé par** : agent, 2026-07-29 (hors périmètre de la session, découvert en analysant la couverture), **prouvé empiriquement** en environnement de test : `Absence.new(user: u).valid?` → `true`, puis `nb_jours` → `NoMethodError: undefined method '-' for nil` et `en_cours?` → `TypeError: cannot determine inclusion in beginless/endless ranges`.
- **Parcours de reproduction** : aucun depuis le formulaire (les champs date sont requis côté HTML) ; atteignable par requête forgée ou par tout code créant une `Absence` sans dates. La fiche utilisateur affichant l'absence lèverait alors une 500.
- **Cause** : `Absence` ([absence.rb:24-26](app/models/absence.rb#L24)) n'a **aucune validation de présence** sur `du`/`au` ; les trois validations métier commencent toutes par `return if du.blank? || au.blank?`, donc une absence sans dates les traverse toutes.
- **Correctif proposé** : `validates :du, :au, presence: true`. ⚠️ À vérifier avant application : cela rendrait invalides d'éventuelles absences existantes sans dates en prod (un `Absence.where(du: nil).or(...)` avant migration).
- **Non corrigé** (méthode /tests, et lot `Absence` non retenu par PE pour cette session — aucun test écrit dessus).

### B33 — CRM adhérent : le filtre Statut n'offre jamais l'état « Signé » sur l'onglet Cotations
- **Signalé par** : agent, 2026-07-29 (session /tests lot B).
- **Parcours de reproduction** : se connecter en adhérent (ou manager) → CRM → onglet « Mes Cotations » → dérouler le filtre **Statut** → les états proposés sont Créé / Envoyé / Validé / Refusé / Archivé. **« Signé » est absent**, alors que c'est un état propre à `Cotation` et une étape centrale de son workflow : un adhérent ne peut pas filtrer ses devis signés.
- **Cause** : la vue ([adherent_crm/index.html.erb:29](app/views/adherent_crm/index.html.erb#L29)) alimente le menu avec `Commande.workflow_state_humanized` **quel que soit l'onglet**. Or `Commande` n'a pas l'état `SIGNE` ([commande.rb:22-26](app/models/commande.rb#L22)), contrairement à `Cotation` ([cotation.rb:25-30](app/models/cotation.rb#L25)).
- **Correctif proposé** : choisir la classe selon `@tab` (`{'cotations' => Cotation, 'commandes' => Commande, 'factures' => Facture}[@tab]`). **Non corrigé** (modification de vue avec effet sur le comportement → hors du périmètre /tests).

### B34 — CRM adhérent : le terme de recherche n'est pas échappé (jokers SQL actifs)
- **Signalé par** : agent, 2026-07-29 (session /tests lot B).
- **Parcours de reproduction** : CRM → champ « Rechercher » → saisir `%` (ou `_`) → **tous** les documents du périmètre remontent, au lieu de ceux contenant littéralement ce caractère.
- **Cause** : `apply_filters` ([adherent_crm_controller.rb:29](app/controllers/adherent_crm_controller.rb#L29)) construit `"%#{params[:search]}%"` sans échapper `%` ni `_`, qui sont les jokers de `ILIKE`.
- **Portée** : **pas une faille** — la valeur passe par un paramètre lié (`s:`), donc aucune injection SQL, et le filtre ne peut que restreindre `policy_scope`. Simple gêne fonctionnelle. Sévérité faible.
- **Correctif proposé** : `ActiveRecord::Base.sanitize_sql_like(params[:search])` avant interpolation. **Non corrigé** (méthode /tests). Comportement actuel **épinglé** par un test, à inverser à la correction.

### B35 — CRM adhérent : le filtre `adherent_id` est ignoré sur l'onglet Cotations
- **Signalé par** : agent, 2026-07-29 (session /tests lot B).
- **Parcours de reproduction** : en manager, appeler `/adherent_crm?adherent_id=<id>` → les onglets Commandes et Factures sont bien restreints à cet adhérent ([adherent_crm_controller.rb:95](app/controllers/adherent_crm_controller.rb#L95) et l.118), l'onglet Cotations ne l'est **pas**.
- **Cause** : asymétrie entre les trois `prepare_variables_of_*_for_view` — `adherent_id` (sans accent) n'est appliqué qu'aux commandes et factures ; seul `adhérent_ids` (avec accent, dans `apply_filters`) vaut pour les trois. Deux paramètres différents pour la même intention, dont aucun n'est aujourd'hui émis par le formulaire de la vue.
- **Portée** : incohérence, pas une fuite (`policy_scope` borne les trois onglets de la même manière).
- **Correctif proposé** : unifier sur un seul paramètre et l'appliquer dans `apply_filters`. **Non corrigé** (méthode /tests). Comportement actuel **épinglé** par un test.

### B40 — Deux personnes peuvent réserver le même outil le même jour, et l'une des deux réservations devient invisible
- **Signalé par** : agent, 2026-07-29 (session `/tests` « matériel », reproduit par test).
- **Parcours de repro** : deux comptes non-adhérents de la même commune (ex. le manager `hidalgo` et l'agent `bond`) → chacun ouvre `/tools` et clique la case verte du **même outil au même jour** → les deux clics réussissent (« Outil réservé le … avec succès »). **Observé** : deux lignes `réservé` existent en base pour ce couple (outil, jour) ; dans la grille, un seul état est retenu et c'est le **dernier créé** qui gagne. Le premier réservataire voit donc une case bleu clair « Réservé par qqn d'autre », sans lien pour libérer **sa propre** réservation.
- **Où** : [app/controllers/mouvements_controller.rb:101](app/controllers/mouvements_controller.rb#L101) (`reserve`, aucune vérification d'existence) + [app/models/tool.rb:119](app/models/tool.rb#L119) (`pluck(:état, :user_id).to_h` — la conversion en Hash écrase les doublons d'état).
- **Cause racine** : `Mouvement` n'a aucune validation d'unicité sur (`tool`, `date`, `état: réservé`), et la grille agrège par état, pas par utilisateur.
- **Impact** : deux agents peuvent partir avec le même matériel le même jour en croyant l'avoir réservé — cas typique du service technique. Le premier ne peut même pas annuler depuis la grille.
- **Correctif proposé (décision métier)** : refuser la seconde réservation (validation model + message dans `reserve`), ou l'assumer et afficher les deux. Comportement actuel épinglé par `réserver deux fois le même jour crée deux réservations` (`mouvements_controller_test.rb`) et `deux réservations le même jour : seule la dernière compte` (`tool_test.rb`), **à inverser à la décision**.

### B41 — `users#agent_calendrier` : une date illisible en paramètre provoque une erreur 500
- **Signalé par** : agent, 2026-07-29 (même famille que les crashes corrigés ce jour dans `tools#index`/`#show`/`mouvements#reserve`).
- **Parcours de repro** : ouvrir `/users/…/agent_calendrier?date=nawak` (ou laisser un lien/marque-page porter une date malformée) → `Date::Error`.
- **Où** : [app/controllers/users_controller.rb:165-167](app/controllers/users_controller.rb#L165) — `params[:date] = Date.today if params[:date].blank?` puis `params[:date].to_date`, exactement le motif corrigé ailleurs.
- **Impact** : 500 sur une page agent, déclenchable par une URL forgée ou un paramètre corrompu.
- **Correctif proposé** : le même garde que `ToolsController#date_valide?` (une méthode privée de 5 lignes, à mutualiser si un troisième contrôleur en a besoin). **Non appliqué** : hors du périmètre autorisé ce jour (l'autorisation portait sur les trois autres emplacements).

## 🟡 Risques surveillés (non reproductibles aujourd'hui — re-signaler si les gardes tombent)

### R1 — Pointage : une fille de la veille non terminée ferait pointer une NOUVELLE intervention au lieu de terminer la sienne
- **Signalé par** : PE, 2026-07-10 (point sensible vécu/craint sur la page d'accueil).
- **Scénario redouté** : un agent oublie de clôturer son pointage ; la fille reste `nouveau` avec `fin` nil. Le lendemain, il re-scanne le QR de la mère → `User#find_current_intervention` ([user.rb:350](app/models/user.rb#L350)) filtre sur `DATE(début) = Date.today` → ne trouve **pas** la fille de la veille → `interventions_controller#pointer` ([interventions_controller.rb:365](app/controllers/interventions_controller.rb#L365)) crée une **nouvelle** fille (« Début de journée enregistré ! ») au lieu de terminer l'ancienne, qui reste ouverte à jamais.
- **Statut 2026-07-10 : NON reproductible — vérifié empiriquement** (simulation en transaction annulée, cas avec et sans `fin_prévue` héritée de la mère) : la création de la nouvelle fille est **refusée** dans les deux cas. Deux gardes indépendantes :
  1. **Clôture nocturne** : tâche Hatchbox `interventions:terminer_pointages` (22h) → `TerminerPointagesJob` termine toutes les filles `nouveau` avec `début` → normalement aucune fille ne survit à la nuit.
  2. **Validation #357** (commit `89b12a76`) : `agents_must_not_have_open_pointage` ([intervention.rb:262](app/models/intervention.rb#L262)) interdit un 2e pointage ouvert pour l'agent → même si une fille survit, le scan du lendemain est **refusé avec un message explicite** au lieu de créer en silence.
- **⚠ Conditions qui rendraient le bug à nouveau faisable — à re-vérifier si l'une survient** :
  1. **Suppression/affaiblissement** de `agents_must_not_have_open_pointage` (tentant si des agents se plaignent d'être bloqués par une fille orpheline) **combiné** à une nuit sans clôture.
  2. **Tâche Hatchbox bloquée** (précédent vécu : une seule expression cron invalide bloque TOUTES les tâches) — la garde 2 empêche alors le bug silencieux mais l'agent est **bloqué** (voir effet de bord ci-dessous).
  3. `TerminerPointagesJob` **rescue par enregistrement** : si `terminer!` échoue sur une fille (ex. conflit #357 à 22h — cas déjà vu en test), elle survit à la nuit.
  4. **Fille héritant `fin_prévue`** : `create_next_intervention` fait un `dup` de la mère **sans remettre `fin_prévue`/`début_prévue` à nil** → `pointage_ouvert?` (= `effective_fin.blank?`) devient faux et la garde dédiée est **contournée** ; seul `OVERLAP_SQL` bloque alors (vérifié bloquant aujourd'hui, mais via un intervalle inversé — protection moins intentionnelle). Toute retouche de `create_next_intervention`, `effective_fin` ou `OVERLAP_SQL` mérite un re-test de ce scénario.
- **Effet de bord actuel (pas le bug signalé, mais à connaître)** : un agent avec une fille orpheline **ne peut plus pointer du tout** (le scan ne peut ni la terminer — filtre « aujourd'hui » — ni en créer une nouvelle — garde #357) jusqu'à la clôture de 22h ou une intervention manuelle du manager.
- **Décision client 2026-07-10** : on ne code rien tant que le cas n'est pas reproductible ; l'agent doit **re-signaler ce risque** si un changement dans cette zone le rend faisable.

### R2 — `duplicate key … audits_pkey` : deux runs de test simultanés sur `coopcom_test` rembobinent la séquence des audits (test uniquement — sans objet depuis l'adoption de `rails test:all`)
- **Signalé le** : 2026-07-13 (PE : `WikiPagesControllerTest#test_should_create_wiki_page`, seed 14293, `PG::UniqueViolation … "audits_pkey" (id)=(4907)`). Diagnostic par autopsie de la base + lecture du code Rails 8.0.5 — non reproductible à la demande (course inter-processus). *Ex-« B14 » d'un stash resté non commité, renuméroté R2 à la résolution du conflit le 2026-07-16 (le n° B14 a été réattribué entre-temps au bug « service changé silencieusement »).*
- **Où** : `test/fixtures/audits.yml` (aucun `id:` explicite) × le rechargement des fixtures de Rails (`activerecord-8.0.5/lib/active_record/fixtures.rb:689` : `reset_pk_sequence!` = `SELECT MAX(id)` **puis** `setval`, non atomiques, exécutés **après** la coûteuse vérification des clés étrangères).
- **Cause** (deux ingrédients) :
  1. La table `audits` n'a **pas de classe modèle résolvable par Rails** (la gem fournit `Audited::Audit`, pas de `Audit` de premier niveau) → Rails **n'assigne pas** les ids `identify` habituels aux fixtures : les lignes tirent `nextval` à l'insertion (**vérifié en base** : ids séquentiels 7981/7982 au lieu des 876480149/913074033 qu'`identify` donnerait), et chaque chargement recale la séquence sur `MAX(id)`.
  2. Si un **second processus** utilise `coopcom_test` en même temps (guard-minitest, `test:system` dans un autre terminal, double run), il peut tirer et **committer** un id d'audit dans la fenêtre `SELECT MAX` → `setval` du premier → le `setval` **rembobine la séquence en dessous d'une ligne commitée**. Plus tard dans le run, `nextval` redistribue cet id → `UniqueViolation` au premier test qui crée un enregistrement audité.
- **Signature caractéristique** : `audits_pkey` avec un id **très inférieur** au `last_value` attendu de `audits_id_seq`. Auto-réparant : le chargement de fixtures suivant refait DELETE + INSERT + `setval` cohérents.
- **Statut 2026-07-16 : reclassé risque surveillé — la parade retenue est le workflow, pas le code.** PE a découvert que `bin/rails test:all` lance toute la suite (système incluse) en **un seul run** → plus de double run en usage normal (validé empiriquement : 3 × `test:all` verts, seeds 8236/511/42077, 1336 runs / 0 échec). Règle consignée dans CONTRIBUTING §⑦. Deux correctifs successivement implémentés, vérifiés puis **abandonnés sur décision PE** : la base dédiée `coopcom_test_system` (2026-07-13-d, aiguillage `ARGV` non standard) et le durcissement `_fixture: model_class: Audited::Audit` en tête d'`audits.yml` (ids `identify` stables — abandonné le 2026-07-16 : « pas de modification qui ne sert à rien si `test:all` est utilisé »).
- **La fragilité de fond demeure** : les fixtures `audits.yml` tirent toujours la séquence. Un double run accidentel (deux terminaux, `guard` actif pendant un run manuel) peut reproduire le symptôme — dans ce cas, re-signaler ; le durcissement d'une ligne reste documenté ci-dessus.

### R3 — Sous `test:all`, un `sign_in` Devise d'un test d'intégration peut être « volé » par une requête navigateur retardataire → redirection login au lieu du comportement métier (flakiness rare, test uniquement)
- **Signalé le** : 2026-07-16 (2 occurrences le même jour, jamais avant : run agent `test:all` 1359 runs / 1 échec, puis run PE — `SecuriteRegressionsTest#test_impossible_de_lire_une_conversation_avec_un_utilisateur_d'une_autre_organisation`, attendu `redirect_to /messagerie`, obtenu `redirect_to /users/sign_in`). **3e occurrence le 2026-07-17** (run PE : `InterventionsDisponibiliteTest#test_le_réel_est_prioritaire…`, attendu 2XX, obtenu 302 → `/users/sign_in` ; vert en isolation 12/12). **4e occurrence le 2026-07-17** (run agent `test:all` **parallèle 4 workers**, seed 42077 : `InterventionsDisponibiliteTest#test_pas_de_conflit_si_les_dates_réelles_sont_disjointes`, même signature 302 → login — le mode parallèle mélange système + intégration dans chaque worker, donc expose davantage au vol de hook). La fréquence monte (4 en 2 jours) — si ça continue, activer une des pistes ci-dessous.
- **Faits établis** : le test passe en isolation (14/14), passe avec `rack_attack_test` dans le même run (37/37), passe sur 3 seeds de la suite non-système complète (3 × 1276 runs / 0 échec) → ne se manifeste que dans `test:all` (système + intégration dans le même processus). **Hors de cause** : la config rack-attack (inerte en test via `:null_store`, et ne produit que des 429/403, jamais une redirection login).
- **Mécanisme — désormais PROUVÉ par la source de la gem** (2026-07-17, warden 1.2.9, ce n'est plus une déduction) : `sign_in` (Devise::Test::IntegrationHelpers, inclus globalement `test_helper.rb:24`) → `Warden::Test::Helpers#login_as` → `Warden.on_next_request` qui **empile un bloc dans un tableau global au processus** (`warden/test/warden_helpers.rb:25` : `_on_next_request << blk`). Ce tableau est **drainé sans aucun filtrage** par le hook posé par `Warden.test_mode!` (`warden.rb:37-42`) :
  ```ruby
  Warden::Manager.on_request do |proxy|
    unless proxy.asset_request?
      while blk = Warden._on_next_request.shift   # ← LA prochaine requête, quelle qu'elle soit
        blk.call(proxy)
      end
    end
  end
  ```
  Le seul filtre est `asset_request?` — une requête **Turbo/XHR retardataire** du navigateur d'un system test n'en est pas une. Sous `test:all`, le serveur Puma de Capybara vit dans le **même processus** et reste actif entre les classes : sa requête en vol traverse Warden juste après le `sign_in` du test d'intégration suivant, **shift le bloc et pose l'utilisateur sur la session du navigateur** au lieu de celle du test → le `get`/`delete` du test part non authentifié.
- **Signature caractéristique** : test d'intégration/contrôleur qui échoue avec `redirect_to /users/sign_in` là où il attend le comportement métier, uniquement en `test:all`, non reproductible en isolation, la classe précédente (ordre du seed) étant un system test.
- **Occurrences** : 5 en 2 jours (2026-07-16 ×2, 2026-07-17 ×3) — 5e = run PE seed 7911, `InterventionsControllerTest#test_purge_:_impossible_de_supprimer_la_photo_d'une_AUTRE_intervention`, attendu 404, obtenu 302 → login ; vert en relance isolée (1 run / 0 échec). **Aucune n'a jamais touché deux fois le même test** : c'est l'ordre du seed qui décide de la victime.
- **Statut : CORRIGÉ le 2026-07-17** (accord PE). Patch dans `test_helper.rb` + 3 tests de verrouillage dans `test/integration/sign_in_hook_isolation_test.rb` (dont une **garde anti-faux-positif** : une file toujours vide ferait passer les 2 tests R3 tout en cassant l'authentification de toute la suite). **Preuve rouge/verte faite** : correctif désactivé → les 2 tests R3 échouent, garde OK ; réactivé → 3/3 verts. Suite non-système **1279 runs / 0 échec / 2 skips** ; échantillon système 4/4 (le helper `login` n'est pas affecté). **Correctif** : neutraliser le drain hors du thread de test, puisque les requêtes d'intégration sont traitées **inline dans le thread principal** alors que Puma sert les siennes dans **ses propres threads** —
  ```ruby
  module Warden::Test::WardenHelpers
    def _on_next_request
      return [] unless Thread.current == Thread.main # requête navigateur : ne consomme rien
      @_on_next_request ||= []
    end
  end
  ```
  La file reste intacte pour le vrai test. ⚠ Ne PAS « ré-armer » le hook depuis l'intérieur du bloc (réflexe naturel) : le drain est un `while … shift`, un re-`push` serait re-shifté immédiatement → **boucle infinie**. Vérifié au préalable : **aucun system test n'utilise `sign_in`** (ils passent par le helper `login` = vrai formulaire), donc rien ne dépend du hook côté navigateur. **Écartés** : re-tenter la requête si redirigée login (masquerait une vraie régression d'authentification — inacceptable sur cette app) ; remplacer `sign_in` par un POST de connexion réel (immunisé par construction et plus réaliste, mais casse les re-`sign_in` en cours de test — `require_no_authentication` de Devise redirige un utilisateur déjà connecté — et touche 25 fichiers).

### R4 — Deadlock Postgres entre le `REFRESH MATERIALIZED VIEW` synchrone du dashboard et une écriture `agent_interventions`, DANS un run `test:all` unique (flakiness rare, test uniquement — mais le mécanisme existe aussi en prod)
- **Signalé le** : 2026-07-17 (2 runs `test:all` consécutifs de l'agent : `InterventionManagerFlowTest#test_Modifier_intervention`, `ActiveRecord::Deadlocked: PG::TRDeadlockDetected` sur `DELETE FROM agent_interventions` dans `interventions_controller.rb:237`, l'autre processus détenant un verrou `ShareRowExclusiveLock` ; 2e erreur du même run non capturée, vraisemblablement l'effet domino du même deadlock). Vert en isolation (10/10). Un 3e run n'a montré ni deadlock ni erreur (1 flake de sync sans rapport, `InterventionAdherentFlowTest`, vert en isolation 8/8).
- **Fait nouveau vs 2026-07-16** : le deadlock `REFRESH` avait été attribué au lancement **simultané** de deux runs ; ici **un seul run** était en cours (sauf run parallèle de PE non signalé). Le serveur Capybara est multi-threads : deux requêtes navigateur concurrentes suffisent — T1 committe une écriture d'intervention puis son `after_commit` lance `refresh_views!` (`concurrently: false` = verrou exclusif sur la vue, puis lecture des tables sources) pendant que T2 fait `DELETE agent_interventions` puis attend à son tour le refresh → étreinte mortelle.
- **Portée prod (déduction)** : le refresh synchrone en prod est `CONCURRENTLY` (pas de verrou de lecture) mais deux écritures simultanées d'interventions par deux utilisateurs peuvent toujours se disputer vues + tables sources ; à volumétrie actuelle, probabilité faible ; un deadlock y ferait échouer la requête web de l'utilisateur (500).
- **Pistes si récurrent** (trade-offs actés par PE le 2026-07-15 « volume faible, code minimal ») : (a) `rescue ActiveRecord::Deadlocked` + retry unique autour du refresh ; (b) sérialiser les refresh via un verrou consultatif Postgres ; (c) rebrancher le `RefreshDashboardViewsJob` dormant (coalescé, un seul refresh en vol — la conception 2026-06-18 éliminait ce deadlock par construction).
- **Statut : risque surveillé, non corrigé** — re-signaler chaque occurrence pour suivre la fréquence.

---

## ✅ Bugs corrigés (historique)

| Bug | Corrigé | Référence |
|---|---|---|
| Filtre **Statut** de l'index interventions cassé (select multiple → `to_s.downcase` ne matchait rien) | 2026-06-23 | commit `a9f23e82` |
| Fixture `tonte_locaux` : `workflow_state: "Validé"` (capitale) | 2026-06-23 | commit `a9f23e82` |
| `NotifAdherentCommandeEnvoyeeJob` : `MailLog` avec `commande_id` inexistant → `UnknownAttributeError` | ~2026-07 | réécriture #330 (Alexandre Meunier) |
| `notif_panne` : `MailLog.to` recevait un **ID** au lieu de l'email | ~2026-07 | commit `b32fbf28` (client) |
| Jobs managers : `intervention.organisation_id` / `manager.organisation_id` inexistants (dérivation via service) | 2026-07-01 | 4 jobs corrigés, session `/tests` |
| Pré-filtre services des index (#309/#311) + matrice finale admin/manager | 2026-06-23 | sessions filtres, committé côté client |
| **B12** — filtre #292 absent de `temps_par_adherent` (un temps négatif entamait le total par adhérent du dashboard) | 2026-07-13 | branche `dashboard-scenic` (demande PE, session /tests) : `.where("temps_total >= 0")` ajouté — hérite de la limite de grain **B13** ; ⚠ `staging` reste bogué jusqu'à la fusion (son `dashboard_data.rb` sera remplacé par la version Scenic) ; test ex-`skip` passé au vert dans `dashboard_temps_negatif_test.rb` |
| **B15** — photos d'intervention via le formulaire manager/admin (dropzone) : (a) **500 sur `edit`** dès que l'intervention a des photos (`attachment.blob` appelé sur un `Attached::Many`, `_file_dropzone.html.erb:29` — le partial était écrit pour `has_one_attached`) ; (b) **photo jamais enregistrée** depuis ce formulaire : input file sans `multiple` → param `intervention[photos]` **scalaire**, rejeté en silence par `permit(photos: [])` (le formulaire **agents** `_form_for_agents.erb` avait lui `multiple: true` → d'où le « des fois ça fonctionne » selon le rôle) ; (c) **AVIF** annoncé dans l'`accept` des deux formulaires mais refusé par `PieceJointeValidable::IMAGES` → échec de validation après coup | 2026-07-15 (signalé et corrigé le jour même, PE) | partial `_file_dropzone` généralisé has_one/has_many (détection `Attached::Many`, liste des blobs **persistés**, `multiple` auto sur l'input, hint « remplacera » réservé au has_one) ; `dropzone_controller.js` gère plusieurs fichiers (drop + change + libellé) ; `image/avif` ajouté à `IMAGES`. 4 tests : `edit` avec photos (**prouvé rouge sur l'ancien partial**) + assertion `input[multiple]`, update ajoute une photo, signed_ids ré-émis conservés + ajout, AVIF accepté |
| **B16** — `purge` d'une photo : redirection **302** après un DELETE Turbo, au lieu du 303 imposé par la décision audit 2026-06-12 §4. Sévérité **rétrogradée faible** après test empirique de PE en dev (le scénario destructeur initialement déduit était faux : `button_to` émet POST+`_method=delete`, et fetch convertit POST→GET sur un 302 → pas de ré-émission de DELETE ; simple écart de cohérence) | 2026-07-15 (signalé, instruit et corrigé le jour même) | `status: :see_other` ajouté au `redirect_to` de `interventions_controller#purge` (une ligne, demande PE) ; test ex-`skip` passé au vert (« la redirection après un DELETE Turbo est en 303 see_other ») ; suite 1253 runs / 0 échec / 2 skips (retour à B1+B9) |
| **B9** — slug inconnu sur commandes/factures → **500** au lieu d'un refus propre (`find_by(slug:)` nil → `authorize` sur la classe → `CommandePolicy#manage?` évalue `record.organisation` → NoMethodError, vérifié empiriquement le 2026-07-10 ; cotations avait déjà son garde) | 2026-07-28 (autorisation PE « je te laisse corriger la policy des commandes ») | garde ajouté dans `set_commande`/`set_facture` sur le motif du contrôleur cotations et de la checklist CONTRIBUTING (« introuvable → redirection ») : `redirect_to <index>_path, alert: '… introuvable'` ; la chaîne de filtres s'arrête avant `authorize` (comportement identique à cotations, déjà en prod). Test ex-`skip` réécrit et passé au vert (redirection + alerte, dans les TESTS CRITIQUES de `commandes_controller_test`) + miroir facture |
| **B25** — **fuite des évaluations dans l'export XLS** : l'export de l'index interventions (`format.xls`, bouton visible de tous les rôles, `index?` = tout connecté) incluait les colonnes **Évaluation (note)** et **Avis** sans restriction → un **agent** exportant ses propres interventions lisait ses évaluations, en violation du CCTP (« visibles uniquement des gestionnaires ») et du garde de la vue show. Découvert par exploration le 2026-07-28, **confirmé par PE** le jour même | 2026-07-28 (correction autorisée par PE) | `ExportToXls::Interventions` prend `include_evaluation:` (en-têtes ET valeurs conditionnels) ; le contrôleur passe `include_evaluation: !current_user.agent?` (même règle que la section Compte-rendu de la show). ⚠ Au passage, `ApplicationService.call` forwarde désormais les **kwargs** (`**kwargs`, requis en Ruby 3, rétro-compatible). 3 tests critiques : export agent sans note/avis (avec garde anti-faux-positif : l'intervention figure bien dans le fichier), export manager avec, show HTML agent sans avis |
| **B10** — les 2 tests « création à postériori » échouaient entre 14 h et 15 h (fixture `intervention_fille` de **martin** ancrée sur l'heure réelle − 4 h recouvrait la plage [10 h, 11 h] créée à midi fixe pour le même agent → refus #357 légitime ; test uniquement) | 2026-07-15 | correctif « désolidariser les acteurs » : les 2 tests utilisent **john_wick** (aucune intervention de fixture → jamais de conflit) au lieu de martin ; la fixture `4.hours.ago` reste intacte (elle protège les tests de pointage, cf. 2026-07-09). Vérifié **en pleine fenêtre 14 h–15 h** : 42/42 verts + suite complète 1239 runs / 0 échec |

---

## Comment s'en servir
- **Retrouver la liste** : ouvrir ce fichier, ou demander à l'agent « ressors-moi les bugs ouverts » (il connaît ce registre via sa mémoire).
- **À chaque nouveau bug signalé** : l'ajouter ici avec son parcours de reproduction, et référencer `Bn` depuis CLAUDE.md.
- **À chaque correction** : déplacer la ligne dans « Corrigés » avec le commit, et mettre à jour CLAUDE.md.
