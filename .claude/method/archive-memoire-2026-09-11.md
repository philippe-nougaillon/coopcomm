# Archive des mémoires consolidées — 2026-09-11

> Ces entrées de mémoire ont été **rapatriées dans `CLAUDE.md`** (une ligne chacune) le 2026-09-11, pour qu'une règle n'ait qu'une seule source et qu'elle s'applique systématiquement plutôt que sur rappel conditionnel. Le fichier garde leur rédaction d'origine, avec le « Why » détaillé. Il n'est chargé nulle part.

---

---
name: crm-conventions-roadmap
description: "CRM \"conventions\" feature — what shipped and the deliberately deferred next step"
metadata: 
  node_type: memory
  type: project
  originSessionId: 9336990a-ea81-4595-b102-28e7cd46bb1f
---

A `Convention` feature was built (juin 2026) as the start of a CRM: a convention belongs to one adhérent + one service (unique per service), has `date_début`, `date_fin_prévue` (optional) and a `has_one_attached :document`. Listed in users/show for adhérents; managed by admins (all) or managers (only conventions whose service is among their services, via `ConventionPolicy` + `Convention.visible_to`).

**Deferred on purpose:** the per-convention "interventions avec leur fréquence et leur prix" (contract line items). The user said "on s'en occupera plus tard" and leaned toward **free-text lines** (intitulé + fréquence + prix), with frequency likely a fixed enum (hebdo/mensuel/trimestriel/…). The `Convention` model is intentionally minimal so these lines can be added later (probably a new `belongs_to :convention` child model).

**Why:** avoids re-asking the same scoping questions and prevents treating the missing line-items as an oversight.
**How to apply:** when extending conventions, add the line-items as a child model; reuse the existing modal form (DaisyUI `<dialog>`) and the absences-style table pattern already in users/show.

**Update (juin 2026):** a separate **devis/quoting module shipped** — `Prestation` (catalogue facturable, scopé `belongs_to :organisation`, code unique par org), `Cotation` (devis : `belongs_to :adherent (class_name "User")` + `belongs_to :service`, `ref` auto `AAAA-N` par org, enum `statut`, soft-delete `discard`, `has_one :organisation, through: :service`, `visible_to(user)` = admin→son org / manager→ses services) et `CotationLigne` (`prestation` + `qté` + `prix_ht`, `total_ht` colonne virtuelle générée ; recalcule `cotation.total_ht` on save/destroy). Porté de `philippe-nougaillon/mvp-crm-ccmm` (qui était en ActiveAdmin) vers les idiomes coopcomm : contrôleurs custom + Pundit (`CotationPolicy`/`PrestationPolicy`, managers autorisés contrairement à `ServicePolicy`) + vues ERB/DaisyUI + formulaire imbriqué via le Stimulus `nested-form` + PDF Prawn (`app/pdfs/cotation_pdf.rb`, a nécessité d'ajouter la gem `prawn-table`). UI : nav « Cotations » (icône `request_quote`), section sur la fiche adhérent (comme les conventions), catalogue Prestations sous Paramètres. **Ce module est distinct des line-items de convention encore différés ci-dessus** (un devis ≠ les lignes contractuelles d'une convention).

---

---
name: crm-dashboard-cctp
description: Active CRM-branch goal — the CCTP-mandated dashboard the client wants
metadata: 
  node_type: memory
  type: project
  originSessionId: 5f562ae9-977e-43d9-8f06-29e01b532c50
---

The active goal of the `CRM` branch (in development as of 2026-06-05) is a **CRM dashboard** specified in the client's CCTP. The client wants these indicators:

- Nombre de demandes par statut (en attente, en cours, terminées, refusées)
- Devis (Cotation) en attente de réponse, avec **relances automatiques**
- Chiffre d'affaires prévisionnel et réalisé
- Taux de transformation devis/commandes
- Note moyenne de satisfaction
- Répartition par type de prestation et par commune

