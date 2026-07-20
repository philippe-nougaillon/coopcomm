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

### B9 — Slug inconnu sur cotations/commandes/factures → erreur 500 au lieu de 404
- **Où** : [commandes_controller.rb:149](app/controllers/commandes_controller.rb#L149), [factures_controller.rb:138](app/controllers/factures_controller.rb#L138), [cotations_controller.rb:187](app/controllers/cotations_controller.rb#L187)
- **Cause** : `set_…` fait `find_by(slug:)` → `nil` sur un slug inconnu ; `is_user_authorized` fait alors `authorize(Commande)` sur la **classe**, et `CommandePolicy#manage?` évalue `record.organisation` → `NoMethodError` (**vérifié empiriquement le 2026-07-10** : `undefined method 'organisation' for class Commande`) → **500**. Même motif dans les trois contrôleurs.
- **Parcours de reproduction** :
  1. En tant que **manager**, j'ouvre une commande puis je modifie l'URL (`/commandes/nimporte-quoi`) — ou je suis un vieux lien vers une commande supprimée en dur / un slug régénéré.
  2. → page d'erreur **500** au lieu d'un 404 « introuvable ».
- **Impact** : erreur brute + bruit dans les logs pour un simple lien mort ; surface triviale à déclencher.
- **Trace test** : test `skip` documenté dans `test/controllers/commandes_controller_test.rb` (« slug inconnu : devrait renvoyer 404 — bug B9 ») — passera au vert à la correction.
- **Correctif proposé** : `find_by!(slug:)` (ou `friendly.find`) pour lever `ActiveRecord::RecordNotFound` → 404 standard, dans les trois contrôleurs.

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
- **Signalé le** : 2026-07-16 (2 occurrences le même jour, jamais avant : run agent `test:all` 1359 runs / 1 échec, puis run PE — `SecuriteRegressionsTest#test_impossible_de_lire_une_conversation_avec_un_utilisateur_d'une_autre_organisation`, attendu `redirect_to /messagerie`, obtenu `redirect_to /users/sign_in`). **3e occurrence le 2026-07-17** (run PE : `InterventionsDisponibiliteTest#test_le_réel_est_prioritaire…`, attendu 2XX, obtenu 302 → `/users/sign_in` ; vert en isolation 12/12). La fréquence monte (3 en 2 jours) — si ça continue, activer une des pistes ci-dessous.
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
| **B10** — les 2 tests « création à postériori » échouaient entre 14 h et 15 h (fixture `intervention_fille` de **martin** ancrée sur l'heure réelle − 4 h recouvrait la plage [10 h, 11 h] créée à midi fixe pour le même agent → refus #357 légitime ; test uniquement) | 2026-07-15 | correctif « désolidariser les acteurs » : les 2 tests utilisent **john_wick** (aucune intervention de fixture → jamais de conflit) au lieu de martin ; la fixture `4.hours.ago` reste intacte (elle protège les tests de pointage, cf. 2026-07-09). Vérifié **en pleine fenêtre 14 h–15 h** : 42/42 verts + suite complète 1239 runs / 0 échec |

---

## Comment s'en servir
- **Retrouver la liste** : ouvrir ce fichier, ou demander à l'agent « ressors-moi les bugs ouverts » (il connaît ce registre via sa mémoire).
- **À chaque nouveau bug signalé** : l'ajouter ici avec son parcours de reproduction, et référencer `Bn` depuis CLAUDE.md.
- **À chaque correction** : déplacer la ligne dans « Corrigés » avec le commit, et mettre à jour CLAUDE.md.
