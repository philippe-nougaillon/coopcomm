# Dettes réglées — CoopComm

> Dettes réglées, **de la plus récente à la plus ancienne**. Dettes ouvertes : `dettes-ouvertes.md`.
>
> **Règle de tenue** : une fiche arrive ici **entière** depuis `dettes-ouvertes.md`, **en tête de liste**, titre préfixé `✅ RÉGLÉE (AAAA-MM-JJ)`.

---

## ✅ Réglées, du plus récent au plus ancien

### DT13 — ✅ RÉGLÉE (2026-10-05) — slim-select : deux câblages pour un même widget, et du code mort autour (constat 2026-10-05, sonde HTML sur 25 pages, 54 selects)
- **Réglé le 2026-10-05 (demande PE)** : 43 selects à classe seule passent en `data: { controller: 'slim-select' }` et la classe `slim-select` disparaît des 56 blocs restants ; `autoInjectSlimSelect` et ses trois écouteurs Turbo retirés d'`application.js` ; les 4 règles CSS (miroir, `[multiple]`, `:focus`, `[required]`) rebasculées sur `select[data-controller~="slim-select"]` ; `dynamic_select_controller#populateSelect` réécrit sur l'instance Stimulus (`slimSelectDe`, partagée avec la liste des agents), branche « CAS B » supprimée ; `services/index.html.erb`, l'action et la policy `index` commentées supprimées ; `class:` en double de `factures/index` réglé par PE le même jour. Vérifié : rendu serveur des 25 pages (54/54 avec contrôleur), navigateur sur 19 pages (un widget par select, CSS `required` active), cascades intervention et convention, `rails test:all` 2202 runs / 0 échec. Laissé, code parké : `tools/_form.html.erb:25` (`<% if false %>`) et `tools/index.html.erb:39` (commentaire ERB).
- **Deux câblages** : 13 selects déclarent `data-controller="slim-select"` ; les autres comptent sur l'injection d'[application.js:25-48](app/javascript/application.js#L25) (classe `slim-select`, aux seuls `turbo:load`/`render`/`frame-load`), dont **7 `required`** que la CSS cache en attendant le widget — `interventions/form/_demande` adhérent et service, `interventions/_form_for_agents` adhérent, `conventions/_form` adhérent et service, `prestations/_form` unité, `warehouses/_form` utilisateurs. [users/_form.html.erb:112](app/views/users/_form.html.erb#L112) dit pourquoi la déclaration explicite est la forme sûre. La liste d'ids de l'injection (`#intervention_tags`, `#intervention_tags_manager`, `#user_tag_list`) est redondante : les trois portent déjà la classe ou le contrôleur.
- **Code mort et doublons** : [dynamic_select_controller.js:141-154](app/javascript/controllers/dynamic_select_controller.js#L141) garde une branche « CAS B » (re-création d'un SlimSelect nu, sans nos réglages) morte depuis que la 2.13.1 pose `selectEl.slim` — lu dans la source ; `app/views/services/index.html.erb` n'est atteignable par aucune route (`except: %i[index]`, action commentée) ; [factures/index.html.erb:28](app/views/factures/index.html.erb#L28) écrit deux fois `class:` dans le même appel.
- Le reste du relevé du même jour (soumission, troncature des puces, labels, filtres Service) est en **P1**, `perfectionnements-a-faire.md`.

### DT5 — ✅ RÉGLÉE (2026-08-25, #475 d'Alex) — Test optionnel : réactiver le system test logout manager
- réactiver le system test logout *manager* (commenté « missing assertions ») — la recette de logout fiable existe depuis le 2026-06-17.
- Le test « En tant que manager, je veux me déconnecter » existe, actif, dans `test/system/manager/manager_flow_on_devise_test.rb` (constaté le 2026-09-22).

### DT4 — ✅ RÉGLÉE (au plus tard le 2026-07-13, constaté le 2026-09-22) — Quirk local : `bundle exec` obligatoire
- `bundle exec` obligatoire (conflit gem `date` 3.5.1 vs lock 3.5.0).
- `Gemfile.lock` est à `date (3.5.1)` depuis le 2026-07-13 (`32cd31a3`) : le conflit décrit n'existe plus.
