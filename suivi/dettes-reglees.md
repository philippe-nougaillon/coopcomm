# Dettes réglées — CoopComm

> Dettes réglées, **de la plus récente à la plus ancienne**. Dettes ouvertes : `dettes-ouvertes.md`.
>
> **Règle de tenue** : une fiche arrive ici **entière** depuis `dettes-ouvertes.md`, **en tête de liste**, titre préfixé `✅ RÉGLÉE (AAAA-MM-JJ)`.

---

## ✅ Réglées, du plus récent au plus ancien

### DT5 — ✅ RÉGLÉE (2026-08-25, #475 d'Alex) — Test optionnel : réactiver le system test logout manager
- réactiver le system test logout *manager* (commenté « missing assertions ») — la recette de logout fiable existe depuis le 2026-06-17.
- Le test « En tant que manager, je veux me déconnecter » existe, actif, dans `test/system/manager/manager_flow_on_devise_test.rb` (constaté le 2026-09-22).

### DT4 — ✅ RÉGLÉE (au plus tard le 2026-07-13, constaté le 2026-09-22) — Quirk local : `bundle exec` obligatoire
- `bundle exec` obligatoire (conflit gem `date` 3.5.1 vs lock 3.5.0).
- `Gemfile.lock` est à `date (3.5.1)` depuis le 2026-07-13 (`32cd31a3`) : le conflit décrit n'existe plus.