**Why:** this is the concrete next milestone, not derivable from code yet — keeps the dashboard work scoped to what the client actually asked for.
**How to apply:** build on existing models — `Intervention` (statuts/workflow), `Cotation`/`CotationLigne`/`Prestation` (devis, CA, transformation — see [[crm-conventions-roadmap]]), `Organisation`/`Service` (commune). The "relances automatiques" likely means a Solid Queue job over pending `Cotation`s. "Note moyenne de satisfaction" maps to the intervention évaluation. Test everything (project rule: tout ce qui peut être testé doit l'être).

---

---
name: dashboard-scenic-materialized-views
description: "Dashboard graphiques alimentés par des vues matérialisées Scenic, rafraîchies immédiatement à chaque changement"
metadata: 
  node_type: memory
  type: project
  originSessionId: a0f61953-51f2-4d2c-a2e8-81e2de05e2d3
---

Le dashboard ([dashboard_data.rb](app/controllers/concerns/dashboard_data.rb)) lit ses graphiques depuis **2 vues matérialisées PostgreSQL gérées via la gem Scenic** (branche `dashboard-scenic`, livrée 2026-06-18) au lieu de scanner `interventions` : `dashboard_intervention_stats` (grain org/service/adhérent/mois/statut) et `dashboard_agent_stats` (grain org/agent). Mesuré : agrégat full-table ~150 ms à 1 M lignes vs ~0,05 ms sur la vue pré-agrégée.

**Choix du client** (pas le défaut technique que j'aurais recommandé — j'aurais commencé par cache+index) : vues matérialisées + rafraîchissement **« immédiat à chaque changement »**, sans bouton manuel.

**Refresh (simplifié le 2026-07-15, décision PE « volume faible, code minimal »)** : `after_commit` sur `Intervention`/`AgentIntervention` (concern `DashboardRefreshable`, update gardé sur les colonnes du dashboard) → `refresh_dashboard_views` appelle **directement** `Scenic.database.refresh_materialized_view` sur les 2 vues, **synchrone, `concurrently: false`**. Trade-offs acceptés : refresh dans la requête web, verrou de lecture pendant le refresh, une erreur de refresh fait échouer l'écriture, N écritures = N refreshes. **`RefreshDashboardViewsJob` conservé dormant** (plus appelé par personne, PE veut le garder « au cas où ») : c'est l'ancienne version scalable — coalescing DIRTY/INFLIGHT, verrou consultatif PG, `REFRESH CONCURRENTLY` — à rebrancher si la volumétrie augmente.

Subtilités : la vue agent divise `temps_total` par le nombre d'agents **kept** (`users.discarded_at IS NULL`) pour coller à `Intervention#agents` (default_scope discard) — cf. vue v02. Scenic **réapplique seul les index** lors d'un `update_view` matérialisé → ne PAS remettre `add_index` à la main (seulement au `create_view`).

Lié à [[crm-dashboard-cctp]]. Reste non couvert (modèle de données manquant) : répartition par commune, taux de transformation devis→commande, type de prestation par intervention.

---

---
name: permissions-auto-approve
description: User wants broad command auto-approval; only push/destructive/prod actions hard-blocked via PreToolUse hook
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f20049b8-5890-4571-9e3a-a9e94b63a1a4
---

L'utilisateur a demandé (2026-06-08) à **ne plus valider chaque commande à la main**. Configuré dans `.claude/settings.local.json` : `defaultMode: acceptEdits` + `allow: ["Bash", "Read", "Edit", "Write", "Glob", "Grep"]`. Garde-fou déterministe : hook PreToolUse `.claude/hooks/guard-bash.py` (Python, pas de `jq` — jq absent de la machine) qui bloque `git push`/`reset --hard`/`clean`, `db:migrate|rollback|drop|reset`, déploiement (kamal/cap/mina), envois réels Mailgun/Twilio (best-effort).

**Why:** flux trop lourd à tout approuver ; mais app en prod avec vraies communes → les actions irréversibles doivent rester bloquées techniquement, pas seulement par convention.

**How to apply:** ne pas tenter de contourner le hook ni de désactiver les `deny`. Si une action légitimement bloquée est nécessaire (ex. une migration), demander l'accord explicite à l'utilisateur — c'est lui qui pousse/migre/déploie. Le volet mail/SMS est best-effort : rester prudent sur tout `rails runner` qui pourrait déclencher un envoi. Voir [[push-forbidden]] dans le périmètre du CLAUDE.md.

---

---
name: intervention-bugs-detectes-2026-06-22
description: "4 bugs intervention détectés en écrivant les tests (2026-06-22), signalés mais NON corrigés"
metadata: 
  node_type: memory
  type: project
  originSessionId: a2d6452e-aed8-4eb1-881d-60788bcb381f
  modified: 2026-08-03T16:48:59.763Z
---

En renforçant la suite de tests « intervention incassable » (branche `staging`, 2026-06-22), 4 anomalies ont été détectées, **signalées et volontairement non corrigées** (hors périmètre « tests »). Détail en bas de `test/models/intervention_test.rb`. **Statuts re-vérifiés dans le code le 2026-07-10** : #1 et #3 corrigés ; #2 et #4 toujours présents. À arbitrer :

1. **Filtre Statut cassé (prod) — ✅ CORRIGÉ le 2026-06-23** (branche `staging`) — le select « Statut » de l'index est `multiple` → envoie un tableau de libellés humanisés (`["Nouveau"]`), mais `InterventionsController#index` faisait `params[:workflow_state].to_s.downcase` → `'["nouveau"]'` → ne matchait aucune ligne. Fix appliqué : `selected_states = Array(params[:workflow_state]).reject(&:blank?).map(&:downcase)` puis `where(workflow_state: selected_states)`. Test `skip` dé-skippé + tests multi-select et tableau vide ajoutés ; system test slim-select vert. (NB : pour filtrer par « validé » via l'UI, la fixture `tonte_locaux` capitale resterait non matchée — voir #3, distinct.)
2. **Fixture `intervention_validé`** — écrite `adherent_id: weil` (raccourci non résolu par les fixtures) → `adherent_id` reste nil → enregistrement invalide, toute transition workflow dessus lève `RecordInvalid`. Fix : `adherent: weil`. **❌ Toujours présent au 2026-07-10** (`test/fixtures/interventions.yml:43`).
3. **Fixture `tonte_locaux`** — `workflow_state: "Validé"` (capitale) ≠ état du workflow `"validé"`. **✅ CORRIGÉ le 2026-06-23** (→ `"validé"`, committé dans `a9f23e82`). ⚠ Effet de bord : ça démasque que `EmailSubscription#on_intervention_updated` fait `intervention.audits.last.user_id` **sans garde** ; une intervention de fixture n'a aucun audit → `nil` → crash de `should_update_intervention`. **Décision client (2026-06-23) : NE PAS modifier la souscription** (fonctionnalité de notif **dormante**, robustesse reportée à son activation). Réparé côté **données de test** : fixture `test/fixtures/audits.yml` (audit `create` réaliste pour `tonte_locaux`, user valide) → `audits.last` non nil. Suite : 760 runs / 0 échec.
   ⚠️ **RISQUE PROD DIFFÉRÉ (à revoir quand la notif sera activée)** : mesuré sur la base dev — **599/902 audits d'intervention ont `user_id` nil** (créés par jobs/imports sans `current_user`), et **166 interventions ont leur DERNIER audit à `user_id` nil**. Or `on_intervention_updated` fait `User.find(last_audit.user_id)` → `User.find(nil)` lève `RecordNotFound` → **la mise à jour de ces 166 interventions planterait en prod si la souscription était active**. (`last_audit.nil?` lui n'arrive jamais en prod : 0 intervention sans audit.) Correctif futur : `User.find_by(id:) ` + `return if user.nil?`.
