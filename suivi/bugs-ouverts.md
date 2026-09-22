# Bugs ouverts — CoopComm

> **Source de vérité** des bugs détectés et non corrigés, avec leur **parcours de reproduction** (point de vue utilisateur quand c'est possible). Un bug trouvé par l'agent est **signalé, pas corrigé** sans accord explicite (cf. `CLAUDE.md`). Bugs corrigés : `bugs-corriges.md`. Défauts non reproductibles parce qu'une garde les empêche : `risques-surveilles.md`.
>
> **Gravité** — la fiche va dans la section de ce que le bug **fait aujourd'hui** :
> - 🔴 **Bloquant** : argent, perte ou corruption de données, fuite d'information, parcours critique (pointage, bon d'intervention, réservation, dashboard, validation), ou un écran entier en 500 pour tous.
> - 🟠 **Gênant** : visible en usage normal, contournable ou rare.
> - ⚪ **Dormant** : impact nul aujourd'hui — code mort, test uniquement, piège à la réactivation, mis de côté.
>
> **Règle de tenue** : une fiche nouvelle prend le **prochain numéro libre** ci-dessous (et l'incrémente) et se range dans sa section **par numéro**. Un bug corrigé **quitte ce fichier** pour `bugs-corriges.md` — fiche entière, titre préfixé `✅ CORRIGÉ (AAAA-MM-JJ)`, ligne « Correctif appliqué » ; ne jamais marquer ✅ sur place. Une correction **partielle** reste ici, titre `⚠️ PARTIELLEMENT CORRIGÉ`, reliquat en tête de fiche.
>
> **Prochain numéro libre : B121**

---

## 🔴 Bloquants

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
- **Rebalayé le 2026-09-22** : inchangé (`services_for_adherent`, [interventions_controller.rb:382](app/controllers/interventions_controller.rb#L382)). Depuis, la cascade sait conserver une option marquée `data-mandatory` ([dynamic_select_controller.js:48](app/javascript/controllers/dynamic_select_controller.js#L48)), utilisée seulement par `_form_for_agents` pour l'agent courant : marquer de la même manière le service actuel de l'intervention serait le correctif le plus court.

### B19 — ⚠️ PARTIELLEMENT CORRIGÉ (2026-07-29, garde vue restaurée ; garde contrôleur toujours absente) — Un outil rattaché à des interventions peut être supprimé
- **Signalé par** : agent, 2026-07-24 (surfacé en fiabilisant `tools_test` : l'assertion « bouton masqué » visait un id disparu → faux positif qui masquait la régression).
- **Parcours de repro** : se connecter en manager/admin → fiche d'un outil **utilisé dans des interventions** (fixture `tondeuse`) → le bouton « Supprimer » est affiché → modale → « Oui, supprimer » → l'outil est **réellement supprimé** (les `tool_interventions` sont détruits en cascade `dependent: :destroy`, les interventions perdent leur lien outil).
- **Où** : [app/views/tools/show.html.erb:17](app/views/tools/show.html.erb#L17) (bouton affiché sous la seule garde `policy(@tool).destroy?`) + [app/controllers/tools_controller.rb:83](app/controllers/tools_controller.rb#L83) (`@tool.destroy!` sans garde) + [app/models/tool.rb:11](app/models/tool.rb#L11) (`has_many :tool_interventions, dependent: :destroy`).
- **Cause racine (prouvée par git)** : le commit `fc5330c4` (« UX -show tools ») a retiré la branche `<% if @tool.interventions.any? %>` qui, avant, remplaçait le bouton (`id="supprimer_outil"`) par un bloc inerte « Suppression impossible, l'outil est utilisé dans des interventions ». `ToolPolicy#destroy?` = `manager_or_admin? && organisation?` **n'a jamais** regardé les interventions ; la protection était uniquement dans la vue (donc déjà contournable par requête forgée — le contrôleur `destroy` n'a aucune garde).
- **Impact** : perte de données potentielle (rattachements outil↔interventions) déclenchable en 2 clics ; historique des interventions faussé.
- **Correctif proposé (décision métier à trancher)** : soit **restaurer la protection** — re-masquer/désactiver le bouton pour `@tool.interventions.any?` **ET** ajouter une garde dans `tools_controller#destroy` (redirection + message si l'outil est utilisé), la vue seule étant contournable ; soit **assumer** la suppression libre (et alors supprimer le test `Ne pas pouvoir supprimer un outil avec une intervention`). Test correspondant en `skip` documenté jusqu'à décision.
- **⚠️ MISE À JOUR 2026-07-29 — corrigé À MOITIÉ** : le commit `756dfdcd` (#412, Dani) a **restauré la garde côté vue** (bloc « Suppression impossible, l'outil est utilisé dans des interventions » à la place du bouton). Le `skip` du test système est donc **levé** (`test/system/tools_test.rb`, assertion réelle au vert). **La garde contrôleur manque toujours** : [tools_controller.rb:94](app/controllers/tools_controller.rb#L94) fait `@tool.destroy!` sans rien vérifier — vérifié empiriquement, un `DELETE /tools/:slug` direct supprime l'outil `tondeuse` et ses `tool_interventions`. Comportement épinglé par le test `un outil utilisé par une intervention est quand même supprimé` (`tools_controller_test.rb`), **à inverser à la correction**.

### B40 — Deux personnes peuvent réserver le même outil le même jour, et l'une des deux réservations devient invisible
- **Signalé par** : agent, 2026-07-29 (session `/tests` « matériel », reproduit par test).
- **Parcours de repro** : deux comptes non-adhérents de la même commune (ex. le manager `hidalgo` et l'agent `bond`) → chacun ouvre `/tools` et clique la case verte du **même outil au même jour** → les deux clics réussissent (« Outil réservé le … avec succès »). **Observé** : deux lignes `réservé` existent en base pour ce couple (outil, jour) ; dans la grille, un seul état est retenu et c'est le **dernier créé** qui gagne. Le premier réservataire voit donc une case bleu clair « Réservé par qqn d'autre », sans lien pour libérer **sa propre** réservation.
- **Où** : [app/controllers/mouvements_controller.rb:101](app/controllers/mouvements_controller.rb#L101) (`reserve`, aucune vérification d'existence) + [app/models/tool.rb:119](app/models/tool.rb#L119) (`pluck(:état, :user_id).to_h` — la conversion en Hash écrase les doublons d'état).
- **Cause racine** : `Mouvement` n'a aucune validation d'unicité sur (`tool`, `date`, `état: réservé`), et la grille agrège par état, pas par utilisateur.
- **Impact** : deux agents peuvent partir avec le même matériel le même jour en croyant l'avoir réservé — cas typique du service technique. Le premier ne peut même pas annuler depuis la grille.
- **Correctif proposé (décision métier)** : refuser la seconde réservation (validation model + message dans `reserve`), ou l'assumer et afficher les deux. Comportement actuel épinglé par `réserver deux fois le même jour crée deux réservations` (`mouvements_controller_test.rb`) et `deux réservations le même jour : seule la dernière compte` (`tool_test.rb`), **à inverser à la décision**.

### B101 — Un seul caractère hors Windows-1252 fait tomber le PDF d'un devis, d'une commande ou d'une facture
- **Où** : [base_pdf_for_crm.rb](app/services/transform_to_pdf/base_pdf_for_crm.rb) — toutes les méthodes qui écrivent du texte issu de la base : `add_metadata` (intitulé, adhérent, service), `add_lignes` (intitulé de ligne, libellé de prestation), `add_memo`, `add_signature`.
- ⚠ **Périmètre : les documents CRM seulement — le PDF d'une INTERVENTION n'est pas concerné.** `TransformToPdf::Intervention` assainit déjà son texte (`texte_sûr`, [intervention.rb:435](app/services/transform_to_pdf/intervention.rb#L435)) : les caractères inconnus y deviennent `?`, le PDF se génère normalement. **C'est le comportement voulu, pas un bug** — voir « pourquoi des `?` » ci-dessous. `BasePdfForCrm` n'a **aucun** équivalent : là, ça lève.
- **Les deux comportements mesurés côte à côte (2026-09-07, sonde en mémoire, rien enregistré)** : intervention **#423** (slug `32c322af-…`), dont les commentaires contiennent réellement `☀ 👍 → m³ ³ ₂` → `TransformToPdf::Intervention.call(i, u).render` rend **68 396 octets, aucune erreur** (les caractères hors jeu s'affichent `?`) ; la même chaîne posée dans le `mémo` d'une cotation → `TransformToPdf::Cotation.call(c).render` lève **`Prawn::Errors::IncompatibleStringEncoding`**.
- **Pourquoi des `?` du côté intervention** : Prawn n'a que les polices intégrées au format PDF, en single-byte Windows-1252 ; un caractère absent de ce jeu **n'a aucune forme à dessiner**. Les deux seules issues sont donc « remplacer par un signe de substitution » (ce que fait `texte_sûr`) ou « embarquer une police TTF » (correctif de fond, ci-dessous), qui est la seule qui rende les emoji et les flèches réellement lisibles.
- **Cause** : Prawn n'embarque aucune police ; il utilise les polices **AFM intégrées** au format PDF (Helvetica), qui sont en **single-byte Windows-1252**. Devant un caractère hors de ce jeu, Prawn ne dégrade pas l'affichage — il **lève `Prawn::Errors::IncompatibleStringEncoding`**, et toute la génération tombe avec lui. La documentation de la gem ne propose qu'une issue : embarquer une police TTF.
- **Mesuré** (sonde en transaction annulée sur la base de dev, 2026-09-01) : mémo d'une cotation réelle passé à `Prévoir 2 m³ de terreau ☀` → `TransformToPdf::Cotation.call(c).render` lève `Prawn::Errors::IncompatibleStringEncoding`. Donnée restaurée par `ActiveRecord::Rollback` (vérifié).
- **Parcours de reproduction** :
  1. En tant que **manager**, je crée un devis et je saisis dans le **mémo** un caractère absent du jeu latin occidental — un emoji tapé au téléphone (`☀`, `👍`), une flèche `→`, ou un indice comme `m³`... `³` passe, mais `₂` non.
  2. J'enregistre, puis j'ouvre la fiche du devis.
  3. → L'**aperçu PDF de la page ne s'affiche pas**, et le bouton « Générer PDF » rend une **erreur 500**. Le devis devient impossible à envoyer à l'adhérent tant que le caractère n'est pas retiré, et rien n'indique lequel est en cause.
  4. Idem sur une commande et sur une facture (même classe mère), et sur le **mail** qui joint le PDF (`NotificationMailer` l.110, 152, 169) : l'envoi échoue.
- **Impact** : ce sont les documents contractuels envoyés aux communes. Le caractère fautif est invisible à l'œil dans le formulaire, et le message d'erreur ne remonte pas à l'utilisateur. Probabilité réelle : la saisie se fait aussi sur téléphone, où l'emoji est à un appui du clavier.
- **Deux correctifs possibles** :
  - **assainir le texte** avant de l'écrire, comme le fait `TransformToPdf::Intervention#texte_sûr` (substitutions connues, puis `encode('Windows-1252', undef: :replace, replace: '?')`) — quelques lignes, aucun ajout au dépôt, mais les caractères exotiques deviennent `?` ;
  - **embarquer une police TTF** (DejaVu Sans ou Open Sans, licence OFL donc compatible avec l'open-source envisagé) — UTF-8 complet, supprime le besoin d'assainir **dans les quatre services PDF à la fois**, au prix de 4 fichiers de police (~300–700 Ko) et de PDF un peu plus lourds. L'équipe y avait déjà pensé : le bloc est commenté dans [qrcode_modele_intervention.rb:27-32](app/services/transform_to_pdf/qrcode_modele_intervention.rb#L27-L32), avec un chemin `vendor/assets/fonts/Open_Sans/`.
- **Non couvert par les tests** : aucun test n'exerce un caractère hors Windows-1252 sur les PDF CRM.
- ✅ **Remède disponible depuis le 2026-09-01** (#485, PDF d'intervention) : `TransformToPdf::Intervention#texte_sûr` ([intervention.rb:433](app/services/transform_to_pdf/intervention.rb#L433)) traduit `₂` et `→` puis remplace par « ? » tout caractère hors Windows-1252. Les trois PDF du CRM ne l'utilisent pas (rebalayage 2026-09-22) : à mutualiser dans `base_pdf_for_crm.rb`.

## 🟠 Gênants

### B4 — Sujet du mail de panne malformé : `{title: "…"}`
- **Où** : [notif_panne_job.rb:12-18](app/jobs/notif_panne_job.rb#L12-L18) vs `NotificationMailer#avertissement_reservation`
- **Cause** : le job passe `title:` en **argument nommé**, mais le mailer attend `title` en **positionnel** → le hash devient le dernier paramètre positionnel et l'objet du mail rend littéralement `{title: "[COOPCOMM] L'outil X a été déclaré en panne"}`.
- **Parcours de reproduction** :
  1. En tant qu'**adhérent A**, je **réserve un outil** dans le magasin (clic sur une case du planning matériel) pour une date à venir.
  2. En tant qu'**agent/manager**, je **déclare ce même outil en panne** (clic sur la case panne) — zone sensible `Mouvement`.
  3. → `NotifPanneJob` envoie le mail d'avertissement au réserviste A : le corps est correct, mais l'**objet** du mail est le hash brut au lieu du texte.
- **Impact** : cosmétique mais très visible (mail réel envoyé au client avec un sujet cassé).
- **Correctif proposé** : aligner l'appel sur la signature (passer `title` en positionnel, ou convertir la signature en kwargs partout).
- ✅ **Re-vérifié ouvert le 2026-07-31, preuve empirique** : `notif_panne_job.rb:16` passe toujours `title: title` (mot-clé) et `notification_mailer.rb:84` déclare toujours `def avertissement_reservation(user, tool, date_reservation, date_panne, title)` (positionnel). Le test `test/jobs/notif_panne_job_test.rb` est **vert** alors qu'il asserte `assert_equal "{title: …}", mail.subject` — le sujet cassé est donc bien celui qui part aujourd'hui.

### B13 — Le filtre #292 opère sur les cellules pré-agrégées du dashboard, pas par intervention (un négatif peut être « netté » au lieu d'exclu)
- **Signalé le** : 2026-07-13. ⚠️ **N'est plus spécifique à une branche : c'est désormais un bug de `staging`** (constaté le 2026-07-31) — `dashboard-scenic` **a été fusionnée** (commit `0fb76419 #297`, `db/views/` et les modèles `DashboardAgentStat`/`DashboardInterventionStat` sont sur staging, `dashboard_data.rb` a disparu). La mention « staging filtre au grain intervention » est **caduque**.
- **Où** : les `where("temps_total >= 0")` appliqués aux vues matérialisées : grain **(org, service, adhérent, mois, statut)** pour les stats interventions, grain **(org, agent)** pour le temps par agent.
- **Cause** : une vue matérialisée ne stocke que des sommes par cellule. Si une cellule mélange +8 h et −3 h, elle vaut 5 ≥ 0 → elle **passe** le filtre et le −3 est compté (staging strict : 8). Si le net d'une cellule/d'un agent est négatif, **tout** est exclu, y compris la part positive (staging : la part positive reste).
- **Statut de la décision** : le volet **grain agent** a été **acté par PE le 2026-07-13** (résolution du conflit de merge, « approximation au grain agent »). Le volet **grain cellule** (stats interventions) n'a pas été discuté explicitement — même nature, porté à connaissance ici.
- **Parcours de reproduction** :
  1. Un adhérent a, le **même mois**, sur le **même service** et au **même statut**, une intervention à +8 h et une à −3 h.
  2. Dashboard manager → le KPI « temps total » compte **5 h** pour ce mois (au lieu de 8 h avec le #292 strict).
- **Impact** : faible tant que les temps négatifs restent rares (un seul connu en prod) ; l'écart ne se voit que si positif et négatif cohabitent dans la même cellule.
- **Trace test** : 2 tests « ÉPINGLAGE B13 » dans `test/controllers/dashboard_temps_negatif_test.rb` figent le comportement actuel (net agent 9−5=4 ; cellule 8−3=5) — **à inverser** si le grain intervention est finalement retenu.
- **Correctif proposé (si l'exactitude est voulue)** : ajouter aux deux vues une colonne `temps_total_positif` (`SUM(CASE WHEN temps_total >= 0 THEN temps_total ELSE 0 END)` — au grain intervention, donc exact) et faire pointer les calculs de temps du concern dessus ; les `where` disparaissent. Migration Scenic `update_view` (⚠ piège connu : ne pas ré-ajouter les index à la main).

### B17 — `purge` : l'audit peut être silencieusement perdu si l'intervention est devenue invalide
- **Signalé** : 2026-07-15, même session.
- **Où** : [interventions_controller.rb:343](app/controllers/interventions_controller.rb#L343) — `@intervention.update(audit_comment: …)` sans bang ni branche d'échec.
- **Cause/scénario (déduction, non reproduit)** : la photo est purgée **avant** l'update ; si les validations échouent (ex. `agents_must_be_available` #357 devenue fausse depuis la création), l'audit « Photo n°X supprimée » n'est **pas** écrit, mais l'utilisateur voit quand même la notice « Photo supprimée ». Le cas nominal est couvert par un test (« la suppression est tracée dans l'audit trail », vert).
- **Impact** : trou ponctuel d'audit trail, faible.
- **Correctif proposé** : à instruire — écrire l'audit sans dépendre des validations de l'intervention (ou au minimum logguer/alerter en cas d'échec de l'update).
- ⚠️ **Rebalayé le 2026-09-22** : `purger_photos_demande` ([interventions_controller.rb:273](app/controllers/interventions_controller.rb#L273)) a le même `update(audit_comment: …)` sans bang ; même correctif à appliquer aux deux.

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

### B41 — `users#agent_calendrier` : une date illisible en paramètre provoque une erreur 500
- **Signalé par** : agent, 2026-07-29 (même famille que les crashes corrigés ce jour dans `tools#index`/`#show`/`mouvements#reserve`).
- **Parcours de repro** : ouvrir `/users/…/agent_calendrier?date=nawak` (ou laisser un lien/marque-page porter une date malformée) → `Date::Error`.
- **Où** : [app/controllers/users_controller.rb:165-167](app/controllers/users_controller.rb#L165) — `params[:date] = Date.today if params[:date].blank?` puis `params[:date].to_date`, exactement le motif corrigé ailleurs.
- **Impact** : 500 sur une page agent, déclenchable par une URL forgée ou un paramètre corrompu.
- **Correctif proposé** : le même garde que `ToolsController#date_valide?` (une méthode privée de 5 lignes, à mutualiser si un troisième contrôleur en a besoin). **Non appliqué** : hors du périmètre autorisé ce jour (l'autorisation portait sur les trois autres emplacements).

### B45 — `format_mail_recipients` rend du HTML non échappé
- **Signalé par** : agent, 2026-07-29 (reproduit : `format_mail_recipients('<b>x</b>@paris.fr')` rend le `<b>` comme balise).
- **Où** : [app/helpers/mail_logs_helper.rb:15](app/helpers/mail_logs_helper.rb#L15) — `.join(',<br/>').html_safe` sur des valeurs jamais échappées.
- **Impact** : XSS stocké par construction. Portée **faible** aujourd'hui (la colonne est alimentée par l'application, à partir d'emails validés), mais toute nouvelle source d'écriture dans `MailLog#to` devient un vecteur.
- **Correctif proposé** : échapper chaque adresse (`ERB::Util.h`) avant le `join`, en gardant le `<br/>` comme seul HTML délibéré. Comportement actuel **épinglé** par `ÉPINGLAGE H4` (`mail_logs_helper_test.rb`), à inverser à la correction.

### B48 — La tâche `interventions:relancer` ne relance jamais personne (condition de date inversée)
- **Signalé par** : agent, 2026-07-30 (reproduit par test : une intervention terminée depuis 10 jours n'est pas sélectionnée ; une intervention datée 10 jours dans le futur l'est).
- **Où** : [lib/tasks/interventions.rake:6](lib/tasks/interventions.rake#L6) — `where('updated_at::DATE - NOW()::DATE >= ?', 3)` sélectionne les interventions modifiées **dans plus de 3 jours**, pas depuis.
- **Impact** : fonctionnalité de relance silencieusement morte. Aucune erreur, aucun log.
- **Correctif proposé** : inverser la soustraction (`NOW()::DATE - updated_at::DATE >= 3`). Comportement actuel **épinglé** dans `test/tasks/interventions_relancer_test.rb`.

### B49 — `interventions:relancer` plante sur `intervention.organisation_id`, après avoir envoyé le mail
- **Signalé par** : agent, 2026-07-30 (reproduit ; `Intervention#respond_to?(:organisation_id)` renvoie `false`, vérifié en console).
- **Où** : [lib/tasks/interventions.rake:14](lib/tasks/interventions.rake#L14) — la table `interventions` n'a pas de colonne `organisation_id` (l'organisation dérive du service via `has_one through:`).
- **Impact** : le jour où B48 sera corrigé, la tâche enverra le premier mail puis lèvera `NoMethodError` — l'adhérent est relancé, le `MailLog` n'est jamais tracé et les suivants ne sont pas traités.
- **Correctif proposé** : `intervention.organisation&.id`, comme les 4 jobs corrigés le 2026-07-01. Comportement actuel **épinglé**.

### B73 — Le trigger de refresh du dashboard épuise `max_locks_per_transaction` en écriture de masse
- **Où** : [db/triggers/interventions_refresh_dashboard_v01.sql](db/triggers/interventions_refresh_dashboard_v01.sql) et son jumeau `agent_interventions`, via `refresh_dashboard_views()`.
- **Cause** : le trigger est `FOR EACH STATEMENT`, mais il exécute un `REFRESH MATERIALIZED VIEW` **complet des deux vues** à chaque instruction. Depuis B71 le refresh a lieu **dans** la transaction ; chaque rafraîchissement y prend ses verrous, qui ne sont relâchés qu'au commit.
- **Parcours de reproduction** (exécuté, 2026-08-05) : dans une seule transaction, créer ~150 interventions (un test qui construit une matrice, un import, une migration de reprise, un script de seed) → `PG::OutOfMemory: ERROR: out of shared memory / HINT: You might need to increase max_locks_per_transaction`, avec `CONTEXT: SQL statement "REFRESH MATERIALIZED VIEW dashboard_intervention_stats"`.
- **Impact** : aucun en usage normal (une intervention enregistrée à la fois). Mais tout traitement par lot est désormais à risque : import XLS massif, migration de données, reprise de l'existant à la mise en prod de septembre. L'échec survient **au milieu** de la transaction, donc tout est annulé.
- **Correctifs possibles** (aucun appliqué) : (a) rendre le refresh conditionnel (`pg_trigger_depth()`, ou un drapeau de session posé par les traitements de masse) ; (b) revenir à un refresh différé hors transaction pour les lots ; (c) augmenter `max_locks_per_transaction` — traite le symptôme, pas la cause.
- **Contournement dans les tests** : `test/support/interventions_matrice.rb` limite le nombre d'écritures et pose l'état du workflow en mémoire plutôt qu'en base.
- **Famille** : même origine que R4 (étreinte mortelle sur le refresh) — c'est le second mode de défaillance du même mécanisme.

### B74 — `calculate_co2` ré-enregistre l'intervention avec validations depuis un `after_commit`, et peut changer son état
- **Où** : [intervention.rb:457](app/models/intervention.rb#L457) (`save` dans `calculate_co2`), appelé par `apres_terminaison` ([l.628](app/models/intervention.rb#L628)).
- **Cause** : `after_commit :apres_terminaison` appelle `calculate_co2`, qui fait un `save` **complet** — donc rejoue toutes les validations et tous les `before_validation`, dont `check_workflow_pointage_mère`.
- **Parcours de reproduction** (exécuté, 2026-08-05) : enregistrer une intervention avec `repeter: true` et `workflow_state: 'terminé'` → après le commit, l'état en base est **`pointage activé`**. Le calcul du CO₂ a remis en cause l'état du workflow.
- **Second effet, non reproduit mais structurel** : ce `save` est **sans `!` et son retour est ignoré**. Si une validation échoue à cet instant (conflit de disponibilité apparu entre-temps, agent devenu absent), `trajet` et `co2` sont perdus **en silence** — l'utilisateur voit son intervention terminée, sans trajet ni empreinte carbone, sans message.
- **Impact** : le cas « modèle de pointage terminé » ne devrait pas se produire par l'UI (aucun bouton Terminer n'est rendu sur un modèle) ; il est atteignable par requête forgée, par la console et par la tâche de clôture nocturne. La perte silencieuse de `trajet`/`co2`, elle, est atteignable normalement.
- **Correctif proposé** : sortir l'écriture du callback (`update_columns(trajet:, co2:)` — ces colonnes ne demandent aucune validation), ce qui supprime d'un coup le rejeu des validations, le changement d'état et la perte silencieuse. ⚠️ `co2` est dans la liste surveillée par le trigger du dashboard : `update_columns` déclenche bien le refresh, le comportement de B71 est préservé.
- **Note connexe** : ce `save` imbriqué est déjà la raison pour laquelle `apres_terminaison` doit être déclaré **en dernier** dans le modèle (cf. décision 2026-07-29-h) — le défaut a donc déjà coûté une fois.

### B98 — ⚠️ PARTIELLEMENT CORRIGÉ (2026-08-26, formulaire de connexion seul) — L'œil qui révèle le mot de passe est inutilisable dès qu'on a tapé dedans
- ⚠️ **Reliquat (rebalayage 2026-09-22)** : `devise/sessions/new.html.erb` porte `z-10` depuis le 2026-08-26 (commit `60509511`, Dani). Les trois autres formulaires — `users/_form_password.html.erb`, `devise/passwords/edit.html.erb`, `devise/invitations/edit.html.erb` — ont chacun deux boutons sans la classe (mesuré).
- **Où** : le bouton `data-action="click->password-visibility#toggle"` des formulaires Devise (connexion, invitation, mot de passe oublié, changement de mot de passe).
- **Cause** : daisyUI donne `z-index: 1` au champ **quand il a le focus** ; le bouton, en `position: absolute`, reste à `z-index: auto`. Le champ passe donc **au-dessus** de l'œil et intercepte le clic.
- **Mesuré** (sonde navigateur, 2026-08-26) : champ non focalisé → `elementFromPoint` au centre du bouton renvoie le `<svg>` de l'œil ; champ focalisé après saisie → il renvoie l'`INPUT`, avec `z-index: 1` sur le champ et `auto` sur le bouton.
- **Parcours de reproduction** :
  1. J'ouvre la page de connexion et je saisis mon mot de passe — le champ a le focus.
  2. Je clique sur l'œil pour vérifier ce que j'ai tapé.
  3. → **Rien ne se passe** : le clic atterrit dans le champ. Il faut d'abord cliquer ailleurs pour retirer le focus, puis cliquer sur l'œil.
- **Impact** : la fonction est inatteignable dans son usage normal, sur les quatre formulaires. Gênant surtout sur téléphone, où l'on ne relit pas sa saisie autrement.
- **Correctif proposé** : une classe sur le bouton — `relative z-10`.
- **Test** : `test/system/adherent/devise_adherent_flow_test.rb`, assertion sur le `type` du champ (`password` → `text`), **rouge volontairement** jusqu'à la correction.

### B103 — L'entrée « Tous » des filtres d'index a disparu du menu déroulant : on ne peut plus revenir à « tout afficher » que par la petite croix
- **Signalé par** : l'agent, 2026-09-07, en instruisant l'effet du commit `c8c8b8ef` (Dani, « Fix blank sur mouvement »).
- **Où** : [slim_select_controller.js:8-11](app/javascript/controllers/slim_select_controller.js#L8-L11) — `connect()` marque `data-placeholder = 'true'` sur l'option vide de **tous** les selects slim, sans regarder si le select est `required`. SlimSelect 2.13.1 masque alors cette option (`ss-option ss-hide`). Le garde visait les champs obligatoires (il y ferme le trou de B99/B102, cf. la fiche B99) ; il attrape au passage les filtres, dont l'option vide **est** un choix légitime.
- **Vues concernées** : les 6 filtres à blanc étiqueté — `cotations/index:53`, `commandes/index:42`, `factures/index:36`, `conventions/index:27` et `:34`, `adherent_crm/index:32` (tous `include_blank: "Tous"`).
- **Mesuré au navigateur (2026-09-07), preuve rouge/verte faite** : sur `/cotations?workflow_state=Envoyé`, menu du filtre Statut = `[["", ss-option ss-hide], ["Créé"], ["Envoyé" ss-selected], …]` — l'entrée « Tous » est là mais invisible et sans son libellé. Le bloc de 5 lignes retiré temporairement (copie de sauvegarde, jamais `git checkout`) → `[["Tous", ss-option], …]` : l'entrée revient. L'écart est donc bien imputable à ce commit.
- **Parcours de reproduction** :
  1. J'ouvre la liste des devis et je filtre sur le statut « Envoyé ».
  2. Je rouvre le menu **Statut** pour revenir à tous les devis.
  3. → La ligne **« Tous » n'est plus proposée** ; le menu ne liste que les six statuts. Il faut deviner la petite croix `×` du champ pour vider le filtre.
- **Impact** : faible mais quotidien, et sur un public « peu à l'aise avec l'informatique ». Pas de cul-de-sac : la croix `×` fonctionne et re-soumet bien le formulaire (vérifié : `?workflow_state=` → liste complète). **Le champ replié affiche toujours « Tous » quand rien n'est filtré** (SlimSelect reprend le texte de l'option placeholder) — la perte ne concerne que le menu ouvert. Même chose pour les invites `prompt: "Choisir un adhérent"` des formulaires : elles restent affichées dans le champ replié, seule leur ligne de menu disparaît, ce qui est le comportement voulu là-bas.
- **Correctif proposé, mesuré** : borner le garde aux champs obligatoires — `if (blankOption && this.element.required)`. Variante posée temporairement et relevée au navigateur : le filtre Statut retrouve son entrée « Tous », et les trois selects requis de `cotations/new` gardent `data-placeholder = "true"` et `valueMissing = true`. Les ~10 selects `required` du dépôt portent bien l'attribut (vérifié sur rôle, état et matériel d'un mouvement, adhérent/service/prestation d'un devis), donc aucun n'est déprotégé par ce bornage. C'était déjà le périmètre du garde de B99.
- **Non couvert par un test** : plus aucun test ne surveille le comportement de l'option vide depuis la suppression de `test/system/slim_select_test.rb` par `#491`.

<!-- B104 est dans un stash (flash qui fait déborder le cookie de session), non encore fusionnée dans staging : ne pas le réattribuer. -->

### B109 — Devis, commandes, factures : les tableaux d'une même fiche partagent le paramètre `page` et tournent ensemble
- **Signalé par** : l'agent, 2026-08-27 ; re-vérifié présent sur `staging` le 2026-09-14.
- **Où** : `cotations#show` (`@pagy_prestations`, `@pagy_envois`, `@pagy`), `commandes#show` et `factures#show` (`@pagy_prestations`, `@pagy`).
- **Cause** : `Pagy::DEFAULT[:page_param]` est laissé au défaut `:page` ; aucun appel ne le surcharge. Les `pagy_nav` d'une même page émettent donc le même `?page=`.
- **Parcours de reproduction** : sur une cotation à 25 prestations et 15 lignes d'activité, je clique « 2 » sous les prestations → l'historique des envois et l'activité basculent eux aussi en page 2.
- **Impact** : sur les trois écrans « argent » du CRM, dès qu'un document dépasse 10 lignes.
- **Correctif proposé** : `pagy(..., page_param: :page_prestations)` et `:page_envois` — `pagy_nav` reprend le `page_param` de son instance.
- **Test proposé** : contrôleur — `get cotation_url(c, page_prestations: 2)` → les prestations bougent, l'activité reste en page 1.

### B110 — Pagination des prestations à moitié câblée : `factures#show` l'ignore, `commandes#show` ne l'applique qu'au mobile
- **Signalé par** : l'agent, 2026-08-27 ; re-vérifié présent sur `staging` le 2026-09-14.
- **Où** : [factures/show.html.erb:150 et 197](app/views/factures/show.html.erb#L150), [commandes/show.html.erb:196 et 243](app/views/commandes/show.html.erb#L196).
- **Cause** : les trois contrôleurs construisent `@prestations` + `pagy`, mais seule `cotations/show` a été convertie de bout en bout.
  - **Factures** : la vue n'utilise **jamais** `@prestations` (mobile et desktop itèrent `@facture.facture_lignes`) et rend malgré tout un `pagy_nav`.
  - **Commandes** : le mobile prend `@prestations` (l.196), mais le `<tbody>` desktop **réassigne** `commande_lignes = @commande.commande_lignes.includes(:prestation)` (l.243).
- **Parcours de reproduction** : une facture de 25 lignes les liste **toutes** sous une pagination « 1-10 sur 25 » dont les numéros ne changent rien. Une commande de 25 lignes en montre 10 au téléphone, 25 à l'ordinateur.
- **Impact** : incohérence affichée sur des documents financiers.
- **Correctif proposé** : aligner les trois vues sur `@prestations`.
- **Test proposé** : contrôleur — facture puis commande à 12 lignes → le tableau desktop n'en contient que 10.

### B111 — `cotations#show` : l'état vide « Aucune prestation enregistrée. » a disparu
- **Signalé par** : l'agent, 2026-08-27 ; re-vérifié présent sur `staging` le 2026-09-14 (chaîne absente de la vue, présente dans `commandes/show:258` et `factures/show:212`).
- **Où** : [cotations/show.html.erb](app/views/cotations/show.html.erb), section Prestations.
- **Cause** : la conversion à `@prestations` a retiré le `<% else %>` aux deux niveaux, là où commandes et factures l'ont gardé.
- **Parcours de reproduction** : créer une cotation sans ligne et l'ouvrir → sous « Prestations », **plus rien** ; on ne sait pas si la page est cassée ou le document vide.
- **Impact** : cosmétique, mais c'est le premier écran que voit un manager après avoir créé un devis.
- **Correctif proposé** : restaurer la ligne d'état vide, sur le motif de commandes et factures.
- **Test proposé** : contrôleur, cotation sans ligne → `assert_select` sur le libellé.

---

## ⚪ Dormants

### B5 — Mails de bienvenue d'import jamais tracés dans MailLog
- **Où** : [welcome_import_notification_job.rb:15-16](app/jobs/welcome_import_notification_job.rb#L15-L16)
- **Cause** : `MailLog.create` sans `organisation_id` (colonne **NOT NULL**) → le `create` (non-bang) échoue **en silence** ; le mail part, le log n'est jamais persisté.
- **Parcours de reproduction** :
  1. En tant qu'**admin**, j'**importe des utilisateurs** (import fichier) → chaque nouvel utilisateur reçoit bien son mail de bienvenue avec mot de passe.
  2. Je vais sur l'écran **MailLog** (affichage livré en #354) → **aucune trace** de ces envois.
- **Impact** : trou dans l'audit des envois ; impossible de prouver/déboguer qu'un utilisateur importé a reçu son accès.
- **Correctif proposé** : dériver `organisation_id` (via l'organisation du user importé) + envisager `create!` pour ne plus échouer en silence.
- ⚠️ **Re-vérifié le 2026-08-06 : le défaut est toujours dans le code, mais le parcours de reproduction ci-dessus n'existe plus.** Trois faits mesurés : (1) `welcome_import_notification_job.rb:15` fait toujours `MailLog.create` sans `organisation_id`, et le test `welcome_import_notification_job_test` « QUIRK : le MailLog n'est pas tracé » est **vert** — le log échoue bien en silence ; (2) **le job n'a plus aucun appelant** (grep sur tout le dépôt : seuls sa définition, son test, CLAUDE.md et `points-a-trancher.md` le nomment) — c'est du code mort, déjà listé comme tel dans la dette de `points-a-trancher.md` avec `@mdp` et `@success_logs` ; (3) l'import réel envoie une **invitation Devise** (`users_controller:289`, `user.invite!`), et `User#send_devise_notification` **trace bien un MailLog** avec `organisation_id` (user.rb:304-328). **Donc : impact nul aujourd'hui, aucun mail d'import n'échappe au MailLog.** Le bug ne redeviendrait réel que si quelqu'un rebranchait ce job. **Correctif recommandé : supprimer le job et son test** plutôt que réparer un code mort (à trancher avec la dette `@mdp`/`@success_logs`).

### B6 — `user.organisation =` → NoMethodError (code mort, piège à la réactivation)
- **Où** : [user.rb:194](app/models/user.rb#L194) (`User.from_omniauth`) et [registrations_controller.rb:16](app/controllers/users/registrations_controller.rb#L16)
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

### B43 — Trois branches mortes dans le repli de `audit_changes_list`
- **Signalé par** : agent, 2026-07-29 (découvert en écrivant les tests : les assertions attendues échouaient).
- **Parcours de repro** : aucun — c'est précisément le problème. Les messages « Désactivation / Réhabilitation du compte par un administrateur » et « Mise à jour de l'affectation logistique (Entrepôt) » ne peuvent **jamais** s'afficher.
- **Où** : [app/helpers/audits_helper.rb:100-106](app/helpers/audits_helper.rb#L100) et [audits_helper.rb:119-120](app/helpers/audits_helper.rb#L119).
- **Cause racine** : on n'entre dans ce bloc de repli que si `humanize_changes` est vide, c'est-à-dire si **tous** les champs modifiés sont dans `FILTERED_FIELDS`. Or ni `discarded_at` ni `warehouse_id` n'y figurent → ils produisent toujours une ligne de changement, et le repli n'est jamais atteint. Vérifié : une désactivation affiche « Statut du compte : Réactivé → Désactivé » (comportement correct, mais pas celui que le code croit produire).
- **Impact** : nul pour l'utilisateur (le rendu de repli est moins bon que celui qui s'applique), mais 5 lignes de code trompeuses qui font croire à un comportement inexistant.
- **Correctif proposé** : supprimer les deux branches, ou — si les messages sont voulus — les déplacer **avant** le test `humanize_changes.blank?`. Décision d'affichage à prendre.
- ⚠️ **Rebalayé le 2026-09-22 — fiche à re-mesurer** : `audit_changes_list` a été réécrit le 2026-08-06 ([audits_helper.rb:177](app/helpers/audits_helper.rb#L177)), les lignes citées n'existent plus. Mesuré : `remember_created_at` et `sign_in_count` figurent dans `FILTERED_FIELDS`, donc les branches « Connexion », « Déconnexion » et « Maintien de la connexion » sont atteignables ; `discarded_at` n'y figure pas et `format_audit_value` rend déjà « Désactivé »/« Réactivé », donc les deux messages de la branche `discarded_at` restent inatteignables. `warehouse_id` non vérifié.

### B46 — Code mort : `prettify` et `audited_view_path`
- **Signalé par** : agent, 2026-07-29.
- **Où** : [app/helpers/application_helper.rb:28-119](app/helpers/application_helper.rb#L28) — ~80 lignes.
- **Cause racine** : les 7 partials `_audit` sont passés à `audit_details` le 2026-07-28-c ; plus aucune vue n'appelle ces deux méthodes (vérifié par grep sur `app/`). Elles représentent 44 des 88 lignes non couvertes du fichier.
- **Impact** : aucun à l'exécution ; charge de maintenance et bruit dans la mesure de couverture.
- **Correctif proposé** : suppression. Non testées délibérément (on ne fige pas du code voué à disparaître).

### B53 — Code mort exécutable : méthodes qui lèveraient si elles étaient appelées
- **Signalé par** : agent, 2026-07-30 (analyse de couverture).
- **Où** :
  - [app/controllers/twilio_controller.rb:60-75](app/controllers/twilio_controller.rb#L60) — `terminer_intervention` référence un `sender` inexistant → `NameError`. `send_options` (l. 48-58) n'est appelée par personne.
  - [app/models/user.rb:260-266](app/models/user.rb#L260) — `nb_bad_words` itère sur `Notification`, **classe absente du projet** → `NameError`.
  - ~~[app/controllers/users_controller.rb:362](app/controllers/users_controller.rb#L362) — `interventions_average` appelle `interventions` (méthode de modèle) depuis un contrôleur → `NameError`. Action non routée.~~ — **supprimé avec B89 (2026-08-10)**, constaté le 2026-09-22.
  - [app/models/user.rb:178-204](app/models/user.rb#L178) — `from_omniauth` : `:omniauthable` et la route sont commentés ; contient par ailleurs le bug `user.organisation=` déjà signalé.
- **Impact** : nul tant que rien ne les appelle ; pièges à la réactivation.
- **Correctif proposé** : suppression (voir aussi B46 et le récapitulatif de code mort du 2026-07-30 dans CLAUDE.md).
- **Rebalayé le 2026-09-22** : `nb_bad_words` ([user.rb:279](app/models/user.rb#L279)), `send_options` et `terminer_intervention` ([twilio_controller.rb:55](app/controllers/twilio_controller.rb#L55) et `:67`, `sender` toujours indéfini) et `from_omniauth` sont toujours là.

### B91 — Un adhérent peut écraser les mots clés par un paramètre `tag_list` forgé — ⏸️ MIS DE CÔTÉ (décision PE, 2026-08-11)
- **Décision PE** : « il y a plein de champs qui ne devraient pas être permis pour certains rôles parce qu'ils sont cachés selon le `workflow_state` ou le rôle ; c'est un sujet à part, la majorité de ces cas sont des *abuser stories* ». Le critère retenu : **un bug est un bug quand un utilisateur modifie un champ qui ne lui est PAS caché** (c'était le cas de B90) ; forger un paramètre absent de son formulaire n'en est pas un. Fiche conservée pour mémoire, à traiter avec l'ensemble des permits le jour où le sujet sera ouvert.
- **Où** : [interventions_controller.rb:550](app/controllers/interventions_controller.rb#L550) — `:tag_list` figure dans les permits
- **Cause** : aucun formulaire ne soumet `intervention[tag_list]` (les rôles passent par `tags_manager` / `tags_intervenant`, lus par `update_tag_list`). Le permit est donc **mort en usage normal** et ne sert qu'à une requête forgée : `assign_attributes(intervention_params)` écrit les mots clés **avant** que `update_tag_list` ne s'exécute, et celui-ci sort tôt pour l'adhérent puisque son formulaire ne porte aucun champ de mots clés.
- **Parcours de reproduction** (prouvé par test) :
  1. Une intervention porte les mots clés `urgence`.
  2. Connecté en **adhérent**, j'envoie `PATCH /interventions/:slug` avec `intervention[tag_list]=forgé` (console navigateur, ou un champ ajouté à la main dans le formulaire).
  3. Les mots clés de l'intervention deviennent `forgé` — alors que le champ ne m'est jamais proposé et que la garde de **B90** est précisément là pour m'empêcher d'y toucher.
- **Correctif proposé** : retirer `:tag_list` de `intervention_params`. Aucun formulaire ne le soumet, donc aucune régression attendue.
- **Épinglé par** : `interventions_controller_test`, « un adhérent écrase les mots clés par un paramètre tag_list forgé » — à inverser à la correction.

### B107 — `/mouvements` : un `id` posé à la main casse le lien entre le libellé « État » et son champ
- **Signalé par** : l'agent, 2026-08-27 ; re-vérifié présent sur `staging` le 2026-09-14.
- **Où** : [mouvements/index.html.erb:33](app/views/mouvements/index.html.erb#L33) — `id: 'etats-select'` sur le select du filtre État.
- **Cause** : le `label_tag :etats` de la ligne précédente rend `for="etats"`, alors que le select s'appelle `etats-select`. Cet id n'est référencé nulle part (ni CSS, ni JS, ni test).
- **Parcours de reproduction** : sur `/mouvements`, cliquer sur le libellé « État » — le champ ne prend pas le focus. Un lecteur d'écran n'annonce plus le libellé.
- **Impact** : accessibilité, et tout futur `select`/`fill_in` par libellé en test système échouera sans raison lisible.
- **Correctif proposé** : retirer la ligne.
- **Test proposé** : sentinelle — sur les pages d'index, tout `for=` de `<label>` désigne un champ existant.

### B108 — `absence-status` : deux valeurs sont déclarées et jamais lues, et le commentaire qui les accompagne égare
- **Signalé par** : l'agent, 2026-08-27 ; re-vérifié présent sur `staging` le 2026-09-14.
- **Où** : [absence_status_controller.js](app/javascript/controllers/absence_status_controller.js), qui recalcule « absence en cours » côté navigateur.
- **Constat** : les `static values` `matin` et `apresMidi` sont posées par la vue et **aucune** n'est lue par `isEnCours()`, qui ne compare que `du` et `au`.
- **Commentaire trompeur** : « Ajusta esta regla si `Absence#en_cours?` … es distinta (p.ej. corte a mediodía) » laisse croire à un écart avec le modèle. Il n'y en a pas : `Absence#en_cours?` est `(du..au).include?(Date.today)` et ignore lui aussi les demi-journées.
- **Impact** : valeurs mortes et commentaire qui égare. **Aucune divergence de comportement.**
- **À trancher** : les retirer, ou s'en servir — une absence du matin cesserait d'être « en cours » à 15 h, ce qui demande d'aligner `en_cours?` côté Ruby (`début_datetime` / `fin_datetime` font déjà la coupure à midi).
- **Point annexe** : le JS lit la date **locale du navigateur**, `en_cours?` la date **serveur** — un téléphone mal réglé donne une ligne ambre que le serveur ne considère pas en cours.
