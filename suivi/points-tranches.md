# Points tranchés — CoopComm

> Décisions prises, **de la plus récente à la plus ancienne**, avec la décision et sa date dans la fiche. En bas : le récapitulatif des décisions anciennes. Points en attente : `points-a-trancher.md`.
>
> **Règle de tenue** : une fiche arrive ici **entière** depuis `points-a-trancher.md`, **en tête de liste**, titre préfixé `✅ TRANCHÉ (AAAA-MM-JJ)`.

---

## ✅ Tranchés, du plus récent au plus ancien

### D3 — ✅ SANS OBJET (2026-09-21) — Activation future des notifications `EmailSubscription` (= bug **B8**)
- **Question** : quand (si) on active la notif « intervention mise à jour », valider le correctif préalable (`User.find_by` + garde nil) — 166 interventions crasheraient sinon.
- **Contexte** : fonctionnalité dormante, décision client du 2026-06-23 de ne pas y toucher d'ici là.
- ⚠️ **Requalifié le 2026-07-31** : `on_intervention_updated` n'existe plus, mais la même ligne non gardée subsiste dans `on_intervention_workflow_changed` ([email_subscription.rb:7](app/subscriptions/email_subscription.rb#L7)), qui lui est **bien actif** (publié par valider/refuser/archiver et par `Intervention#apres_terminaison`). Ce n'est donc plus un risque conditionné à une activation future : voir B8 au registre. Le handler voisin `on_intervention_done` a déjà reçu le garde le 2026-07-29-h.
- ⚠️ **Mis à jour le 2026-09-21** : B8 est **corrigé** (la propagation du `user_id` nil a frappé en production, voir sa fiche dans « Bugs corrigés »). La ligne 7 non gardée est reclassée en **risque surveillé R5** : non atteignable aujourd'hui, deux gardes indépendantes mesurées. Ce point n'attend donc plus de décision ; il reste ici tant que PE ne l'a pas déplacé dans « Tranchés ».

### D1 — ✅ TRANCHÉ PAR LE CODE (2026-08-11, commit `0a83223d` #465) — Prix du devis vs tarif courant (= bug **B2** du registre)
- **Question** : quand une commande est créée depuis une cotation signée (puis une facture depuis la commande), quel prix fait foi — celui **signé sur le devis** ou le **tarif courant** de la prestation ?
- **Contexte** : aujourd'hui le tarif courant écrase silencieusement le prix du devis (confirmé : commande à 120 € pour un devis signé à 76,50 €). Correctif technique trivial une fois tranché.
- **Statut** : **en réflexion** (2026-07-10 : « je ne sais pas encore »). **Éclairage 2026-07-28** (fiche contexte) : PE décrit le cycle voulu par « **le tarif est stocké dans la commande** » et « on ne peut pas modifier le prix d'une facture » — ce qui suggère la sémantique *prix figé au moment du devis signé* ; le CCTP (§5.5.7) va dans le même sens : facturation « aux temps réels » mais **comparée au devis initial avec explication des écarts** (donc le devis reste la référence). Confirmation explicite demandée à PE ; si oui, correctif = ne pas appliquer `set_prix_from_prestation` quand la ligne porte déjà un prix hérité d'une cotation/commande.
- ✅ **Tranché par le code le 2026-08-11** (constaté au rebalayage du 2026-09-22) : commit `0a83223d` d'Alexandre Meunier, #465 « Freeze the price » — le prix figé est celui de la ligne de devis, copié dans la commande puis dans la facture ; le callback qui appliquait le tarif courant a été supprimé. = B2 corrigé. Aucune décision écrite n'accompagne le commit : à confirmer par PE que c'est bien la sémantique voulue.

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

### D11 — ~~Visibilité de l'adhérent repassée en dur dans la vue~~ — **TRANCHÉ et appliqué le 2026-08-06**
`#444` avait rouvert une exception au principe posé le 2026-08-05 (toute la visibilité de la page dans `InterventionPolicy`). Rétabli sur décision de PE :
- `show.html.erb` ne teste plus aucun rôle : trois branches de policy, `voir_pointages?` / `voir_realisation?` / `voir_temps?`.
- Nouveau prédicat `voir_temps?` (= `show? && adhérent? && !record.repeter?`) pour la section « Intervention » de l'adhérent, extraite en partial `show/_temps_adherent.html.erb` — le `<h2>` et les deux sous-partials n'y sont plus dupliqués.
- `voir_agent_des_pointages?`, défini le 2026-08-05 mais **jamais appelé**, pilote enfin la colonne « Agent » du tableau des pointages, qui testait `current_user.agent?` en dur à trois endroits (en-tête, cellule, `colspan`).
- Le `unless current_user.adhérent?` devenu mort dans `show/_assignation.html.erb` a été retiré par PE.

### D6 — ✅ TRANCHÉ (2026-08-03) — Refaire la fiche outil (`tools#show`) sur le même système de cases que l'index
- **Décision PE (2026-08-03)** : bascule faite. La fiche outil **garde sa grille mensuelle** (et le choix Calendrier / Liste des interventions) mais rend ses cases avec `Tool#get_etats_from_mouvements` + `tools/_mouvement`, exactement comme l'index. Légende alignée (carrés au lieu de pastilles).
- **Fin de panne d'un clic sur la case rouge : abandonnée** (décision PE). Elle n'existait que dans le show via `_mouvement_slot` ; la fin de panne passe désormais par le bouton « Gestion panne », présent sur les deux pages. Une case rouge est inerte partout. L'index n'a pas été touché.
- **Ferme au passage** : **B36** (corrigé, prérequis à la bascule) et **B37** (`Tool#dernier_mouvement_a` supprimée avec `mouvements/_mouvement_slot.html.erb`, son unique appelant).
- **Défaut corrigé en chemin** : `tools#show` calculait sa fenêtre sur `params[:date]` alors que `month_calendar` navigue avec `params[:start_date]` — les couleurs se seraient décalées d'un mois dès la première flèche. Le contrôleur lit maintenant `start_date` en priorité et le passe explicitement au calendrier.

## Décisions anciennes (récapitulatif)

| Point | Décision | Date |
|---|---|---|
| D2 — Fusionner la branche `dashboard-scenic` (vues matérialisées Scenic) dans `staging` ? | **Fusionnée** — constaté le 2026-07-31 : `origin/dashboard-scenic` (`11ddebfe`) est un ancêtre de `staging`, `db/views/` et les modèles `DashboardAgentStat`/`DashboardInterventionStat` y sont, `dashboard_data.rb` a disparu (commit `0fb76419 #297`). Conséquences : **B12 corrigé** sur staging, et **B13 n'est plus un bug de branche mais un bug de staging** (le filtre `temps_total >= 0` opère sur les cellules pré-agrégées). | ≤ 2026-07-31 |
| D4 — Notifier quelqu'un quand un adhérent refuse une cotation ? | **Non, personne pour l'instant** (décision équipe rapportée par PE) ; à revoir plus tard. Le correctif reste noté si ça change : job `NotifCotationRefuseeJob` miroir de `NotifCotationSigneeJob` (créateur via l'audit `create`), branché sur le bloc de `transition!` de `cotations_controller#refuser`. | 2026-07-13 |