4. **`Intervention#calc_temps_total`** — assignait une variable LOCALE `temps_total` sans `self.temps_total = ...` ; le `before_save` ne persistait rien. **✅ CORRIGÉ le 2026-08-03** (demande PE) : `self.temps_total = …` **et `agents.size` au lieu de `agents.count`** — sur un enregistrement neuf, `count` interroge la base avec un `owner_id` nil et renvoie 0, donc le correctif évident aurait enregistré 0 à chaque création. Normalisation `temps_de_pause` nil → 0 remontée en `before_validation` ; accumulateur d'heures de convention durci (`to_f`). Détail au registre.

Voir [[crm-dashboard-cctp]] (le filtre statut alimente aussi des vues métier).

---

---
name: pointage-fille-veille-risque-surveille
description: "Risque surveillé R1 — fille de pointage de la veille non terminée → re-scan créerait une nouvelle intervention ; non reproductible aujourd'hui, re-signaler si les gardes tombent"
metadata: 
  node_type: memory
  type: project
  originSessionId: fe8c88c9-6865-46c2-9e7f-9cb2703079ab
---

Point sensible signalé par PE le 2026-07-10 : si une **fille de pointage** reste `nouveau`/`fin` nil d'un jour antérieur, le re-scan du QR de la mère créerait une **nouvelle** intervention au lieu de terminer l'ancienne (`find_current_intervention` filtre sur `DATE(début) = aujourd'hui`, user.rb:350).

**Statut : NON reproductible (vérifié empiriquement 2026-07-10)** — deux gardes : (1) tâche Hatchbox `interventions:terminer_pointages` à 22h (`TerminerPointagesJob`) ; (2) validation #357 `agents_must_not_have_open_pointage` (intervention.rb:262) qui refuse le scan avec message explicite. Registre détaillé = **R1 dans `suivi/bugs-signales.md`** (section « Risques surveillés »), cf. [[bugs-registre]].

**Why:** Décision client : rien coder tant que non reproductible, mais **re-signaler spontanément** si le bug redevient faisable.

**How to apply:** Alerter PE (et re-tester le scénario) si l'un de ces changements passe dans une session : suppression/affaiblissement de `agents_must_not_have_open_pointage` ; retouche de `create_next_intervention` (le `dup` copie `fin_prévue` → contourne déjà la garde dédiée, seul OVERLAP_SQL bloque), `pointage_ouvert?`, `effective_fin` ou `OVERLAP_SQL` ; élargissement du filtre jour de `find_current_intervention` ; problème de planification Hatchbox (cf. [[hatchbox-cron-syntax]]). Effet de bord connu : une fille orpheline **bloque tout pointage** de l'agent jusqu'à 22h.

---

---
name: checklist-contributing
description: "CONTRIBUTING.md à la racine = checklist des erreurs récurrentes du projet ; l'agent doit l'appliquer à chaque code écrit"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1db9c6b1-5c07-4c0a-b41a-2cba6845e422
---

Le 2026-07-10, PE a demandé une checklist des erreurs récurrentes (tirées de git, du commit sécurité `b7ac9963`, des TODO et du registre de bugs) → livrée dans **`CONTRIBUTING.md` à la racine du repo**, transmissible aux collègues.

