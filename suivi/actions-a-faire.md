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
> **Prochain numéro libre : A7**

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

### A6 — Relever la répartition des navigateurs des utilisateurs, et la version exacte de celui de l'agent de B122
- **Pourquoi** : B122 (bouton de soumission invisible) est entièrement expliqué par l'absence de `oklch()`, mais **la marque et la version du navigateur de l'agent ne sont pas mesurées**. Et l'ampleur — combien d'utilisateurs sont sous Chrome 111 / Samsung Internet 22 — décide entre « un repli CSS suffit » et « il faut faire mettre à jour la flotte ».
- **À faire** : (a) Google Analytics est actif hors développement ([_gtag.html.erb](app/views/partials/_gtag.html.erb)) → lire les rapports **Technologie > Navigateur** et **Version du navigateur** ; (b) demander à l'agent concerné sa marque et sa version (Samsung Internet : ⋮ > Paramètres > À propos de Samsung Internet ; Chrome : `chrome://version`), et par quoi il ouvre l'application — navigateur ou raccourci PWA, la WebView système pouvant être plus ancienne que le navigateur installé.
- **Contrôle d'une minute, en attendant** : faire regarder à l'agent une page portant une photo ou le logo en couleur. Photo en couleur + interface en noir et blanc → c'est le CSS, pas le mode noir et blanc du téléphone.
- **Seuil à retenir** : le navigateur par défaut d'un Galaxy (XCover compris) est **Samsung Internet**, préinstallé à côté de Chrome. Il connaît `oklch()` **à partir de la version 22** (Chromium 111, sortie le **14 juillet 2023**) ; 21 et en dessous, non. Donc : *Samsung Internet mis à jour pour la dernière fois avant juillet 2023 → pas de `oklch()`*. Corollaire : les XCover 4s (2019), 5 (2021) et 6 Pro (2022) sont tous sortis **avant** cette date, leur Samsung Internet d'usine est forcément sous le seuil ; seuls les XCover 7 (janvier 2024) et 7 Pro (mai 2025) sont bons d'origine. Une mise à jour suffit à repasser au-dessus sur tous ces modèles (Samsung Internet 28 descend jusqu'à Android 9, la 29 jusqu'à Android 10) — **c'est donc une question de mise à jour, pas de modèle**.
- **Mesure à faire en premier, 30 secondes, sur le XCover déjà en main** : rouvrir le test dans **Samsung Internet** (pas Chrome, qui se met à jour tout seul par le Play Store) et lire ⋮ > Paramètres > À propos de Samsung Internet. C'est le seul point qui dise si le test du 2026-10-07 portait sur le bon moteur.
- **Déduit, non mesuré** : le layout sert un manifeste PWA ([application.html.erb:17](app/views/layouts/application.html.erb#L17)) ; sur un Galaxy, un raccourci d'écran d'accueil s'ouvre dans le moteur de Samsung Internet — un agent peut donc tomber sur le vieux moteur même si Chrome est son navigateur par défaut.

## 🟠 Attendu avant la montée en charge

### A1 — Planifier la relance des cotations sur Hatchbox
- **Quoi** : déclarer `bin/rails cotations:relancer_adherents` dans le planificateur Hatchbox, 1×/jour (la garde 48h est dans la tâche).
- ⚠ **Piège** : syntaxe cron Hatchbox limitée (`0/10` non supporté ; une expression invalide bloque TOUTES les tâches planifiées — incident déjà vécu).

### A3 — CI : job `test:system` séparé
- **Quoi** : exécuter les tests système dans un job CI distinct des tests unitaires/intégration.
- **Pourquoi** : les tests système non transactionnels laissent des résidus qui, depuis #357 (dispos sur dates réelles), font échouer les tests de pointage lancés dans le même run.
- **Rebalayé le 2026-09-22** : la CI ([rails.yml](.github/workflows/rails.yml)) ne lance que `PARALLEL_WORKERS=2 bin/rails test` ; la ligne `bin/rails test:system` est commentée (l. 115). Les tests système ne tournent donc **jamais** en CI — le point n'est plus « séparer » mais « brancher ».
