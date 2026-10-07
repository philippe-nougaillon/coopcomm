# Dettes ouvertes — CoopComm

> **Dette technique actée** : du **code livré** — application, scripts, schéma, données — qu'il faudra réécrire ou nettoyer parce qu'il rend la maintenance plus dure ou l'outil plus lent avec le temps : structure, doublon, code mort, dépendance fragile ou obsolète, donnée fausse, script sans filet. Ce qui manque **autour** du code (tests, CI, bancs, procédures) est un risque s'il laisse passer une régression (`risques-surveilles.md`), sinon un perfectionnement ; ce qui serait mieux sans coûter davantage à attendre est un perfectionnement (`perfectionnements-a-faire.md`). Dettes réglées : `dettes-reglees.md`. Décisions en attente : `points-a-trancher.md`.
>
> **Gravité** — la fiche va dans la section de ce qui **reste cassé ou exposé tant que la dette attend** :
> - 🔴 **Bloque la prod ou l'argent** : obligation contractuelle, argent, sécurité devant de vrais utilisateurs.
> - 🟠 **Attendu avant la montée en charge** : rien de cassé aujourd'hui, mais un chemin réel y mène.
> - ⚪ **Confort** : acté, non planifié.
>
> **Règle de tenue** : prochain numéro libre ci-dessous (préfixe `DT`), rangement **par numéro** dans la section. Une dette réglée quitte ce fichier pour `dettes-reglees.md`, titre préfixé `✅ RÉGLÉE (AAAA-MM-JJ)`.
>
> **Prochain numéro libre : DT14**

---

## 🔴 Bloque la prod ou l'argent

_Aucune._

## 🟠 Attendu avant la montée en charge

### DT1 — Dette audit 2026-06-12 (différée par décision client)
- migrations `lockable` et `WikiPage.organisation_id` ; `remember_me` forcé ; pas de `current_password` exigé au changement de mot de passe.
- **Rebalayé le 2026-09-22** : les colonnes `failed_attempts` et `locked_at` existent dans le schéma ; la dette n'est plus une migration mais l'activation de `:lockable`, commenté dans [user.rb:22](app/models/user.rb#L22). `remember_me` forcé ([user.rb:375](app/models/user.rb#L375), rend `true`) et `WikiPage.organisation_id` absent : inchangés.

### DT2 — Donnée en base : `temps_total` négatif pré-existant
- un `temps_total` **négatif** pré-existant (repéré le 2026-06-18) — nettoyer à l'occasion (lié à B1).
- **Re-mesuré le 2026-09-22** : 7 interventions à `temps_total` négatif sur 262 en base de dev, toutes modifiées avant le 2026-08-10, aucune depuis #462.

### DT10 — Onglets CRM figés sur les états de `Commande` (= bug B33)
- au-delà du « Signé » manquant, le menu Statut de `adherent_crm` n'est pas dérivé de l'onglet courant. À traiter avec B33.

## ⚪ Confort

### DT12 — Déplacements de tests annoncés, jamais faits (sortis de la skill le 2026-09-28)
- La skill `tests-coopcomm` portait dans son gabarit des contrôleurs une liste de déplacements à faire, qui n'a pas sa place dans un gabarit permanent. Elle est déplacée ici, **rebalayée contre le dépôt le 2026-09-28** :
  - **`test/controllers/tris_test.rb` existe toujours.** La note disait « passe en tests système » ; le fichier est en réalité un `ActionDispatch::IntegrationTest` (sentinelle des colonnes triables, exercées par `get`), donc sa place au regard de la hiérarchie actuelle est **`test/integration/`**, pas `test/system/`. Déplacement à faire, ou fiche à clore si on assume qu'il reste là.
  - **`menus_deroulants_test` et `securite_regressions_test` n'existent plus** nulle part dans `test/` : les deux points de la note sont sans objet.
  - **Tests des temps négatifs d'intervention** : la note demandait de les retirer, « patchés par #462 ». Il en reste un, [intervention_pointage_test.rb:197](test/models/intervention_pointage_test.rb#L197), qui asserte le message de validation — il paraît légitime aujourd'hui (cf. DT2 : 7 lignes négatives pré-existantes en base de dev). À confirmer avant toute suppression.

### DT3 — Doublon Solid Queue potentiel
- plugin Puma `solid_queue` **et** ligne `worker:` du `Procfile.dev` — vérifier qu'on ne fait pas tourner deux workers.
- **Rebalayé le 2026-09-22** : le plugin Puma est conditionné à `SOLID_QUEUE_IN_PUMA` depuis le 2026-06-18 (`ffd3ea8b`, #308) ; le doublon n'existe que si la variable est posée en dev à côté du `worker:` du `Procfile.dev` — non vérifié dans `.env`.

### DT6 — Code mort de l'import XLS : reste le job d'accueil et `capture_stdout`
- ~~**Code mort de l'import XLS**~~ — **résolu le 2026-08-07, sauf le job** : le bilan riche prévu a été branché (décision PE), donc `@stream`/`capture_stdout`, `@success_logs`, `@error_logs` et `@mdp` (accumulation de mots de passe en clair) ont disparu avec la réécriture de `import_do` en service. **Reste** : `WelcomeImportNotificationJob` et son test, toujours **appelés par personne** (l'import envoie une invitation Devise), et porteurs du bug **B5** ; `lib/capture_stdout.rb` n'a plus non plus d'appelant. À supprimer quand PE le voudra.
- **Rebalayé le 2026-09-22** : `lib/capture_stdout.rb` n'existe plus ; reste uniquement le job et son test, toujours sans appelant.

### DT9 — `include_blank: true` redondant (mesuré 2026-08-31)
- à côté de `required: true`, il produit **exactement le même** `<option value="" label=" ">` — Rails l'impose de toute façon. Les cinq endroits qui écrivent les deux (interventions adhérent/service ×2 formulaires, mouvements matériel/état) peuvent le perdre. Ménage, sans effet fonctionnel.
- **Rebalayé le 2026-09-22** : il en reste deux, [_form_for_agents.erb:50](app/views/interventions/_form_for_agents.erb#L50) et [form/_demande.html.erb:37](app/views/interventions/form/_demande.html.erb#L37) ; les mouvements ont été nettoyés.
