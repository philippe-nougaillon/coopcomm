# Dettes ouvertes — CoopComm

> **Dette technique actée** : ce qu'on sait imparfait et qu'on a choisi de ne pas traiter maintenant. Dettes réglées : `dettes-reglees.md`. Décisions en attente : `points-a-trancher.md`.
>
> **Gravité** — la fiche va dans la section de ce qui **reste cassé ou exposé tant que la dette attend** :
> - 🔴 **Bloque la prod ou l'argent** : obligation contractuelle, argent, sécurité devant de vrais utilisateurs.
> - 🟠 **Attendu avant la montée en charge** : rien de cassé aujourd'hui, mais un chemin réel y mène.
> - ⚪ **Confort** : acté, non planifié.
>
> **Règle de tenue** : prochain numéro libre ci-dessous (préfixe `DT`), rangement **par numéro** dans la section. Une dette réglée quitte ce fichier pour `dettes-reglees.md`, titre préfixé `✅ RÉGLÉE (AAAA-MM-JJ)`.
>
> **Prochain numéro libre : DT12**

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

### DT8 — Selects d'identité sans invite (constat 2026-08-31, lot B99)
- sur un formulaire d'intervention neuf, les widgets **Adhérent** et **Service** s'affichent complètement vides, sans aucune invite — le placeholder d'un select requis est vide par construction. Comportement antérieur au lot B99, mais plus visible depuis que la ligne vide a disparu du menu. Le remède est déjà pratiqué dans le dépôt : `prompt: "Choisir un adhérent"` (`commandes/_form`), là où les trois `_prestation_form` ont au contraire `prompt: ""`. Décision d'ergonomie à prendre en une fois pour les ~8 selects concernés.

### DT10 — Onglets CRM figés sur les états de `Commande` (= bug B33)
- au-delà du « Signé » manquant, le menu Statut de `adherent_crm` n'est pas dérivé de l'onglet courant. À traiter avec B33.

## ⚪ Confort

### DT3 — Doublon Solid Queue potentiel
- plugin Puma `solid_queue` **et** ligne `worker:` du `Procfile.dev` — vérifier qu'on ne fait pas tourner deux workers.
- **Rebalayé le 2026-09-22** : le plugin Puma est conditionné à `SOLID_QUEUE_IN_PUMA` depuis le 2026-06-18 (`ffd3ea8b`, #308) ; le doublon n'existe que si la variable est posée en dev à côté du `worker:` du `Procfile.dev` — non vérifié dans `.env`.

### DT6 — Code mort de l'import XLS : reste le job d'accueil et `capture_stdout`
- ~~**Code mort de l'import XLS**~~ — **résolu le 2026-08-07, sauf le job** : le bilan riche prévu a été branché (décision PE), donc `@stream`/`capture_stdout`, `@success_logs`, `@error_logs` et `@mdp` (accumulation de mots de passe en clair) ont disparu avec la réécriture de `import_do` en service. **Reste** : `WelcomeImportNotificationJob` et son test, toujours **appelés par personne** (l'import envoie une invitation Devise), et porteurs du bug **B5** ; `lib/capture_stdout.rb` n'a plus non plus d'appelant. À supprimer quand PE le voudra.
- **Rebalayé le 2026-09-22** : `lib/capture_stdout.rb` n'existe plus ; reste uniquement le job et son test, toujours sans appelant.

### DT7 — Fixture d'API mal formée (constat 2026-07-29, session `/tests` lot D)
- `test/fixtures/files/responseRoutesInfos.json`, utilisée par le stub WebMock global du `test_helper`, contient la **sortie du service `FetchRoutesInfos`** (`{"data_response":…, "routes_info":…, "localisation_depart":…}`) et non la **réponse brute de Google** (`{"routes":[…]}`). Conséquence : dans toute la suite, `get_trajet_from_response` reçoit un objet sans clé `routes` → renvoie `''`, et `Intervention#calculate_co2` calcule toujours **co2 = 0**. Le chemin nominal du connecteur n'était donc exercé nulle part. Les nouveaux tests de `fetch_routes_infos_service_test.rb` posent leurs propres stubs au bon format ; **la fixture globale n'a pas été corrigée** (elle est utilisée implicitement par toute la suite, un changement de forme y modifierait le `trajet`/`co2` de nombreux tests d'intervention — à faire dans un lot dédié).

### DT9 — `include_blank: true` redondant (mesuré 2026-08-31)
- à côté de `required: true`, il produit **exactement le même** `<option value="" label=" ">` — Rails l'impose de toute façon. Les cinq endroits qui écrivent les deux (interventions adhérent/service ×2 formulaires, mouvements matériel/état) peuvent le perdre. Ménage, sans effet fonctionnel.
- **Rebalayé le 2026-09-22** : il en reste deux, [_form_for_agents.erb:50](app/views/interventions/_form_for_agents.erb#L50) et [form/_demande.html.erb:37](app/views/interventions/form/_demande.html.erb#L37) ; les mouvements ont été nettoyés.

### DT11 — Template de PR GitHub (mis de côté le 2026-07-10)
- créer `.github/pull_request_template.md` avec 5-6 cases à cocher (une par famille d'erreur de `CONTRIBUTING.md` §2) — GitHub pré-remplit alors la description de chaque PR, cases cliquables. Décision client : **pour l'instant on utilise `CONTRIBUTING.md` seul** ; à réévaluer si la checklist n'est pas suivie en revue. Doc : <https://docs.github.com/fr/communities/using-templates-to-encourage-useful-issues-and-pull-requests/creating-a-pull-request-template-for-your-repository>.
