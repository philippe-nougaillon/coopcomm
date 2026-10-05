# Points à trancher — CoopComm

> **Décisions** (métier ou de conception) qui attendent PE, l'équipe ou le client. Ce que l'agent n'a pas le droit de faire seul est dans `actions-a-faire.md`, la dette actée dans `dettes-ouvertes.md`, ce qui serait mieux sans rien bloquer dans `perfectionnements-a-faire.md`, un fait à connaître dans `a-savoir.md`, les décisions prises dans `points-tranches.md`.
>
> **Gravité** — la fiche va dans la section de ce qui **reste cassé ou exposé tant que le point attend** :
> - 🔴 **Bloque la prod ou l'argent** : obligation contractuelle, argent, sécurité devant de vrais utilisateurs.
> - 🟠 **Attendu avant la montée en charge** : rien de cassé aujourd'hui, mais un chemin réel y mène.
> - ⚪ **Confort** : acté, non planifié.
>
> **Règle de tenue** : prochain numéro libre ci-dessous, rangement **par numéro** dans la section. Un point tranché quitte ce fichier pour `points-tranches.md`, titre préfixé `✅ TRANCHÉ (AAAA-MM-JJ)`, décision et date dans la fiche ; l'agent reporte ensuite dans `CLAUDE.md` ce qui change une convention.
>
> **Prochain numéro libre : D21**
<!-- D15 à D17 n'existent pas sur staging : numéros perdus avec une copie de travail non commitée. D18 garde son numéro, cité dans CLAUDE.md. -->

---

## 🔴 Bloque la prod ou l'argent

_Aucun._

## 🟠 Attendu avant la montée en charge