**Why:** Les mêmes fautes reviennent : GET mutant (récidive #310 huit jours après l'audit), colonnes/signatures supposées au lieu de vérifiées (4 jobs cassés), `create` sans `!` silencieux, `self.attr =` oublié dans les callbacks, propagation incomplète des renommages, fixtures ancrées sur l'heure réelle, logique métier dans les contrôleurs (les TODO « à déplacer »).

**How to apply:** Avant tout code : vérifier schéma/signatures dans `db/schema.rb`, placer la logique en model/service et les effets de bord en job, POST + `authorize` + `can_xxx?` sur les mutations, `create!` pour les écritures obligatoires, grep sur tout nom changé, jamais d'heure réelle en test. Passer la checklist §2 de CONTRIBUTING.md avant chaque commit ; la citer à PE quand un écart apparaît. Refactorisations différées jusqu'à couverture de tests complète (décision PE). Voir [[bugs-registre]].

---

---
name: bugs-registre
description: Registre unique des bugs signalés (avec parcours de reproduction) dans suivi/bugs-signales.md — à consulter/mettre à jour quand on parle de bugs
metadata: 
  node_type: memory
  type: project
  originSessionId: 11449fe0-c36e-44fd-9286-844708de3045
  modified: 2026-08-06T13:27:29.217Z
---

Depuis le 2026-07-10, tous les bugs signalés par l'agent sont regroupés dans **`suivi/bugs-signales.md`** (repo coopcomm ; **déplacé de `.claude/method/` vers `suivi/` le 2026-08-05** à la demande de PE, parce que le harnais gardait une confirmation sur les chemins sous `.claude/` — cf. [[ecriture-libre-claude-method]] ; suivi par git, donc versionné une fois committé). Chaque bug (B1–B8 à la création) y a : localisation code, cause, **parcours utilisateur de reproduction** (demande explicite du client), impact, correctif proposé ; plus une section « Corrigés » avec les commits.

**Why:** le client veut pouvoir retrouver les bugs à tout moment et comprendre comment les reproduire du point de vue utilisateur, pas seulement techniquement.

**How to apply:** quand le client demande « les bugs » → lire et restituer ce fichier. Quand un nouveau bug est détecté (sessions /tests etc.) → l'ajouter au registre AVEC son parcours de reproduction, et référencer `Bn` depuis CLAUDE.md. Complète (ne remplace pas) [[intervention-bugs-detectes-2026-06-22]].

⚠️ **Règle rappelée par PE le 2026-08-06 — dès que je corrige un bug, je DÉPLACE sa fiche entière** de « 🔴 Bugs ouverts » vers « Fiches détaillées des bugs corrigés », titre préfixé `✅ CORRIGÉ (date)` + ligne « Correctif appliqué ». **Marquer `✅ CORRIGÉ` sur place ne suffit pas** : c'est exactement ce que j'avais fait 34 fois, et PE ne comprenait plus pourquoi des bugs corrigés figuraient dans la liste des bugs à traiter. Le déplacement fait partie de la correction, pas d'un rangement ultérieur. Corollaires : correction **partielle** → la fiche reste dans « ouverts », titre `⚠️ PARTIELLEMENT CORRIGÉ`, reliquat en tête ; **jamais** de nouvelle fiche après la section « Comment s'en servir » (B73/B74 y avaient atterri et échappaient aux deux listes) ; fiches **triées par numéro** dans les deux sections.

Fichier jumeau (même dossier, créé le même jour) : **`suivi/points-a-trancher.md`** = décisions/actions **en attente du client** (D1 = prix devis vs tarif courant = B2 « en réflexion » ; fusion dashboard-scenic ; Hatchbox ; confirmations prod ; dette). Quand le client tranche un point → le déplacer dans « Tranchés » + reporter dans CLAUDE.md. Bugs constatés → registre ; choix à faire → points-a-trancher.

---

---
name: new-function-placement
description: Convention de placement — toute nouvelle fonction se met en dernier parmi les fonctions de sa catégorie
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 4e67ba3a-c8c9-449b-a5d4-330c8a72b7b1
---

Quand j'écris une nouvelle fonction/méthode quelque part, je la place **en dernier** par rapport aux autres fonctions de la **même catégorie** (même groupe logique : actions de contrôleur, méthodes privées, helpers, scopes, callbacks, etc.). Pas au milieu ni en tête du groupe.

**Why:** Le client veut un placement prévisible et stable des ajouts : la dernière fonction d'un groupe est toujours la plus récente, ce qui réduit le bruit de diff et facilite la relecture.

**How to apply:** Avant d'insérer une nouvelle fonction, identifier sa catégorie (les fonctions de même nature regroupées dans le fichier) et l'ajouter **à la fin de ce groupe**. Respecter les regroupements existants plutôt que l'ordre absolu du fichier (ex. ne pas mettre une méthode privée après une publique juste parce que c'est la dernière ligne).

---

---
name: hatchbox-cron-syntax
description: "Incident prod : Hatchbox ne supporte pas la syntaxe cron 0/10 — une seule expression invalide bloque TOUTES les tâches planifiées"
metadata: 
  node_type: memory
  type: project
  originSessionId: b3bcc524-bf73-4f72-b7dd-f313b27bbd97
---

Incident de production vécu par PE (raconté le 2026-07-10) : les tâches planifiées Hatchbox ne se lançaient plus du tout. Cause : une tâche configurée avec l'expression cron `0/10 * * * *` — Hatchbox ne gère pas cette écriture (`0/10`, style Quartz, non POSIX). Effet : **toutes** les tâches étaient bloquées, même celles avec une expression valide (`0 20 * * *`).

**Why:** une seule expression invalide fait tomber tout le planificateur, pas seulement la tâche fautive — panne silencieuse et globale.

**How to apply:** pour toute tâche planifiée sur Hatchbox (ex. `cotations:relancer_adherents`, cf. [[crm-dashboard-cctp]]), utiliser la syntaxe standard `*/10` et vérifier chaque expression existante avant d'en ajouter une. Consigné aussi dans « Pièges connus » de CLAUDE.md.

---

---
name: claude-config-git-visibility
description: "La config Claude (CLAUDE.md, .claude/) est commitée/poussée sur le repo partagé ; PE veut pouvoir purger ces traces ; fichiers privés via .git/info/exclude"
metadata: 
  node_type: memory
  type: project
  originSessionId: b3bcc524-bf73-4f72-b7dd-f313b27bbd97
  modified: 2026-07-28T08:18:35.313Z
---

Constaté le 2026-07-10 : contrairement à la décision notée le 2026-06-05, **toute la config Claude est trackée et poussée** (CLAUDE.md, CLAUDE.minimal.md, `.claude/commands/`, `.claude/hooks/`, `.claude/method/`). PE est **le seul** à utiliser l'agent sur ce projet, mais d'autres développeurs (Dani Isaza, Alexandre Meunier, Philippe) voient le dépôt. Position de PE (précisée le 2026-07-10) : **acceptable pour l'instant**, mais le projet **risque de repasser en public (open-source) un jour** → il faudra alors purger la config Claude de l'historique (et au minimum les détails d'audit sécurité et les noms présents dans CLAUDE.md).

**Why:** deux conséquences pratiques — (1) tout ce que j'écris dans CLAUDE.md est potentiellement lu par l'équipe et poussé (PE committe lui-même mes mises à jour, ex. `29b9b982`) ; (2) un fichier ajouté sous `.claude/` n'est PAS ignoré par défaut.

**How to apply:** pour un fichier Claude qui doit rester hors dépôt, l'ajouter au **`.gitignore`** (choix PE 2026-07-28 : robuste au re-clone et protège aussi les collègues ; l'absence de trace commitée n'est plus le critère puisque la config est déjà publique dans le dépôt — `.git/info/exclude` reste l'option si un jour il faut du « zéro trace »). Cas actuel : `.claude/method/fiches/contexte-projet.md` (fiche contexte remplie — CCTP anonymisé, détails client, cf. [[contexte-projet-jalons]]). Ne rien mettre de sensible ou d'embarrassant dans CLAUDE.md. **Commits (demande PE 2026-07-10) : ne PAS ajouter la ligne `Co-Authored-By: Claude …` dans les messages de commit** — « pour l'instant » ; deux commits déjà réécrits pour la retirer (`8cdaa5e7`, `139da15a`). Le préfixe de titre `Claude : …` reste utilisé (convention existante de PE, ex. `7b71edbe`). Voir [[permissions-auto-approve]].

