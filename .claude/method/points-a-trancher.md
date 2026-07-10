# Points à trancher / actions en attente — CoopComm

> **Liste unique de ce qui attend une décision ou une action humaine** (client / PE). Distinct du registre des bugs (`bugs-signales.md`) : ici on ne liste pas des défauts, mais des **choix à faire** et des **actions que l'agent n'a pas le droit de faire seul**. Tenir à jour : quand un point est tranché, noter la décision + la date puis le déplacer dans « Tranchés » (l'agent reporte ensuite la décision dans CLAUDE.md).

---

## 🟠 Décisions métier à prendre

### D1 — Prix du devis vs tarif courant (= bug **B2** du registre)
- **Question** : quand une commande est créée depuis une cotation signée (puis une facture depuis la commande), quel prix fait foi — celui **signé sur le devis** ou le **tarif courant** de la prestation ?
- **Contexte** : aujourd'hui le tarif courant écrase silencieusement le prix du devis (confirmé : commande à 120 € pour un devis signé à 76,50 €). Correctif technique trivial une fois tranché.
- **Statut** : **en réflexion** (2026-07-10 : « je ne sais pas encore »).

### D2 — Fusion de la branche `dashboard-scenic` dans `staging`
- **Question** : intégrer ou non les vues matérialisées Scenic (dashboard rapide, décision de conception du 2026-06-18) ?
- **Contexte** : branche poussée, non fusionnée ; `staging` vit sa vie depuis → prévoir un test de fusion. L'alternative (cache + index) avait été steelmanée le 2026-06-18, le choix Scenic reste cohérent avec la vision multi-organisations à fort volume.

### D3 — Activation future des notifications `EmailSubscription` (= bug **B8**)
- **Question** : quand (si) on active la notif « intervention mise à jour », valider le correctif préalable (`User.find_by` + garde nil) — 166 interventions crasheraient sinon.
- **Contexte** : fonctionnalité dormante, décision client du 2026-06-23 de ne pas y toucher d'ici là.

### D4 — Notifier quelqu'un quand un adhérent refuse une cotation ? (constat du 2026-07-10)
- **Question** : aujourd'hui **personne n'est prévenu** au refus d'une cotation (`cotations_controller#refuser` fait la transition sans effet de bord, aucun job « cotation refusée » n'existe) — alors que la **signature** notifie le créateur (`NotifCotationSigneeJob`). Depuis #358, un adhérent peut refuser seul → le manager ne le découvre qu'en consultant l'index. Faut-il un mail au créateur (miroir de la signature) ?
- **Correctif proposé si oui** : job `NotifCotationRefuseeJob` calqué sur `NotifCotationSigneeJob` (créateur retrouvé via l'audit `create`), déclenché depuis `refuser` via le bloc de `transition!`.

## 🔧 Actions à faire (infra / prod)

### A1 — Planifier la relance des cotations sur Hatchbox
- **Quoi** : déclarer `bin/rails cotations:relancer_adherents` dans le planificateur Hatchbox, 1×/jour (la garde 48h est dans la tâche).
- ⚠ **Piège** : syntaxe cron Hatchbox limitée (`0/10` non supporté ; une expression invalide bloque TOUTES les tâches planifiées — incident déjà vécu).

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
- **Template de PR GitHub** (mis de côté le 2026-07-10) : créer `.github/pull_request_template.md` avec 5-6 cases à cocher (une par famille d'erreur de `CONTRIBUTING.md` §2) — GitHub pré-remplit alors la description de chaque PR, cases cliquables. Décision client : **pour l'instant on utilise `CONTRIBUTING.md` seul** ; à réévaluer si la checklist n'est pas suivie en revue. Doc : <https://docs.github.com/fr/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository>.

---

## ✅ Tranchés (historique)

| Point | Décision | Date |
|---|---|---|
| — | — | — |