### D5 — Workflow de validation des documents d'outil : supprimé ou en pause ? (constat du 2026-07-10)
- **Question** : la refonte UX (Dani Isaza, commits `3ae4f02e` du 2026-07-02 « UX - corriger github actions » et `42085022` du 2026-07-03 « UX - solution github ») a **désactivé toute la fonctionnalité** valider/refuser des documents d'outil : actions commentées dans `documents_controller.rb`, routes commentées (`resources :documents, only: %i[]`), workflow commenté dans `document.rb`, boutons retirés du partial `_document.html.erb` (colonne État vide). Le formulaire outil est passé des nested attributes (fichier + état par document) à une **dropzone unique** `form.file_field :documents`. Est-ce une suppression **assumée** de la fonctionnalité, ou un débranchement **temporaire** pour faire passer la CI (les noms de commits le suggèrent) ?
- **Conséquence immédiate** : les 3 system tests de `test/system/documents_test.rb` échouaient (ils testent l'UI disparue) → **commentés le 2026-07-13** (décision client : « pour l'instant on ne l'utilise pas ») avec renvoi vers ce point. À trancher avec Dani : si suppression assumée → supprimer le fichier de test ; si temporaire → réactiver la fonctionnalité et décommenter/adapter les tests.
- **Incohérence à signaler au passage** : `tools_controller#tool_params` permet toujours `documents_attributes` alors que le formulaire n'envoie plus que `documents` (fichier simple) — l'upload de documents depuis le formulaire est probablement cassé aussi côté serveur (non vérifié).
- **Rebalayé le 2026-09-22** : `tool_params` ne permet plus `documents_attributes` mais `:document` ([tools_controller.rb:132](app/controllers/tools_controller.rb#L132)) — l'incohérence signalée n'existe plus ; `test/system/documents_test.rb` a été supprimé le 2026-08-26 (`c0a719b9`, #483). La question de fond est inchangée : routes `only: %i[]`, actions du contrôleur et workflow du modèle toujours commentés.

### D7 — Absences : les 3 écarts restants après le lot du 2026-07-30 (`#419`, `eaa5ac86`, `967781b7`)
- **Contexte** : le CCTP ne contient **aucune exigence** sur les absences (vérifié dans le digest anonymisé de `fiches/contexte-projet.md` ; PE n'a pas transmis le PDF complet, à recouper si un doute contractuel apparaît). La fonctionnalité est un *moyen* du planning, pas un livrable exigé → rien de bloquant pour septembre. Les 5 demandes de PE du 2026-07-30 sont livrées ; ce qui suit ne l'est pas.
- **① Motifs incomplets** — l'enum ne connaît que `congés_payés`, `congé_parental`, `formation`, `congé_sans_solde` ([absence.rb:10](app/models/absence.rb#L10)). Il manque **maladie / arrêt de travail**, statistiquement le premier motif d'absence sur ~115 agents, et probablement RTT et autorisation exceptionnelle. **Aucune migration nécessaire** (ajout de valeurs d'enum + `MOTIF_LABELS`) ; ~5 min. *Décision attendue : la liste exacte des motifs voulus par le client.*
- **② Export XLS « Jours d'absence » non fiable** ([export_to_xls/agents.rb:31](app/services/export_to_xls/agents.rb#L31)) — `agent.absences.sum(&:nb_jours)` somme **tout l'historique** (jamais borné à une année), en **jours calendaires** (week-ends et fériés comptés), et une **demi-journée vaut 1 jour** (`(au - du) + 1`). Deux agents d'ancienneté différente sont incomparables. *Décisions attendues : période de référence (année civile ? 12 mois glissants ?), jours ouvrés ou calendaires, demi-journée = 0,5.* Ne pas publier ce chiffre en l'état s'il sert au pilotage RH ou à la refacturation.
- **③ Calendrier des agents illisible sur les absences** ([users/_agent.html.erb:62-71](app/views/users/_agent.html.erb#L62)) — même carré `bg-[#db2767]` pour « occupé » et « absent », l'information ne vit que dans le `title` au survol, donc invisible sur le Samsung S8 des agents. Le filtre « absent » est commenté dans le contrôleur ([users_controller.rb:179-186](app/controllers/users_controller.rb#L179)) avec un TODO proposant le bon remède (cases grisées). *À traiter seulement si `agent_calendrier` est réellement utilisé — la fiche contexte le donne comme « la seule fonctionnalité qui risquerait d'être ignorée ».*
- **Plus mineur, non chiffré** : aucune vue d'ensemble des absences (routes `only: [:destroy]`, il faut ouvrir chaque fiche agent) ; suppression via `link_to … turbo_method: :delete` ([_absence_form.html.erb:64](app/views/users/_absence_form.html.erb#L64)) au lieu de `button_to`, contraire à la doctrine « plus jamais de GET mutant » de l'audit 2026-06-12 §3.
- **Asymétrie restante, assumée** : `Absence#no_overlapping_interventions` et `Intervention#check_absence` sont désormais alignés (demi-journées + dates réelles des deux côtés). Le seul écart conservé est volontaire : la **clôture d'un pointage déjà ouvert** échappe au contrôle (`Intervention#clôture_de_pointage?`), sans quoi une absence posée en cours de journée figerait le pointage ouvert et ferait échouer la clôture nocturne.
- **Rebalayé le 2026-09-22** : ① toujours 4 motifs ; ② export inchangé ([export_to_xls/agents.rb:31](app/services/export_to_xls/agents.rb#L31)) ; ③ même carré `bg-[#db2767]` ([_agent.html.erb:68](app/views/users/_agent.html.erb#L68) et `:81`) ; le filtre « absent » est **actif** dans `users#index` ([users_controller.rb:32](app/controllers/users_controller.rb#L32)) et seulement commenté dans `agent_calendrier` (`:154`) ; suppression toujours en `link_to … turbo_method: :delete` ([_absence_form.html.erb:68](app/views/users/_absence_form.html.erb#L68)).

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

### D18 — Un champ obligatoire masqué bloque l'enregistrement sans aucun message : faut-il une sentinelle ? (ouvert le 2026-08-28, fiche reconstituée le 2026-09-14)

- **Le problème, en une phrase** : quand un champ `required` est dans un conteneur que le navigateur ne peut pas atteindre (`display: none`, classe `hidden`, bloc replié), un clic sur « Enregistrer » **ne fait rien** — pas de bulle, pas de message, rien n'est envoyé au serveur.
- **Mesuré (Chromium, 2026-09-14, sonde jetable hors dépôt)** : formulaire avec un `<input name="prenom" required>` vide dans un `<div style="display:none">`. Clic sur le bouton → **formulaire non soumis**, le focus **reste sur le bouton**, aucune bulle affichée. La seule trace est dans la console du navigateur, invisible pour l'utilisateur : `An invalid form control with name='prenom' is not focusable.`
- **Pourquoi c'est sournois** : le serveur ne reçoit rien, donc aucun log, aucune erreur, aucun test de contrôleur ne peut le voir. Pour l'utilisateur, le bouton « est cassé ». Et un test système ne le voit que s'il remplit tous les champs **sauf** celui qui est masqué.
- **État actuel du dépôt (vérifié le 2026-09-14) : aucun cas actif connu**, mais chaque cas existant ne tient qu'à un **contournement écrit à la main** :
  - **Formulaire utilisateur** — `toggle_role_info_controller.js` masque *Prénom* pour un adhérent et *Localisation* pour les autres rôles ; il **retire `required`** du champ qu'il masque, et le remet quand il l'affiche. Le jour où quelqu'un ajoute un champ obligatoire dans une de ces zones sans penser à la bascule, le formulaire se bloque pour un rôle.
  - **Absence en demi-journée** — le champ *Au* est `required` et son conteneur prend `hidden` ; il reste valide seulement parce que `syncDates` recopie *Du* dans *Au*.
  - **Selects slim-select obligatoires** — le vrai `<select>` est masqué par le widget. `application.css` le garde volontairement *focusable* (`opacity: 0` et non `display: none`, commentaire en place) — c'est précisément ce piège qui est évité là.
  - **Zones de dépôt de fichier** — l'input réel est caché : c'est pour cela qu'aucun champ fichier ne porte `required` (constat du 2026-08-04 sur l'import XLS).
- **Ce qui manque** : rien ne détecte un **nouveau** cas. Le risque vient d'une modification future — un champ ajouté dans un bloc repliable, une bascule JS qui oublie `required` — et il passe tous les tests actuels.
- **À trancher** :
  1. **Sentinelle système** (recommandation) : sur chaque formulaire, pour chaque combinaison d'affichage qui compte (rôles du formulaire utilisateur, demi-journée d'absence…), vérifier par JavaScript que **tout champ `required` visible pour le serveur est atteignable** — c'est-à-dire que ni lui ni un ancêtre n'a un `display: none` calculé. Coût : un fichier de test, à étendre à chaque formulaire à bascule.
  2. **Filet côté navigateur** : un petit contrôleur Stimulus global qui écoute l'événement `invalid` et, si le champ n'est pas visible, affiche un message générique (« Un champ obligatoire est incomplet ») au lieu du silence. Protège aussi les cas qu'aucun test n'anticipe, mais masque le défaut au lieu de le faire tomber en test.
  3. **Ne rien faire** et s'en remettre aux contournements existants — acceptable tant qu'aucun formulaire à bascule n'est ajouté ; à revoir si la mise en prod fait remonter un « le bouton ne marche pas ».
- **À rappeler à PE en début de session tant que ce point est ouvert** (demande du 2026-08-28, consignée dans `CLAUDE.md` §4).

### D19 — slim-select chargé depuis unpkg à l'exécution, sans copie locale (constat 2026-10-05)
- **Constat** : [application.html.erb:21-22](app/views/layouts/application.html.erb#L21) charge `slimselect.umd.min.js` et `slimselect.css` depuis `https://unpkg.com/slim-select@2.13.1/…` ; aucun pin importmap, aucune copie dans `vendor/`. Tout le reste du JavaScript est servi par l'application.
- **Ce qui casse sans la bibliothèque** (déduit de la CSS, non simulé) : [application.css:322](app/assets/stylesheets/application.css#L322) applique à tout `select[data-controller~="slim-select"][required]` `opacity: 0`, `pointer-events: none` et `position: absolute` **dès le rendu HTML**, widget ou pas. Si le script ne se charge pas (unpkg indisponible, proxy filtrant d'une collectivité, service worker de la PWA #514 s'il sert un jour les pages hors-ligne), `new SlimSelect` lève dans `connect()` et les champs obligatoires des formulaires — adhérent et service d'une intervention, rôle et services d'un utilisateur, lignes de devis/commande/facture, matériel et état d'un mouvement, unité d'une prestation, utilisateurs d'un site — **disparaissent sans message** ; les filtres d'index, eux, retombent sur un select natif utilisable.
- **À trancher** : (1) servir la bibliothèque depuis l'application — copie de l'UMD et de la feuille dans les assets, aucun changement de code, mise à jour manuelle ; ou (2) `bin/importmap pin slim-select --download` et `import SlimSelect from 'slim-select'` dans `slim_select_controller.js` et `dynamic_select_controller.js` ; ou (3) garder le CDN. Arguments pour (1) ou (2), au-delà de la robustesse : l'ouverture du code prévue mi-novembre 2026 (un dépôt qui tourne sans appel sortant) et les zones blanches du service technique.
- **Steelman du statu quo** : version épinglée (`@2.13.1`), cache long, CDN mondial ; l'application elle-même est inutilisable sans réseau, donc la bibliothèque ne tombe seule que sur panne unpkg ou filtrage du domaine.

## ⚪ Confort

### D10 — Fusion des deux formulaires d'intervention
Le découpage du 2026-08-05 a ramené `_form` à 83 lignes d'ossature et `_form_for_agents` à 172, tous deux consommant les mêmes blocs. Il ne reste que **trois** différences réelles, toutes visibles en tête de `_form_for_agents` :
- pas de champ description, et le service est figé sur `current_user.services.first` ;
- l'adhérent n'est modifiable que sur un bon saisi par un agent (`bon?` et hors pointage) ;
- les dates réelles sont **toujours** obligatoires et disposées côte à côte, là où l'autre formulaire ne les exige qu'à la terminaison.
Les deux premières s'expriment déjà par des prédicats de policy (`saisir_description?`, `choisir_service?`, `choisir_adherent?`). **À trancher : fusionne-t-on ?** Le gain serait un seul formulaire ; le coût, une troisième condition sur la disposition et l'obligation des dates.
- **Rebalayé le 2026-09-22** : toujours deux formulaires, 76 et 192 lignes.

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
- **Re-mesuré le 2026-09-22 (§6)** : 7 interventions à `temps_total` négatif sur 262 en base de dev, toutes modifiées avant le 2026-08-10, aucune depuis #462.