---

---
name: tldr-chaque-message
description: "PE veut un TL;DR en tête de chaque réponse de l'agent"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 6093979e-fe65-42df-8026-1daa443cc0ad
---

Chaque réponse de l'agent doit commencer par un **TL;DR** (demandé le 2026-07-13, « à partir de maintenant, à chaque message »).

**Why:** PE veut saisir l'essentiel d'un coup d'œil avant de lire le détail — cohérent avec sa méthode (relire la sortie, réponses vérifiables).

**How to apply:** Ouvrir chaque message par une ligne `**TL;DR : …**` qui donne le résultat/la conclusion, puis le détail en dessous. Vaut pour toutes les réponses, y compris les courtes.

---

---
name: format-message-commit
description: "Format imposé des messages de commit proposés : #XXX Thème : changements en bref (thème = modèle touché, ou Test, ou Claude)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 1f255f80-498b-4e1a-923b-de97028d6111
  modified: 2026-08-05T15:41:41.893Z
---

Demande de PE (2026-07-29) : tout message de commit que je propose s'écrit **`#XXX Thème : changements en bref`** — numéro d'issue en tête, puis le **thème**, puis une description brève sur **une seule ligne**. Le thème est en général le **modèle touché** (`Intervention`, `Convention`, `Tool`, `Cotation`, `Home`…), ou **`Test`** quand le commit ne fait qu'écrire/réparer des tests, ou **`Claude`** quand il touche ma configuration (`CLAUDE.md`, `.claude/`, mémoire).

**Why:** c'est la convention déjà majoritaire dans l'historique du dépôt (`#400 Home : les agents voient de nouveau…`, `#394 Intervention : bouton Terminer selon l'affectation…`, `Claude : commentaires simplifiés`) ; mes propositions antérieures s'en écartaient souvent (`#332 : longue phrase sans thème`, deux-points collé au numéro, sous-titre à rallonge).

**How to apply:** une ligne, en français, verbe ou groupe nominal court ; pas de corps de commit à rallonge ni d'énumération de fichiers ; pas de `Co-Authored-By: Claude` (cf. [[claude-config-git-visibility]]). Je **propose** le message, je ne committe jamais moi-même (cf. [[pas-de-commit-par-agent]]). **Le numéro d'issue ne s'invente jamais** : s'il n'a pas été donné par PE ou vérifié dans le dépôt, écrire `#XXX` et demander — cf. [[numero-issue-jamais-invente]].

---

---
name: numero-issue-jamais-invente
description: "Interdit absolu d'inventer un numéro d'issue/US GitHub (#XXX) : soit PE le donne, soit je laisse #XXX et je demande"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 45b27d90-8557-40d6-8e89-6f683025765f
  modified: 2026-08-05T15:41:31.286Z
---

Demande de PE (2026-08-05, après **deux** erreurs de sa part causées par mes numéros inventés) : je n'écris **jamais** un numéro d'issue/US GitHub que je n'ai pas reçu de PE ou vérifié dans le dépôt. Cela vaut partout : messages de commit proposés, notes de `CLAUDE.md`, `suivi/bugs-signales.md`, `suivi/points-a-trancher.md`, commentaires, tout texte que je produis.

**Why:** le backlog GitHub est privé et je n'y ai aucun accès — un `#445` qui « ressemble » au bon numéro est une pure invention plausible, et PE l'a recopiée telle quelle dans deux commits. Un numéro faux rattache le travail à la mauvaise issue et se propage dans l'historique du dépôt, où il est coûteux à corriger.

**How to apply:** par défaut, écrire littéralement **`#XXX`** et demander en une ligne « quel numéro d'issue ? ». Ne déduire un numéro que d'une **source vérifiable** — `git log` du dépôt (issue déjà référencée par un commit existant), ou un numéro que PE vient de donner dans la conversation — et dire d'où il vient. Ne jamais extrapoler à partir d'un numéro voisin, d'une date, ni d'une issue mentionnée dans une note antérieure de `CLAUDE.md` (elle peut elle-même venir d'une invention). Même règle pour les numéros de PR. Voir [[format-message-commit]].

---

---
name: pas-de-commit-par-agent
description: "L'agent ne committe plus lui-même — il propose un message de commit, PE committe"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 42969af2-f6fc-45bf-86db-4c8a31e6ef64
---

Demandé le 2026-07-13 : quand des modifications sont prêtes, **proposer un message de commit** (format du projet : `#<issue> : description`) mais **ne pas exécuter `git commit`** soi-même. Remplace l'autonomie « git commit en local autorisé » accordée le 2026-06-05.

**Why:** PE veut garder la main sur l'historique git (il est aussi le seul utilisateur de l'agent et envisage de purger les traces de l'agent du dépôt — cf. [[claude-config-git-visibility]]).

**How to apply:** en fin de tâche, présenter les fichiers modifiés + un message de commit prêt à copier ; ne jamais lancer `git commit` (ni a fortiori `git push`, déjà interdit) sans demande explicite.

---

---
name: ecriture-libre-claude-method
description: "PE autorise l'écriture directe dans les fichiers de suivi (CLAUDE.md, suivi/, .claude/, mémoire) sans jamais demander confirmation"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: dcd138d1-bbb1-44ee-b093-e5c42d230957
  modified: 2026-08-05T11:19:35.050Z
---

PE a accordé (2026-07-13, **élargi le 2026-07-27**, **réaffirmé avec agacement le 2026-07-28** : « arrête de me demander ! Tu auras toujours le droit de le faire ! Pareil pour tous les fichiers stockés dans .claude ») une autorisation durable : l'agent écrit **sans demander son accord au préalable** — et sans formuler quoi que ce soit qui ressemble à une demande — dans **`suivi/`** (`bugs-signales.md`, `points-a-trancher.md`), **tout `.claude/`** (`journal-session.md`, fiches, golden-set…), la **section 1 de `CLAUDE.md`** (état d'avancement, décisions), et le répertoire de mémoire persistante.

