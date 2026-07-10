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

---

## Comment s'en servir
- **Retrouver la liste** : ouvrir ce fichier, ou demander à l'agent « ressors-moi les bugs ouverts » (il connaît ce registre via sa mémoire).
- **À chaque nouveau bug signalé** : l'ajouter ici avec son parcours de reproduction, et référencer `Bn` depuis CLAUDE.md.
- **À chaque correction** : déplacer la ligne dans « Corrigés » avec le commit, et mettre à jour CLAUDE.md.
