# Actions à faire — CoopComm

> **Actions humaines** (infra, prod, CI, comptes) que l'agent n'a pas le droit de faire seul. Actions faites : `actions-faites.md`. Décisions en attente : `points-a-trancher.md`.
>
> **Gravité** — la fiche va dans la section de ce qui **reste cassé ou exposé tant que l'action attend** :
> - 🔴 **Bloque la prod ou l'argent** : obligation contractuelle, argent, sécurité devant de vrais utilisateurs.
> - 🟠 **Attendu avant la montée en charge** : rien de cassé aujourd'hui, mais un chemin réel y mène.
> - ⚪ **Confort** : acté, non planifié.
>
> **Règle de tenue** : prochain numéro libre ci-dessous, rangement **par numéro** dans la section. Une action faite quitte ce fichier pour `actions-faites.md`, titre préfixé `✅ FAIT (AAAA-MM-JJ)`.
>
> **Prochain numéro libre : A5**

---

## 🔴 Bloque la prod ou l'argent

### A2 — Confirmations prod restantes de l'audit sécurité (2026-06-12)
- Purge des exports **XLS dans `public/`** ; **rotation des comptes seedés** ; `APP_HOSTS` renseigné ; **signature du webhook entrant** vérifiée.
- **Rebalayé le 2026-09-22** : la signature du webhook est vérifiée dans le code depuis le 2026-06-11 (`validate_twilio_signature`, `Twilio::Security::RequestValidator`) ; il ne reste à confirmer en prod que la variable `TWILIO_AUTH_TOKEN`. `public/` ne contient qu'un modèle d'import (`Exemple_import_utilisateurs.xls`), aucun export. Comptes seedés et `APP_HOSTS` : non vérifiables depuis le dépôt.

### A4 — ❗ Sauvegardes de la base de production (à traiter AVANT la mise en prod de septembre)
- **Constat (PE, 2026-07-28, fiche contexte)** : « on ne fait pas de backup de la base de données ».
- **Exigence CCTP §6.2** : sauvegarde automatique **quotidienne**, rétention **≥ 365 jours**, restauration possible ; §7.5 : réversibilité (restitution SQL/CSV/JSON sous 30 j, suppression attestée).
- **Risque** : ~200 interventions/jour refacturées aux communes = données d'argent ; une perte = incident métier ET contractuel.
- **Piste** : `pg_dump` quotidien planifié (Hatchbox — ⚠ syntaxe cron, cf. A1) vers un stockage séparé (S3 déjà dans la stack), chiffré, avec test de restauration documenté. L'agent peut préparer la tâche + la procédure sur demande.

## 🟠 Attendu avant la montée en charge

### A1 — Planifier la relance des cotations sur Hatchbox
- **Quoi** : déclarer `bin/rails cotations:relancer_adherents` dans le planificateur Hatchbox, 1×/jour (la garde 48h est dans la tâche).
- ⚠ **Piège** : syntaxe cron Hatchbox limitée (`0/10` non supporté ; une expression invalide bloque TOUTES les tâches planifiées — incident déjà vécu).

## ⚪ Confort

### A3 — CI : job `test:system` séparé
- **Quoi** : exécuter les tests système dans un job CI distinct des tests unitaires/intégration.
- **Pourquoi** : les tests système non transactionnels laissent des résidus qui, depuis #357 (dispos sur dates réelles), font échouer les tests de pointage lancés dans le même run.
- **Rebalayé le 2026-09-22** : la CI ([rails.yml](.github/workflows/rails.yml)) ne lance que `PARALLEL_WORKERS=2 bin/rails test` ; la ligne `bin/rails test:system` est commentée (l. 115). Les tests système ne tournent donc **jamais** en CI — le point n'est plus « séparer » mais « brancher ».