**Why:** Ce sont les fichiers de mémoire/méthode de l'agent lui-même, et `CLAUDE.md` §2-3 exige déjà de les tenir à jour à chaque session. Demander la permission à chaque mise à jour de registre ralentit le flux sans rien protéger. PE l'a redemandé ~4 fois (2026-07-13 → 2026-07-28) : **écrire, puis signaler ce qui a été écrit** — ne jamais formuler de demande.

**⚠ Correction du diagnostic (2026-07-28)** : la note précédente accusait l'agent de solliciter de lui-même. C'était faux — le prompt « make this edit to bugs-signales.md? » est émis par le **harnais**, pas par l'agent, donc aucune promesse en langage naturel ne pouvait l'éteindre (d'où les 4 rechutes malgré `defaultMode: acceptEdits` + `Edit`/`Write` dans `allow`). **Corrigé côté config** : hook PreToolUse `.claude/hooks/allow-notes.py` (matcher `Edit|Write|NotebookEdit`) qui renvoie `permissionDecision: "allow"` pour **tout `.claude/` sans exception** (y compris `hooks/` et `settings.local.json` — PE a maintenu sa demande après signalement du risque de désarmement des garde-fous), le **répertoire de mémoire** et **`CLAUDE.md`** — décision déterministe, plus de prompt possible. Non couverts : `~/.claude/settings.json` (global) et `/home/pedacquet/aikku/CLAUDE/.claude` (autre dépôt). Si le prompt réapparaît malgré tout : vérifier que le hook est chargé (ouvrir `/hooks` une fois recharge la config).

**⚠ Suite (2026-08-05) — le hook ne suffisait toujours pas pour `.claude/`** : PE a continué de voir la confirmation sur `bugs-signales.md` / `points-a-trancher.md` malgré le hook ET les règles `allow` scopées du 2026-07-29. Conclusion : la garde du harnais sur les chemins sous `.claude/` n'est pas annulable. **Les deux registres ont donc été déplacés vers `suivi/` à la racine du dépôt** (`git mv`, historique préservé) — un dossier projet ordinaire, couvert par `defaultMode: acceptEdits`, plus le hook et les règles `allow(suivi/**)` en filet. Renvois mis à jour dans CLAUDE.md §1, CONTRIBUTING.md, le hook et [[bugs-registre]]. Les autres fichiers de `.claude/method/` (journal, fiches, golden-set) restent en place : ils sont bien plus rarement écrits.

**How to apply:** Mettre à jour ces fichiers directement dès qu'un bug est signalé, un point tranché ou une session à consigner, et lister les fichiers touchés en fin de réponse. Ne s'applique **pas** au reste du dépôt (code, tests, vues) : là, les règles habituelles tiennent — l'agent édite, mais ne committe jamais (cf. [[pas-de-commit-par-agent]]) et signale sans corriger les bugs de prod sous `/tests` (cf. [[bugs-registre]]).

---

---
name: questionner-la-premisse-du-workflow
description: "Leçon 2026-07-16 (rails test:all manqué) — avant d'ingénier autour d'un workflow douloureux, chercher d'abord la commande/voie canonique de l'outil pour l'objectif de fond"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 548d4c1f-25e8-4ab8-ae7a-9b0a46397ce5
---

Le 2026-07-16, PE a découvert seul que `bin/rails test:all` lance toute la suite
(système inclus) en un seul run — alors que les sessions précédentes (B14,
2026-07-13-d) avaient produit des correctifs d'isolation (base dédiée, fixture
`model_class`, règle « jamais deux runs simultanés ») sans jamais mentionner
cette commande. Il a demandé pourquoi.

**Why:** J'avais pris la prémisse « je lance `rails test` et `rails test:system`
en même temps » comme une contrainte à préserver, et cherché « comment faire
coexister deux runs » au lieu de me demander « quelle est la façon canonique de
lancer tous les tests ? ». Erreur de cadrage : optimiser le workflow tel que
donné au lieu de l'interroger. (`test:all` n'apparaît pas dans `bin/rails -T`
— la tâche rake n'a pas de desc — mais figure dans le guide officiel Rails :
une recherche sur l'objectif de fond l'aurait trouvé.)

**How to apply:** Quand un workflow utilisateur cause des douleurs récurrentes,
la recherche de solutions doit TOUJOURS inclure une passe « l'outil a-t-il déjà
une voie de première classe pour l'objectif de fond ? » (reformuler le problème
sans le workflow actuel), avant de proposer des contournements. Présenter les
deux à PE : la voie canonique ET le contournement, avec leurs trade-offs.
Lié : [[bugs-registre]] (ex-B14 du stash, reclassé R2 le 2026-07-16 ; le
durcissement `audits.yml` a finalement été abandonné par PE au profit de
`rails test:all` seul).

---

---
name: tests-data-testid-autorise
description: "/tests — autorisation d'ajouter des data-testid au code de prod plutôt que de contorsionner les tests"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f5193837-732d-4d49-843a-30543c86b558
  modified: 2026-07-22T08:44:00.762Z
---

