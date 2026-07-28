# Points à trancher / actions en attente — CoopComm

> **Liste unique de ce qui attend une décision ou une action humaine** (client / PE). Distinct du registre des bugs (`bugs-signales.md`) : ici on ne liste pas des défauts, mais des **choix à faire** et des **actions que l'agent n'a pas le droit de faire seul**. Tenir à jour : quand un point est tranché, noter la décision + la date puis le déplacer dans « Tranchés » (l'agent reporte ensuite la décision dans CLAUDE.md).

---

## 🟠 Décisions métier à prendre

### D1 — Prix du devis vs tarif courant (= bug **B2** du registre)
- **Question** : quand une commande est créée depuis une cotation signée (puis une facture depuis la commande), quel prix fait foi — celui **signé sur le devis** ou le **tarif courant** de la prestation ?
- **Contexte** : aujourd'hui le tarif courant écrase silencieusement le prix du devis (confirmé : commande à 120 € pour un devis signé à 76,50 €). Correctif technique trivial une fois tranché.
- **Statut** : **en réflexion** (2026-07-10 : « je ne sais pas encore »). **Éclairage 2026-07-28** (fiche contexte) : PE décrit le cycle voulu par « **le tarif est stocké dans la commande** » et « on ne peut pas modifier le prix d'une facture » — ce qui suggère la sémantique *prix figé au moment du devis signé* ; le CCTP (§5.5.7) va dans le même sens : facturation « aux temps réels » mais **comparée au devis initial avec explication des écarts** (donc le devis reste la référence). Confirmation explicite demandée à PE ; si oui, correctif = ne pas appliquer `set_prix_from_prestation` quand la ligne porte déjà un prix hérité d'une cotation/commande.

### D2 — Fusion de la branche `dashboard-scenic` dans `staging`
- **Question** : intégrer ou non les vues matérialisées Scenic (dashboard rapide, décision de conception du 2026-06-18) ?
- **Contexte** : branche poussée, non fusionnée ; `staging` vit sa vie depuis → prévoir un test de fusion. L'alternative (cache + index) avait été steelmanée le 2026-06-18, le choix Scenic reste cohérent avec la vision multi-organisations à fort volume.

### D3 — Activation future des notifications `EmailSubscription` (= bug **B8**)
- **Question** : quand (si) on active la notif « intervention mise à jour », valider le correctif préalable (`User.find_by` + garde nil) — 166 interventions crasheraient sinon.
- **Contexte** : fonctionnalité dormante, décision client du 2026-06-23 de ne pas y toucher d'ici là.

### D5 — Workflow de validation des documents d'outil : supprimé ou en pause ? (constat du 2026-07-10)
- **Question** : la refonte UX (Dani Isaza, commits `3ae4f02e` du 2026-07-02 « UX - corriger github actions » et `42085022` du 2026-07-03 « UX - solution github ») a **désactivé toute la fonctionnalité** valider/refuser des documents d'outil : actions commentées dans `documents_controller.rb`, routes commentées (`resources :documents, only: %i[]`), workflow commenté dans `document.rb`, boutons retirés du partial `_document.html.erb` (colonne État vide). Le formulaire outil est passé des nested attributes (fichier + état par document) à une **dropzone unique** `form.file_field :documents`. Est-ce une suppression **assumée** de la fonctionnalité, ou un débranchement **temporaire** pour faire passer la CI (les noms de commits le suggèrent) ?
- **Conséquence immédiate** : les 3 system tests de `test/system/documents_test.rb` échouaient (ils testent l'UI disparue) → **commentés le 2026-07-13** (décision client : « pour l'instant on ne l'utilise pas ») avec renvoi vers ce point. À trancher avec Dani : si suppression assumée → supprimer le fichier de test ; si temporaire → réactiver la fonctionnalité et décommenter/adapter les tests.
- **Incohérence à signaler au passage** : `tools_controller#tool_params` permet toujours `documents_attributes` alors que le formulaire n'envoie plus que `documents` (fichier simple) — l'upload de documents depuis le formulaire est probablement cassé aussi côté serveur (non vérifié).

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
- **Template de PR GitHub** (mis de côté le 2026-07-10) : créer `.github/pull_request_template.md` avec 5-6 cases à cocher (une par famille d'erreur de `CONTRIBUTING.md` §2) — GitHub pré-remplit alors la description de chaque PR, cases cliquables. Décision client : **pour l'instant on utilise `CONTRIBUTING.md` seul** ; à réévaluer si la checklist n'est pas suivie en revue. Doc : <https://docs.github.com/fr/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository>.

---

## ✅ Tranchés (historique)

| Point | Décision | Date |
|---|---|---|
| D4 — Notifier quelqu'un quand un adhérent refuse une cotation ? | **Non, personne pour l'instant** (décision équipe rapportée par PE) ; à revoir plus tard. Le correctif reste noté si ça change : job `NotifCotationRefuseeJob` miroir de `NotifCotationSigneeJob` (créateur via l'audit `create`), branché sur le bloc de `transition!` de `cotations_controller#refuser`. | 2026-07-13 |