Sous `/tests` (T13), j'ai le **droit d'ajouter un attribut `data-testid`** sur un élément de vue quand c'est le moyen le plus fiable de le cibler — au lieu d'écrire un sélecteur fragile (CSS/XPath/`title=`/`data-action`) ou un helper de test qui contourne un markup non ciblable. Décision PE du 2026-07-22, après discussion data-testid vs sélecteurs sémantiques (rôle/label). **Uniquement `data-testid`** : pas de repli `id` (un id ajouté est un moins bon crochet — unicité exigée, sémantiques de page réelles) ; réutiliser un id Rails existant ne nécessite aucune autorisation ; réparer un `label[for=]`/`id` cassé relève de la voie sémantique différée → à **signaler**, pas corriger.

**Why:** l'ancien interdit « ne modifie pas le code de prod » me poussait à des contorsions de tests bizarres au lieu du bon correctif. PE veut **les tests les plus stables possible** ; il a choisi `data-testid` (et non la voie aria-label/`for=` sémantique) pour l'instant.

**How to apply:**
- Un `data-testid` est **inert** (aucun effet sur le comportement) → hors de l'interdit, qui ne vise désormais que la **logique** de prod (contrôleurs/models/workflow/services/comportement des vues).
- Toute **autre** modif de prod (logique, correction de bug) reste **signalée, non appliquée** (règle /tests point 5) — voir [[bugs-registre]].
- **Signale** les vues que j'ai touchées (ce sont des diffs à relire), et je ne committe pas moi-même (cf. [[pas-de-commit-par-agent]]).
- Règle inscrite dans `.claude/commands/tests.md` et le template T13 de `.claude/method/kit-prompting.md` (copies projet). Les masters partagés `~/aikku/CLAUDE/` ne sont PAS encore modifiés.
- Contexte technique : `Capybara.enable_aria_label` est absent du projet, donc les finders sémantiques ne voient pas les aria-label — c'est une des raisons pour lesquelles data-testid est le levier retenu ici.

---

---
name: contexte-projet-jalons
description: "Jalons CoopComm : prod client début sept. 2026, ~10 j de dev restants (features en pause), contrat → mars 2028, open-source envisagé mi-nov. 2026 ; fiche contexte remplie ; AUCUN backup BDD prod (A4)"
metadata: 
  node_type: memory
  type: project
  originSessionId: b3bcc524-bf73-4f72-b7dd-f313b27bbd97
  modified: 2026-07-28T07:50:31.104Z
---

Fiche contexte remplie le 2026-07-28 (PDF de PE) → **source détaillée = `.claude/method/fiches/contexte-projet.md`** (locale, hors dépôt) : utilisateurs réels, parcours critiques, digest CCTP anonymisé, équipe, volumétrie.

Jalons durs : **mise en prod client début septembre 2026** ; **~10 jours de développement restants**, nouvelles fonctionnalités **en pause** ; support renforcé 6 mois post-prod ; **fin de contrat mars 2028** ; **open-source en réflexion, échéance mi-novembre 2026** (salon des maires), licence peut-être GPLv3.

**Why:** tout arbitrage (périmètre d'un correctif, proposer ou non une feature) doit tenir compte du budget ~10 jours et de l'échéance septembre ; « catastrophique » pour le client = tout ce qui touche à l'argent (temps total, attribution) + un agent qui verrait son évaluation.

**How to apply:** lire la fiche avant toute décision métier/UX. Signalement majeur en attente : **aucune sauvegarde de la base de prod** (exigence CCTP : quotidien, rétention 365 j) = **A4** dans `points-a-trancher.md`. D1/B2 (prix devis) éclairé par la fiche (« le tarif est stocké dans la commande ») mais non tranché. Voir [[pe-profil]], [[bugs-registre]], [[hatchbox-cron-syntax]], [[pointage-fille-veille-risque-surveille]].

---

---
name: doctrine-tests-menace
description: "Doctrine PE 2026-07-28 : pas de mass assignment réel (sauf compte volé) ; menace = curieux via l'UI (avis/note, infos privées d'autrui) ; privilégier les tests du quotidien, sécurité plus tard"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f253fc19-8fc8-4fa1-970e-e1d2a873d8e5
  modified: 2026-07-28T09:28:13.948Z
---

Doctrine de tests actée par PE le 2026-07-28 (consignée aussi dans la fiche `.claude/method/fiches/contexte-projet.md`, section « Modèle de menace ») :
- **Aucun utilisateur ne fera de mass assignment / requête forgée** — seul scénario possible : compte volé par un malveillant.
- **Menace réaliste = les curieux via l'UI normale** : surtout ce qui les concerne (avis/note d'évaluation) et les infos privées d'autres utilisateurs.
- **Privilégier les tests du quotidien / cas concrets** (parcours réels, boutons/exports visibles) ; la plupart des tests de sécurité viendront **plus tard**.

**Why:** oriente le choix des cas de test dans toute session `/tests` — un test « paramètre forgé » vaut moins qu'un test « ce que voit un curieux en cliquant ».

**How to apply:** en construisant une matrice de tests, classer d'abord les parcours UI réels et les expositions de données visibles (pages, exports XLS/PDF, mails) ; ne garder les tests de forge/mass assignment que pour l'argent ou sur demande. Les tests critiques sont marqués `# Test critique` **en tête** des fichiers de test existants (pas de fichier dédié). Voir [[contexte-projet-jalons]], [[bugs-registre]].

---

---
name: style-commentaires-code
description: "PE veut des commentaires de code minimaux — pas de commentaire quand le nom suffit, jamais de nom de personne ni d'historique"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: b25337d8-7137-4f95-aabe-3840ebec2f8f
  modified: 2026-07-28T14:18:15.664Z
---

Écrire le **moins de commentaires possible** dans le code de prod. Par défaut : **aucun**. Un nom de méthode explicite (`redirect_si_invalide`, `terminer_destination`) rend le commentaire inutile — le supprimer entièrement plutôt que le résumer.

Interdits dans un commentaire : le nom d'une personne (PE, Dani…), la justification historique (« à la demande de… », « le bug remontait en 500 »), les numéros d'issue/session, la paraphrase du code.

Toléré, **une ligne maximum** : la forme d'un retour non devinable (`# […lien, méthode HTTP]`), ou un « pourquoi » réellement contre-intuitif qu'aucun lecteur ne peut déduire du code.

**Why:** PE lit le code, pas les commentaires ; un pavé explicatif est du bruit qui vieillit mal et devient faux. Le contexte, l'historique et les raisons ont déjà leur place dans CLAUDE.md, `suivi/bugs-signales.md` et les messages de commit.

**How to apply:** avant d'écrire un commentaire, se demander si le nom de la méthode ou la lecture des 5 lignes suivantes donnent déjà l'information — si oui, ne rien écrire. Vaut aussi pour les en-têtes de fichiers de test : garder les pièges techniques réellement utiles, pas le récit de la session. Voir [[pe-profil]], [[checklist-contributing]].

---

---
name: style-compte-rendu
description: "Comptes rendus courts — seulement ce que PE ne peut pas lire dans le code (décisions à valider, faits mesurés contre-intuitifs, points ouverts)"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 17c51046-959b-46eb-9d8d-44af87cc90d3
  modified: 2026-08-28T09:02:22.644Z
---

PE ne veut plus le détail de ce qui a été fait : il lit le code. Un compte rendu ne
contient que ce qui **ne se lit pas dans le diff**.

**Why:** demandé le 2026-08-28, après un compte rendu qui listait fichier par fichier
l'implémentation — information redondante avec le code, qui noie ce qui demande une
décision de sa part.

**How to apply:** garder — le résultat (suite de tests, état vert/rouge) ; les **faits
mesurés contre-intuitifs** qui justifient la conception ; les **choix tranchés seuls**
qui attendent sa validation ; ce qui reste **ouvert ou à signaler** ; le message de
commit. Supprimer — l'inventaire des fichiers, la liste du « livré », la chronique de
l'écriture des tests, la reformulation de ce que le code dit déjà. Le détail reste
consigné dans [[bugs-registre]] et la section 1 de CLAUDE.md, pas dans la réponse.
Continuer à ouvrir par le TL;DR ([[tldr-chaque-message]]).

---

---
name: rappel-d18-required-masque
description: "PE veut qu'on lui rappelle de traiter D18 (champ required masqué par du JS → soumission bloquée en silence) tant qu'il n'est pas tranché"
metadata: 
  node_type: memory
  type: project
  originSessionId: 17c51046-959b-46eb-9d8d-44af87cc90d3
  modified: 2026-08-28T09:45:13.958Z
---

PE a demandé (2026-08-28) qu'on lui **rappelle de traiter D18** : un champ `required`
que le navigateur ne peut pas focaliser (masqué par du JS, `display: none`, ancêtre
replié) annule la soumission **sans afficher aucune bulle** — l'utilisateur clique
« Enregistrer » et rien ne se passe. La fiche est dans `suivi/points-a-trancher.md`
(cf. [[bugs-registre]]) ; ce qui manque est une sentinelle qui vérifie que tout champ
`required` d'un formulaire est atteignable.

**Le remettre sur la table en début de session** tant qu'il reste dans « à trancher ».

---

---
name: helper-test-un-seul-fichier
description: "Un helper de test utilisé par un seul fichier vit dans ce fichier, jamais dans application_system_test_case.rb ni test_helper.rb"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 17c51046-959b-46eb-9d8d-44af87cc90d3
  modified: 2026-08-28T12:11:30.894Z
---

Une méthode de test n'est mutualisée que si **plusieurs fichiers** l'appellent. Utilisée
par un seul, elle vit sous `private` dans ce fichier — même quand elle « aurait l'air »
générale.

**Why:** rappelé par PE le 2026-08-28 après que j'ai posé `assert_page_defilee`,
`assert_champ_degage_des_barres` et `taille_pc_courte` dans
`test/application_system_test_case.rb` alors qu'un seul fichier s'en servait. Un helper
partagé se lit comme un contrat de toute la suite : le mettre là pour un seul appelant
gonfle la base commune et fait croire à un usage qui n'existe pas.

**How to apply:** avant de poser une méthode dans `application_system_test_case.rb` ou
`test_helper.rb`, compter les fichiers appelants — deux ou plus, elle est partagée ;
un seul, elle descend dans le fichier, sous `private`, en fin de classe, son commentaire
collé à elle. Elle remonte le jour où un second fichier l'appelle, pas avant. C'est aussi
ce que dit la skill `tests-coopcomm`.

---

---
name: recherche_quand_bloque
description: "Après plusieurs tentatives échouées, faire de la recherche au lieu de continuer à tâtonner"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: c212fae5-06c4-4b5e-9166-04859b4ec5ba
  modified: 2026-07-30T16:06:51.265Z
---

**Règle :** Après 3-4 tentatives de fix qui ne fonctionnent pas, pause et fais de la recherche (documentation, Stack Overflow, issues GitHub, etc.) au lieu de continuer à essayer des variations de la même approche.

**Why :** Le tâtonnement itératif peut masquer un problème fondamental (mauvaise hypothèse, comportement de l'outil non documenté, syntaxe incorrecte). La recherche révèle souvent une solution simple qu'on aurait trouvée 5 tentatives plus tôt.

**How to apply :** Si un fix ne marche pas après 2-3 tries, cherche :
- Documentation officielle de l'outil/framework
- Issues GitHub ou Stack Overflow du même problème
- Comportement spécifique en CI (GitHub Actions, env vars)
- Si c'est un framework (Rails), sa documentation ou ses tests pour voir comment on fait ça normalement

